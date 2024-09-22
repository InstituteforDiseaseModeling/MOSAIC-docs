
library(openmeteo)
library(httr)
library(jsonlite)
library(sf)
library(rnaturalearth)
library(sp)
library(ggplot2)
library(lubridate)
library(glue)
library(readr)



afro_iso_codes <- c(
     "AGO", "BEN", "BWA", "BFA", "BDI", "CMR", "CAF", "TCD",
     "COM", "COG", "COD", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB",
     "GHA", "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT",
     "MUS", "MOZ", "NAM", "NER", "NGA", "RWA", "SEN", "SLE",
     "SOM", "ZAF", "SSD", "TGO", "UGA", "TZA", "ZMB", "ZWE"
)



convert_iso3_to_country <- function(x) {

     country_names <- countrycode::countrycode(x, origin = "iso3c", destination = "country.name")
     country_names[x == 'COD'] <- "Democratic Republic of Congo"
     country_names[x == 'COG'] <- "Congo"

     return(country_names)
}


# Define the function to create a grid of points within a country's shapefile
generate_country_grid <- function(country_shp, distance_km) {
     # Transform the country geometry to a projected coordinate system to measure distances in meters
     country_proj <- st_transform(country_shp, crs = st_crs("+proj=utm +zone=37 +datum=WGS84 +units=m +no_defs"))

     # Create a grid of points with the specified distance in meters
     grid_points <- st_make_grid(country_proj, cellsize = distance_km * 1000, what = "centers")

     # Clip the grid points to the country boundary
     grid_points_sf <- st_intersection(grid_points, st_geometry(country_proj))

     # Transform the grid points back to the original coordinate system (longitude/latitude)
     grid_points_sf <- st_transform(grid_points_sf, crs = st_crs(country_shp))

     return(grid_points_sf)
}




get_historical_weather <- function(lat, lon, start_date, end_date) {

     # Construct the API URL
     url <- paste0(
          "https://customer-archive-api.open-meteo.com/v1/archive?",
          "latitude=", lat,
          "&longitude=", lon,
          "&start_date=", start_date,
          "&end_date=", end_date,
          "&daily=precipitation_sum",
          "&apikey=aWshPbO8h8az9ico"
     )

     # Make the API request
     response <- GET(url)

     # Check if the request was successful
     if (status_code(response) == 200) {
          # Parse the JSON response
          data <- fromJSON(content(response, "text", encoding = "UTF-8"))
          # Extract the relevant data
          daily_data <- data$daily$precipitation_sum
          dates <- data$daily$time

          # Return as a data frame
          return(data.frame(date = as.Date(dates), daily_precipitation_sum = daily_data))
     } else {
          # Handle errors
          warning("Failed to retrieve data: ", status_code(response))
          return(NULL)
     }
}




# Load the cholera cases data
cholera_data <- read_csv(file.path(getwd(), "data/cholera_country_weekly_processed.csv"))

ggplot(cholera_data, aes(x = week, y = cases, color = country)) +
     geom_point() +
     labs(title = "Cholera Cases by Week for Each Country",
          x = "Week",
          y = "Number of Cases",
          color = "Country") +
     theme_minimal() +
     theme(axis.text.x = element_text(angle = 45, hjust = 1),
           legend.position = "right") +
     facet_wrap(~ country, scales = "free_y")  # Facet by country


# Inspect the data
print(cholera_data)



date_start <- as.Date("2014-09-01")
date_stop <- as.Date("2024-09-01")
country_iso_code <- "UGA"

country_name <- convert_iso3_to_country(country_iso_code)
country_shp <- ne_countries(scale = "medium", returnclass = "sf", country = country_name)
grid_points <- generate_country_grid(country_shp, distance_km = 100)
coords <- st_coordinates(grid_points)
coords <- as.data.frame(coords)
colnames(coords) <- c("Longitude", "Latitude")


ggplot() +
     geom_sf(data = country_shp, fill = "lightgray") +
     geom_sf(data = grid_points, color = "black", size = 1.5) +
     labs(title = glue("Grid of sampling points in {country_shp$name_long}"),
          x = NULL, y = NULL) +
     theme_minimal()




# Initialize an empty list to store the precipitation data
precipitation_data_list <- list()

# Loop through each point to retrieve precipitation data
for (i in 1:nrow(coords)) {

     lat <- coords$Latitude[i]
     lon <- coords$Longitude[i]

     tmp <- get_historical_weather(lat, lon, date_start, date_stop)

     tmp$year <- lubridate::year(tmp$date)

     tmp <- tmp %>%
          mutate(week = week(date)) %>%
          group_by(year, week) %>%
          summarize(weekly_precipitation_sum = sum(daily_precipitation_sum, na.rm = TRUE))


     plot(tmp$week, tmp$weekly_precipitation_sum)

     tmp$id <- i
     tmp$iso_code <- country_iso_code

     precipitation_data_list[[i]] <- tmp
}


precip_data <- do.call(rbind, precipitation_data_list)



# Merge with the precipitation data by week
precip_data <- merge(precip_data, cholera_data, by = c("week", "iso_code"), all.x=TRUE)

################################################################################

# Scale the precipitation values by centering and dividing by the standard deviation
precip_data$precip_scaled <- (precip_data$weekly_precipitation_sum - mean(precip_data$weekly_precipitation_sum, na.rm = TRUE)) /
     sd(precip_data$weekly_precipitation_sum, na.rm = TRUE)

