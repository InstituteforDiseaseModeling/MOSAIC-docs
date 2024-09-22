
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
library(dplyr)
library(tidyr)
library(MOSAIC)



# Load the cholera cases data
cholera_data <- read_csv(file.path(getwd(), "data/cholera_country_weekly_processed.csv"))

ggplot(cholera_data, aes(x = week, y = cases, color = country)) +
     geom_point() +
     labs(title = "Reported cholera cases (Jan 2023 - Aug 2024)",
          x = "Week",
          y = "Number of Cases",
          color = "Country") +
     theme_minimal() +
     theme(legend.position = "right") +
     facet_wrap(~ country, scales = "free_y")  # Facet by country


# Inspect the data
print(cholera_data)



date_start <- as.Date("2014-09-01")
date_stop <- as.Date("2024-09-01")
country_iso_code <- "MOZ"

country_name <- convert_iso3_to_country(country_iso_code)
country_shp <- ne_countries(scale = "medium", returnclass = "sf", country = country_name)
grid_points <- generate_country_grid_n(country_shp, n_points = 30)
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

     tmp <- get_historical_precip(lat, lon, as.Date("2014-09-01"), as.Date("2024-09-01"), api_key = "aWshPbO8h8az9ico")

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

# Define all the seasonality models

# Cosine Wave
cosine_wave <- function(t, beta0, a1, p, phi) {
     beta0 + a1 * cos(2 * pi * t / p + phi)
}

# Double Cosine Wave
double_cosine_wave <- function(t, beta0, a1, a2, p) {
     beta0 +
          a1 * cos(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p)
}

# Double Sine Wave
double_sine_wave <- function(t, beta0, a1, b1, a2, b2, p) {
     beta0 +
          a1 * sin(2 * pi * t / p) +
          b1 * cos(2 * pi * t / p) +
          a2 * sin(4 * pi * t / p) +
          b2 * cos(4 * pi * t / p)
}

# Combined Sine and Cosine Wave
combined_sine_cosine <- function(t, beta0, a1, b1, a2, b2, p) {
     beta0 +
          a1 * cos(2 * pi * t / p) +
          b1 * sin(2 * pi * t / p) +
          a2 * sin(4 * pi * t / p) +
          b2 * cos(4 * pi * t / p)
}

# Generalized Fourier Series
generalized_fourier <- function(t, beta0, a1, b1, a2, b2, p) {
     beta0 +
          a1 * cos(2 * pi * t / p) +
          b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) +
          b2 * sin(4 * pi * t / p)
}

# Triple Harmonic Fourier Series
triple_harmonic_fourier <- function(t, beta0, a1, b1, a2, b2, a3, b3, p) {
     beta0 +
          a1 * cos(2 * pi * t / p) +
          b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) +
          b2 * sin(4 * pi * t / p) +
          a3 * cos(6 * pi * t / p) +
          b3 * sin(6 * pi * t / p)
}

# Quadruple Harmonic Fourier Series
quadruple_harmonic_fourier <- function(t, beta0, a1, b1, a2, b2, a3, b3, a4, b4, p) {
     beta0 +
          a1 * cos(2 * pi * t / p) +
          b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) +
          b2 * sin(4 * pi * t / p) +
          a3 * cos(6 * pi * t / p) +
          b3 * sin(6 * pi * t / p) +
          a4 * cos(8 * pi * t / p) +
          b4 * sin(8 * pi * t / p)
}

#######################

# Fit the models sequentially

# Cosine Wave Model
fit_cosine <- nls(precip_scaled ~ cosine_wave(week, beta0, a1, p, phi),
                  data = precip_data,
                  start = list(beta0 = mean(precip_data$precip_scaled, na.rm = TRUE),
                               a1 = sd(precip_data$precip_scaled, na.rm = TRUE),
                               p = 52,
                               phi = 0),
                  algorithm = "port",
                  lower = c(beta0 = -Inf, a1 = -Inf, p = 52, phi = -Inf),
                  upper = c(beta0 = Inf, a1 = Inf, p = 52, phi = Inf))

# Double Cosine Wave Model
fit_double_cosine <- nls(precip_scaled ~ double_cosine_wave(week, beta0, a1, a2, p),
                         data = precip_data,
                         start = list(beta0 = coef(fit_cosine)['beta0'],
                                      a1 = coef(fit_cosine)['a1'],
                                      a2 = coef(fit_cosine)['a1'] / 2,
                                      p = 52),
                         algorithm = "port",
                         lower = c(beta0 = -Inf, a1 = -Inf, a2 = -Inf, p = 52),
                         upper = c(beta0 = Inf, a1 = Inf, a2 = Inf, p = 52))