# Scale the cholera cases by centering and dividing by the standard deviation
precip_data$cases_scaled <- (precip_data$cases - mean(precip_data$cases, na.rm = TRUE)) /
     sd(precip_data$cases, na.rm = TRUE)

#######################

# Generalized Fourier Series
generalized_fourier <- function(t, beta0, a1, b1, a2, b2, p) {
     beta0 +
          a1 * cos(2 * pi * t / p) +
          b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) +
          b2 * sin(4 * pi * t / p)
}

#######################

# Fit the models sequentially


# Create a sequence of weeks for plotting the fitted curve
week_seq <- seq(min(precip_data$week), max(precip_data$week), length.out = 100)



# Generalized Fourier Series Model
fit_fourier_precip <- nls(precip_scaled ~ generalized_fourier(week, beta0, a1, b1, a2, b2, p),
                   data = precip_data,
                   start = list(beta0 = 0,
                                a1 = 1,
                                b1 = 1,
                                a2 = 1/2,
                                b2 = 1/2,
                                p = 52),
                   algorithm = "port",
                   lower = c(beta0 = 0, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, p = 52),
                   upper = c(beta0 = 0, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, p = 52))


if (!all(is.na(precip_data$cases_scaled))) {

fit_fourier_cases <- nls(cases_scaled ~ generalized_fourier(week, beta0, a1, b1, a2, b2, p),
                   data = precip_data,
                   start = list(beta0 = 0,
                                a1 = coef(fit_fourier_precip)['a1'],
                                b1 = coef(fit_fourier_precip)['b1'],
                                a2 = coef(fit_fourier_precip)['a2'],
                                b2 = coef(fit_fourier_precip)['b2'],
                                p = 52),
                   algorithm = "port",
                   lower = c(beta0 = 0, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, p = 52),
                   upper = c(beta0 = 0, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, p = 52))

# Predict the fitted values for all models
fitted_values <- data.frame(
     week = week_seq,
     fitted_values_fourier_precip = predict(fit_fourier_precip, newdata = data.frame(week = week_seq)),
     fitted_values_fourier_cases = predict(fit_fourier_cases, newdata = data.frame(week = week_seq))
)

} else {

     # Predict the fitted values for all models
     fitted_values <- data.frame(
          week = week_seq,
          fitted_values_fourier_precip = predict(fit_fourier_precip, newdata = data.frame(week = week_seq)),
          fitted_values_fourier_cases = as.numeric(rep(NA, length(week_seq)))
     )


}



p1 <-
     ggplot(precip_data, aes(x = week)) +
     geom_hline(yintercept = 0, color = "black", linetype = 'dashed') +

     # Map the aesthetic mappings for color and shape to get a legend
     geom_point(aes(y = precip_scaled, color = "Precipitation (2014-2024)"), size = 3.5, alpha = 0.1) +
     geom_point(aes(y = cases_scaled, color = "Cholera Cases (2023-2024)"), size = 3) +

     # Add all waveform models to the plot
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_fourier_precip, color = "Fourier Series (Precip)"), size = 2.2) +
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_fourier_cases, color = "Fourier Series (Cases)"), size = 2.2) +

     scale_x_continuous(breaks = c(1, 10, 20, 30, 40, 52)) +
     scale_color_manual(
          values = c(
               "Precipitation (2014-2024)" = "black",  # Bright Blue
               "Cholera Cases (2023-2024)" = "#FFA500",  # Bright Orange
               "Fourier Series (Precip)" = "#004CFF",    # Bright Green
               "Fourier Series (Cases)" = "#DC143C"      # Bright Red
          ),
          breaks = c(
               "Precipitation (2014-2024)", "Cholera Cases (2023-2024)",
               "Fourier Series (Precip)", "Fourier Series (Cases)"
          )
     ) +
     labs(title = precip_data$country[1],
          x = "Week of Year",
          y = "Scaled Precipitation and Cholera Cases (Z-Score)") +
     theme_classic() +
     theme(
          plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
          axis.title.x = element_text(size = 14, margin = margin(t = 20)),
          axis.title.y = element_text(size = 14, margin = margin(r = 20)),
          axis.text = element_text(size = 12),
          legend.text = element_text(size = 12),
          legend.title = element_blank(),
          panel.grid.major.y = element_line(color = "grey90", size = 0.25),
          panel.grid.minor.y = element_line(color = "grey90", size = 0.25)
     )

print(p1)




# Function to calculate the Sum of Squared Errors (SSE)
calculate_sse <- function(actual_values, predicted_values) {
     sum((actual_values - predicted_values) ^ 2, na.rm = TRUE)
}

# Calculate SSE for each model
sse_results <- data.frame(
     Country = country_name,
     iso_code = country_iso_code,
     Model = c(
          "Cosine Wave", "Double Cosine Wave", "Fourier Series"
     ),
     SSE_precip = c(
          calculate_sse(precip_data$precip_scaled, predict(fit_cosine)),
          calculate_sse(precip_data$precip_scaled, predict(fit_double_cosine)),
          calculate_sse(precip_data$precip_scaled, predict(fit_fourier))
     ),
     SSE_cases = c(
          calculate_sse(precip_data$cases_scaled, predict(fit_cosine)),
          calculate_sse(precip_data$cases_scaled, predict(fit_double_cosine)),
          calculate_sse(precip_data$cases_scaled, predict(fit_fourier))
     )
)

# Print the SSE results
print(sse_results)