# Double Sine Wave Model
fit_double_sine <- nls(precip_scaled ~ double_sine_wave(week, beta0, a1, b1, a2, b2, p),
                       data = precip_data,
                       start = list(beta0 = coef(fit_double_cosine)['beta0'],
                                    a1 = coef(fit_double_cosine)['a1'],
                                    b1 = coef(fit_double_cosine)['a1'] / 2,
                                    a2 = coef(fit_double_cosine)['a2'],
                                    b2 = 0,
                                    p = 52),
                       algorithm = "port",
                       lower = c(beta0 = -Inf, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, p = 52),
                       upper = c(beta0 = Inf, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, p = 52))

# Combined Sine and Cosine Wave Model
fit_combined_sine_cosine <- nls(precip_scaled ~ combined_sine_cosine(week, beta0, a1, b1, a2, b2, p),
                                data = precip_data,
                                start = list(beta0 = coef(fit_double_sine)['beta0'],
                                             a1 = coef(fit_double_sine)['a1'],
                                             b1 = coef(fit_double_sine)['b1'],
                                             a2 = coef(fit_double_sine)['a2'],
                                             b2 = coef(fit_double_sine)['b2'],
                                             p = 52),
                                algorithm = "port",
                                lower = c(beta0 = -Inf, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, p = 52),
                                upper = c(beta0 = Inf, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, p = 52))

# Generalized Fourier Series Model
fit_fourier <- nls(precip_scaled ~ generalized_fourier(week, beta0, a1, b1, a2, b2, p),
                   data = precip_data,
                   start = list(beta0 = coef(fit_combined_sine_cosine)['beta0'],
                                a1 = coef(fit_combined_sine_cosine)['a1'],
                                b1 = coef(fit_combined_sine_cosine)['b1'],
                                a2 = coef(fit_combined_sine_cosine)['a2'],
                                b2 = coef(fit_combined_sine_cosine)['b2'],
                                p = 52),
                   algorithm = "port",
                   lower = c(beta0 = -Inf, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, p = 52),
                   upper = c(beta0 = Inf, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, p = 52))

# Triple Harmonic Fourier Series Model
fit_triple_fourier <- nls(precip_scaled ~ triple_harmonic_fourier(week, beta0, a1, b1, a2, b2, a3, b3, p),
                          data = precip_data,
                          start = list(beta0 = coef(fit_fourier)['beta0'],
                                       a1 = coef(fit_fourier)['a1'],
                                       b1 = coef(fit_fourier)['b1'],
                                       a2 = coef(fit_fourier)['a2'],
                                       b2 = coef(fit_fourier)['b2'],
                                       a3 = 0,
                                       b3 = 0,
                                       p = 52),
                          algorithm = "port",
                          lower = c(beta0 = -Inf, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, a3 = -Inf, b3 = -Inf, p = 52),
                          upper = c(beta0 = Inf, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, a3 = Inf, b3 = Inf, p = 52))

# Quadruple Harmonic Fourier Series Model
fit_quadruple_fourier <- nls(precip_scaled ~ quadruple_harmonic_fourier(week, beta0, a1, b1, a2, b2, a3, b3, a4, b4, p),
                             data = precip_data,
                             start = list(beta0 = coef(fit_triple_fourier)['beta0'],
                                          a1 = coef(fit_triple_fourier)['a1'],
                                          b1 = coef(fit_triple_fourier)['b1'],
                                          a2 = coef(fit_triple_fourier)['a2'],
                                          b2 = coef(fit_triple_fourier)['b2'],
                                          a3 = coef(fit_triple_fourier)['a3'],
                                          b3 = coef(fit_triple_fourier)['b3'],
                                          a4 = 0,
                                          b4 = 0,
                                          p = 52),
                             algorithm = "port",
                             lower = c(beta0 = -Inf, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, a3 = -Inf, b3 = -Inf, a4 = -Inf, b4 = -Inf, p = 52),
                             upper = c(beta0 = Inf, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, a3 = Inf, b3 = Inf, a4 = Inf, b4 = Inf, p = 52))






# Create a sequence of weeks for plotting the fitted curve
week_seq <- seq(min(precip_data$week), max(precip_data$week), length.out = 100)

# Predict the fitted values for all models
fitted_values <- data.frame(
     week = week_seq,
     fitted_values_cosine = predict(fit_cosine, newdata = data.frame(week = week_seq)),
     fitted_values_double_cosine = predict(fit_double_cosine, newdata = data.frame(week = week_seq)),
     fitted_values_double_sine = predict(fit_double_sine, newdata = data.frame(week = week_seq)),
     fitted_values_combined_sine_cosine = predict(fit_combined_sine_cosine, newdata = data.frame(week = week_seq)),
     fitted_values_fourier = predict(fit_fourier, newdata = data.frame(week = week_seq)),
     fitted_values_triple_fourier = predict(fit_triple_fourier, newdata = data.frame(week = week_seq)),
     fitted_values_quadruple_fourier = predict(fit_quadruple_fourier, newdata = data.frame(week = week_seq))
)

# Plot the scaled precipitation and scaled cholera cases with horizontal gridlines
p1 <- ggplot(precip_data, aes(x = week)) +
     geom_hline(yintercept = 0, color = "grey80") +

     # Map the aesthetic mappings for color and shape to get a legend
     geom_point(aes(y = precip_scaled, color = "Precipitation (2014-2024)"), size = 2.5, alpha = 0.1) +
     geom_point(aes(y = cases_scaled, color = "Cholera Cases (2023-2024)"), size = 2.5) +

     # Add all waveform models to the plot
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_cosine, color = "Cosine Wave"), size = 2) +
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_double_cosine, color = "Double Cosine Wave"), size = 2) +
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_double_sine, color = "Double Sine Wave"), size = 2) +
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_combined_sine_cosine, color = "Combined Sine Cosine"), size = 2) +
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_fourier, color = "Fourier Series"), size = 2) +
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_triple_fourier, color = "Triple Fourier"), size = 2) +
     geom_line(data = fitted_values, aes(x = week, y = fitted_values_quadruple_fourier, color = "Quadruple Fourier"), size = 2) +

     # Define manual colors for the legend with the desired order
     scale_color_manual(
          values = c(
               "Cholera Cases (2023-2024)" = "#E6194B",
               "Precipitation (2014-2024)" = "black",
               "Cosine Wave" = "#3CB44B",
               "Double Cosine Wave" = "#4363D8",
               "Double Sine Wave" = "#FFA500",  # Orange
               "Combined Sine Cosine" = "#008080",  # Teal
               "Fourier Series" = "#911EB4",
               "Triple Fourier" = "#800000",  # Maroon
               "Quadruple Fourier" = "#000080"  # Navy
          ),
          breaks = c(
               "Precipitation (2014-2024)", "Cholera Cases (2023-2024)",
               "Cosine Wave", "Double Cosine Wave", "Double Sine Wave",
               "Combined Sine Cosine", "Fourier Series",
               "Triple Fourier", "Quadruple Fourier"
          )
     ) +
     labs(title = "Fitted Seasonality Models to Scaled Precipitation Data",
          x = "Week",
          y = "Scaled Precipitation and Cholera Cases (Z-Score)",
          color = "Model") +
     theme_classic() +
     theme(
          plot.title = element_text(size = 16, face = "bold"),
          axis.title = element_text(size = 14),
          axis.text = element_text(size = 12),
          legend.text = element_text(size = 12),
          legend.title = element_blank(),
          panel.grid.major.y = element_line(color = "grey90", size = 0.25),  # Add horizontal gridlines
          panel.grid.minor.y = element_line(color = "grey90", size = 0.25)   # Add minor horizontal gridlines
     )

# Display the plot
print(p1)




# Function to calculate the Sum of Squared Errors (SSE)
calculate_sse <- function(actual_values, predicted_values) {
     sum((actual_values - predicted_values) ^ 2, na.rm = TRUE)
}

# Calculate SSE for each model
sse_results <- data.frame(
     Model = c(
          "Cosine Wave", "Double Cosine Wave", "Double Sine Wave",
          "Combined Sine Cosine", "Fourier Series",
          "Triple Fourier", "Quadruple Fourier"
     ),
     SSE_precip = c(
          calculate_sse(precip_data$precip_scaled, predict(fit_cosine)),
          calculate_sse(precip_data$precip_scaled, predict(fit_double_cosine)),
          calculate_sse(precip_data$precip_scaled, predict(fit_double_sine)),
          calculate_sse(precip_data$precip_scaled, predict(fit_combined_sine_cosine)),
          calculate_sse(precip_data$precip_scaled, predict(fit_fourier)),
          calculate_sse(precip_data$precip_scaled, predict(fit_triple_fourier)),
          calculate_sse(precip_data$precip_scaled, predict(fit_quadruple_fourier))
     ),
     SSE_cases = c(
          calculate_sse(precip_data$cases_scaled, predict(fit_cosine)),
          calculate_sse(precip_data$cases_scaled, predict(fit_double_cosine)),
          calculate_sse(precip_data$cases_scaled, predict(fit_double_sine)),
          calculate_sse(precip_data$cases_scaled, predict(fit_combined_sine_cosine)),
          calculate_sse(precip_data$cases_scaled, predict(fit_fourier)),
          calculate_sse(precip_data$cases_scaled, predict(fit_triple_fourier)),
          calculate_sse(precip_data$cases_scaled, predict(fit_quadruple_fourier))
     )
)

# Print the SSE results
print(sse_results)










################################################################################





png(filename = "./figures/seasonality_precipitation.png", height = 2000, width = 4000, units = "px", res=300)
combo
dev.off()








