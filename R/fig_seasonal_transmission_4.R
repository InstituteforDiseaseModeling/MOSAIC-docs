library(openmeteo)
library(httr)
library(jsonlite)
library(sf)
library(rnaturalearth)
library(sp)
library(ggplot2)
library(cowplot)
library(lubridate)
library(dplyr)
library(tidyr)
library(glue)
library(readr)
library(MOSAIC)
library(FNN)
library(stringr)

PATHS <- get_paths(root = "~/Library/CloudStorage/OneDrive-Bill&MelindaGatesFoundation/Projects/MOSAIC")


# Load cholera cases data
cholera_data <- read_csv(file.path(getwd(), "data/cholera_country_weekly_processed.csv"))


iso_codes <- MOSAIC::iso_codes_mosaic
iso_codes_with_data <- sort(unique(cholera_data$iso_code))
iso_codes_no_data <- setdiff(iso_codes, unique(cholera_data$iso_code))





################################################################################
# Model seasonal dynamics of cases and precip using fourier series
################################################################################


# Initialize lists to store results for all countries
all_precip_data <- list()
all_fitted_values <- list()
all_param_values <- list()
all_sse_results <- list()

# Loop over each country in iso_codes
for (country_iso_code in iso_codes_mosaic) {

     print(country_iso_code)

     country_name <- MOSAIC::convert_iso3_to_country(country_iso_code)
     country_shp <- sf::st_read(dsn=file.path(PATHS$DATA_SHAPEFILES, paste0(country_iso_code, "_ADM0.shp")))

     grid_points <- MOSAIC::generate_country_grid_n(country_shp, n_points = 10)
     coords <- st_coordinates(grid_points)
     coords <- as.data.frame(coords)
     colnames(coords) <- c("Longitude", "Latitude")


     p <-
          ggplot() +
          geom_sf(data = country_shp, fill = "#fef6e1") +
          geom_sf(data = grid_points, color = "black", size = 2) +
          labs(title = glue("Grid of sampling points in {country_shp$ADM0}"),
               x = NULL, y = NULL) +
          theme_minimal()

     print(p)



     # Initialize an empty list to store the precipitation data
     precipitation_data_list <- list()

     # Loop through each point to retrieve precipitation data
     for (i in 1:nrow(coords)) {

          lat <- coords$Latitude[i]
          lon <- coords$Longitude[i]

          tmp <- get_historical_precip(lat, lon, as.Date("2014-09-01"), as.Date("2024-09-01"), api_key = "aWshPbO8h8az9ico")

          tmp$year <- lubridate::year(tmp$date)

          tmp <- suppressMessages(
               tmp %>%
                    mutate(week = week(date)) %>%
                    group_by(year, week) %>%
                    summarize(weekly_precipitation_sum = sum(daily_precipitation_sum, na.rm = TRUE))
          )

          tmp$id <- i
          tmp$iso_code <- country_iso_code

          precipitation_data_list[[i]] <- tmp
     }

     precip_data <- do.call(rbind, precipitation_data_list)

     # Merge with cholera data by week and ISO code
     precip_data <- merge(precip_data, cholera_data, by = c("week", "iso_code"), all.x=TRUE)

     # Scale the precipitation values
     precip_data$precip_scaled <- (precip_data$weekly_precipitation_sum - mean(precip_data$weekly_precipitation_sum, na.rm = TRUE)) /
          sd(precip_data$weekly_precipitation_sum, na.rm = TRUE)

     # Scale the cholera cases
     precip_data$cases_scaled <- (precip_data$cases - mean(precip_data$cases, na.rm = TRUE)) /
          sd(precip_data$cases, na.rm = TRUE)

     # Fit the Generalized Fourier Series model to precipitation data
     fit_fourier_precip <- nls(precip_scaled ~ generalized_fourier(week, beta0, a1, b1, a2, b2, p),
                               data = precip_data,
                               start = list(beta0 = 0, a1 = 1, b1 = 1, a2 = 1/2, b2 = 1/2, p = 52),
                               algorithm = "port",
                               lower = c(beta0 = 0, a1 = -Inf, b1 = -Inf, a2 = -Inf, b2 = -Inf, p = 52),
                               upper = c(beta0 = 0, a1 = Inf, b1 = Inf, a2 = Inf, b2 = Inf, p = 52))


     coefs_precip <- summary(fit_fourier_precip)$coefficients

     param_values_precip <- data.frame(
          country_name = country_name,
          country_iso_code = country_iso_code,
          response = "precipitation",
          parameter = row.names(coefs_precip),
          mean = coefs_precip[,'Estimate'],
          se = coefs_precip[,'Std. Error'],
          ci_lo = coefs_precip[,'Estimate'] - coefs_precip[,'Std. Error']*1.96,
          ci_hi = coefs_precip[,'Estimate'] + coefs_precip[,'Std. Error']*1.96
     )

     if (country_iso_code %in% iso_codes_with_data) {

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

          fitted_values <- data.frame(
               week = seq(min(precip_data$week), max(precip_data$week), length.out = 100),
               iso_code = country_iso_code,
               fitted_values_fourier_precip = predict(fit_fourier_precip, newdata = data.frame(week = week_seq)),
               fitted_values_fourier_cases = predict(fit_fourier_cases, newdata = data.frame(week = week_seq))
          )

          coefs_cases <- summary(fit_fourier_cases)$coefficients

          param_values_cases <- data.frame(
               country_name = country_name,
               country_iso_code = country_iso_code,
               response = "cases",
               parameter = row.names(coefs_cases),
               mean = coefs_cases[,'Estimate'],
               se = coefs_cases[,'Std. Error'],
               ci_lo = coefs_cases[,'Estimate'] - coefs_cases[,'Std. Error']*1.96,
               ci_hi = coefs_cases[,'Estimate'] + coefs_cases[,'Std. Error']*1.96
          )


     } else {

          fitted_values <- data.frame(
               week = seq(min(precip_data$week), max(precip_data$week), length.out = 100),
               iso_code = country_iso_code,
               fitted_values_fourier_precip = predict(fit_fourier_precip, newdata = data.frame(week = week_seq)),
               fitted_values_fourier_cases = as.numeric(rep(NA, length(week_seq)))
          )

          param_values_cases <- data.frame(
               country_name = country_name,
               country_iso_code = country_iso_code,
               response = "cases",
               parameter = row.names(coefs_precip),
               mean = NA,
               se = NA,
               ci_lo = NA,
               ci_hi = NA
          )

     }

     precip_data$Country <- country_name  # Add country name to precip_data
     fitted_values$Country <- country_name  # Add country name to fitted_values

     param_values <- rbind(param_values_precip, param_values_cases)
     row.names(param_values) <- NULL

     all_precip_data[[country_iso_code]] <- precip_data
     all_fitted_values[[country_iso_code]] <- fitted_values
     all_param_values[[country_iso_code]] <- param_values

}


# Combine all results into a single dataframe
combined_precip_data <- do.call(rbind, all_precip_data)
combined_fitted_values <- do.call(rbind, all_fitted_values)
combined_param_values <- do.call(rbind, all_param_values)
combined_param_values <- combined_param_values[!(combined_param_values$parameter %in% c('beta0', 'p')),]


combined_fitted_values$inferred_from_neighbor <- NA
combined_param_values$inferred_from_neighbor <- NA


# Save combined_param_values to a CSV file
write.csv(combined_param_values, "./tables/combined_param_values.csv", row.names = FALSE)




################################################################################

# Check within cluster first, if not neighbors with data then get nearest neighbor
# with highest precip correlation

################################################################################

library(FNN)  # For k-nearest neighbors
library(sf)

# Step 1: Perform hierarchical clustering with k = 4

# Prepare data for clustering
precip_fitted_df <- combined_fitted_values %>%
     filter(!is.na(fitted_values_fourier_precip)) %>%
     select(iso_code, week, fitted_values_fourier_precip) %>%
     spread(key = week, value = fitted_values_fourier_precip)  # Reshape data

# Remove rows with missing data
precip_fitted_df <- na.omit(precip_fitted_df)

# Perform hierarchical clustering with k = 4
set.seed(123)
precip_matrix <- precip_fitted_df %>% select(-iso_code)
dist_matrix <- dist(precip_matrix)  # Compute distance matrix
hc <- hclust(dist_matrix, method = "ward.D2")
precip_fitted_df$cluster <- cutree(hc, k = 4)  # Assign countries to 4 clusters

# Step 2: Merge clustering results with spatial data

world <- ne_countries(scale = "medium", returnclass = "sf")  # Load medium scale Natural Earth countries data
africa <- world %>% filter(continent == "Africa")  # Filter to get only African countries

africa_with_clusters <- africa %>%
     left_join(precip_fitted_df %>% select(iso_code, cluster), by = c("iso_a3" = "iso_code"))

africa_with_clusters <- africa_with_clusters[!(africa_with_clusters$iso_a3 %in% c("ZAF")),]

# Step 3: Calculate centroids for all African countries
centroids <- st_centroid(africa)
coords <- st_coordinates(centroids)

# Initial value of k for nearest neighbors
initial_k <- 10

# Step 4: Loop through countries with no cholera data and select the best neighbor

for (country_iso_code_no_data in iso_codes_no_data) {

     print(glue("Processing country with no cholera data: {country_iso_code_no_data}"))

     # Get the shapefile for the country with no data
     country_shp_no_data <- sf::st_read(dsn = file.path(PATHS$DATA_SHAPEFILES, paste0(country_iso_code_no_data, "_ADM0.shp")))

     # Ensure both country_shp_no_data and africa have the same CRS
     country_shp_no_data <- st_transform(country_shp_no_data, st_crs(africa))

     # Get the centroid of the country with no data
     centroid_no_data <- st_centroid(country_shp_no_data)
     coord_no_data <- st_coordinates(centroid_no_data)

     # Get the cluster assignment for the country with no data
     country_cluster <- precip_fitted_df %>%
          filter(iso_code == country_iso_code_no_data) %>%
          pull(cluster)

     # Initialize variables for tracking the best neighbor
     best_neighbor_iso_code <- NULL
     highest_corr <- -Inf

     # Step 5: Check for neighbors within the same cluster
     neighbors_within_cluster <- africa_with_clusters %>%
          filter(cluster == country_cluster, iso_a3 != country_iso_code_no_data, iso_a3 %in% iso_codes_with_data)

     if (nrow(neighbors_within_cluster) > 0) {

          print(glue("Found neighbors within the same cluster for {country_iso_code_no_data}"))

          # Get the precipitation data for the country with no data
          precip_no_data <- all_precip_data[[country_iso_code_no_data]] %>%
               select(year, week, weekly_precipitation_sum)

          # Loop through neighbors within the cluster and find the best one based on correlation
          for (neighbor_iso_code in neighbors_within_cluster$iso_a3) {

               precip_neighbor <- all_precip_data[[neighbor_iso_code]] %>%
                    select(year, week, weekly_precipitation_sum)

               # Merge data by year and week for correlation calculation
               merged_precip <- merge(precip_no_data, precip_neighbor, by = c("year", "week"), suffixes = c("_no_data", "_neighbor"))

               if (nrow(merged_precip) > 0) {

                    # Calculate Pearson correlation
                    corr <- cor(merged_precip$weekly_precipitation_sum_no_data, merged_precip$weekly_precipitation_sum_neighbor, use = "complete.obs")

                    print(glue("Correlation between {country_iso_code_no_data} and {neighbor_iso_code}: {corr}"))

                    # Update the best neighbor if this correlation is higher
                    if (corr > highest_corr) {
                         highest_corr <- corr
                         best_neighbor_iso_code <- neighbor_iso_code
                    }
               }
          }

     }

     # Step 6: If no valid neighbor is found within the cluster, check k-nearest neighbors
     if (is.null(best_neighbor_iso_code)) {
          print(glue("No neighbors within the same cluster for {country_iso_code_no_data}. Checking nearest neighbors."))

          k <- initial_k

          while (is.null(best_neighbor_iso_code)) {

               # Find k-nearest neighbors based on centroid distance
               k_neighbors <- get.knnx(coords, coord_no_data, k = k)
               nearest_neighbors <- africa[k_neighbors$nn.index, ]

               # Filter neighbors to only include those that have cholera data
               neighbors_with_data <- nearest_neighbors %>%
                    filter(iso_a3 %in% iso_codes_with_data)

               if (nrow(neighbors_with_data) == 0) {
                    print(glue("No neighbors with data found with k = {k}. Increasing k."))
                    k <- k + 1  # Increase k until a valid neighbor with data is found
               }

               # Stop if k exceeds the total number of available neighbors
               if (k > nrow(africa)) {
                    print(glue("No valid neighbors found for {country_iso_code_no_data} even after increasing k. Skipping."))
                    next
               }

               # Get the precipitation data (weekly_precipitation_sum) for the country with no data
               precip_no_data <- all_precip_data[[country_iso_code_no_data]] %>%
                    select(year, week, weekly_precipitation_sum)

               # Loop through k-nearest neighbors and calculate the correlation between weekly_precipitation_sum
               for (neighbor_iso_code in neighbors_with_data$iso_a3) {

                    precip_neighbor <- all_precip_data[[neighbor_iso_code]] %>%
                         select(year, week, weekly_precipitation_sum)

                    # Merge data by year and week for correlation calculation
                    merged_precip <- merge(precip_no_data, precip_neighbor, by = c("year", "week"), suffixes = c("_no_data", "_neighbor"))

                    if (nrow(merged_precip) > 0) {

                         # Calculate Pearson correlation
                         corr <- cor(merged_precip$weekly_precipitation_sum_no_data, merged_precip$weekly_precipitation_sum_neighbor, use = "complete.obs")

                         print(glue("Correlation between {country_iso_code_no_data} and {neighbor_iso_code}: {corr}"))

                         # Update the best neighbor if this correlation is higher and positive
                         if (corr > highest_corr) {
                              highest_corr <- corr
                              best_neighbor_iso_code <- neighbor_iso_code
                         }
                    }
               }
          }
     }

     # Step 7: If a best neighbor is found, assign the fitted and parameter values
     if (!is.null(best_neighbor_iso_code)) {

          print(glue("Best neighbor based on correlation: {best_neighbor_iso_code} with correlation {highest_corr}"))

          combined_fitted_values[combined_fitted_values$iso_code == country_iso_code_no_data, 'fitted_values_fourier_cases'] <-
               combined_fitted_values[combined_fitted_values$iso_code == best_neighbor_iso_code, 'fitted_values_fourier_cases']

          combined_fitted_values[combined_fitted_values$iso_code == country_iso_code_no_data, 'inferred_from_neighbor'] <- convert_iso3_to_country(best_neighbor_iso_code)

          combined_param_values[combined_param_values$country_iso_code == country_iso_code_no_data & combined_param_values$response == 'cases', c('parameter', 'mean', 'se', 'ci_lo', 'ci_hi')] <-
               combined_param_values[combined_param_values$country_iso_code == best_neighbor_iso_code & combined_param_values$response == 'cases', c('parameter', 'mean', 'se', 'ci_lo', 'ci_hi')]

          combined_param_values[combined_param_values$country_iso_code == country_iso_code_no_data & combined_param_values$response == 'cases', 'inferred_from_neighbor'] <- convert_iso3_to_country(best_neighbor_iso_code)

          print(glue("Assigned data from {best_neighbor_iso_code} to {country_iso_code_no_data}"))

     } else {
          print(glue("No valid neighbor found with a positive correlation for {country_iso_code_no_data}."))
     }
}










################################################################################

# Plot precip and cases data as Z-score. Add Fourier series model fits and indicate
# if the Fourier series model for cases was inferred from another location

################################################################################


# Updated plot to include annotation for countries with inferred data and boxplots for precipitation
p_facet <- ggplot(combined_precip_data, aes(x = factor(week))) +  # Use factor for weeks for boxplots

     geom_hline(yintercept = 0, color = "black") +

     # Replace geom_point with geom_boxplot for precipitation values and hide outliers
     #geom_boxplot(aes(y = precip_scaled, color = "Precipitation (1994-2024)"),
     #             fill = 'lightblue', outlier.shape = NA, alpha = 0.3) +

     geom_point(aes(x= week, y = cases_scaled, color = "Cholera Cases (2023-2024)"), size = 1.5) +

     geom_line(data = combined_fitted_values, aes(x = week, y = fitted_values_fourier_precip, color = "Fourier Series (Precip)"), size = 2) +

     geom_line(data = combined_fitted_values[combined_fitted_values$iso_code %in% iso_codes_with_data,],
               aes(x = week, y = fitted_values_fourier_cases, color = "Fourier Series (Cases)"), size = 2) +

     geom_line(data = combined_fitted_values[combined_fitted_values$iso_code %in% iso_codes_no_data,],
               aes(x = week, y = fitted_values_fourier_cases, color = "Fourier Series (Cases)"), size = 2) +

     # Annotate the inferred country for panels with no cases data
     geom_text(data = combined_fitted_values %>% filter(!is.na(inferred_from_neighbor)),
               aes(x = 15, y = Inf, label = glue("Inferred from:\n{inferred_from_neighbor}")),
               vjust = 1.2, hjust = 0.5, size = 2.5, color = "#DC143C") +

     scale_x_continuous(breaks = c(1, 10, 20, 30, 40, 52)) +

     scale_color_manual(
          values = c(
               "Precipitation (1994-2024)" = "black",  # This won't affect the boxplot
               "Cholera Cases (2023-2024)" = "#FFA500",
               "Fourier Series (Precip)" = "#004CFF",
               "Fourier Series (Cases)" = "#DC143C"
          ),
          breaks = c(
               "Precipitation (1994-2024)",
               "Cholera Cases (2023-2024)",
               "Fourier Series (Precip)",
               "Fourier Series (Cases)"
          )
     ) +

     labs(x = "Week of Year",
          y = "Scaled Precipitation and Cholera Cases (Z-Score)") +

     theme_minimal() +
     theme(
          plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
          axis.title.x = element_text(size = 14, margin = margin(t = 20)),
          axis.title.y = element_text(size = 14, margin = margin(r = 20)),
          axis.text = element_text(size = 12),
          legend.text = element_text(size = 12),
          legend.title = element_blank(),
          legend.position = "bottom",  # Position the legend at the bottom
          legend.box = "vertical",  # Arrange the legends vertically
          legend.box.just = "left",
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(color = "grey90", size = 0.25),
          panel.grid.minor = element_blank(),
          strip.text = element_text(size = 11)
     ) +

     # Arrange legends in two columns
     guides(color = guide_legend(nrow = 1, byrow = TRUE)) +

     facet_wrap(~ Country, scales = "free_y", ncol=4)


print(p_facet)


png(filename = "./figures/seasonal_transmission_all.png", width = 10.5, height = 16, units = "in", res=300)
p_facet
dev.off()









################################################################################

# Plot clustering

################################################################################

library(ggplot2)
library(dplyr)
library(sf)
library(cowplot)
library(RColorBrewer)
library(cluster)  # For hierarchical clustering
library(dbscan)   # For DBSCAN
library(FNN)      # For kNN

# Toggle between using Fourier for precipitation or cases
use_cases <- F  # Set to TRUE to use Fourier fitted values for cases instead of precipitation

# Option to set inferred countries to NA
set_inferred_to_na <- T  # Set to TRUE if you want inferred countries to be set to NA
if (!use_cases) set_inferred_to_na <- FALSE

# Extract Fourier fitted values for the selected type (precipitation or cases)
if (use_cases) {
     fitted_column <- "fitted_values_fourier_cases"
     plot_title <- "Fourier series fitted to cholera cases (2023-2024)"
     map_title <- "Clustering of countries based on seasonal transmission"
} else {
     fitted_column <- "fitted_values_fourier_precip"
     plot_title <- "Fourier series fitted to weekly precipitation (1994-2024)"
     map_title <- "Clustering of countries based on seasonal precipitation"
}

# Extract Fourier fitted values (for precipitation or cases) and create a data frame
precip_fitted_df <- combined_fitted_values %>%
     filter(!is.na(!!sym(fitted_column))) %>%  # Filter out rows without fitted values
     select(iso_code, week, !!sym(fitted_column)) %>%
     spread(key = week, value = !!sym(fitted_column))  # Reshape to have one row per country, weeks as columns

# Remove rows with NA values (countries with incomplete data)
precip_fitted_df <- na.omit(precip_fitted_df)

# Define clustering method (choose: "kmeans", "hierarchical", "dbscan", "knn")
clustering_method <- "hierarchical"  # You can change this to test different methods
k <- 4  # Number of clusters for k-means and hierarchical

# Step 2: Perform clustering based on the chosen method
precip_matrix <- precip_fitted_df %>% select(-iso_code)  # Exclude the country codes for clustering

if (clustering_method == "kmeans") {
     set.seed(123)  # Set seed for reproducibility
     # K-means clustering
     clustering_result <- kmeans(precip_matrix, centers = k)
     precip_fitted_df$cluster <- clustering_result$cluster
} else if (clustering_method == "hierarchical") {
     # Hierarchical clustering
     dist_matrix <- dist(precip_matrix)  # Compute the distance matrix
     hc <- hclust(dist_matrix, method = "ward.D2")
     precip_fitted_df$cluster <- cutree(hc, k = k)  # Cut tree into k clusters
} else if (clustering_method == "dbscan") {
     # DBSCAN clustering
     set.seed(123)
     dbscan_result <- dbscan(precip_matrix, eps = 1, minPts = 3)  # Tune eps and minPts
     precip_fitted_df$cluster <- as.factor(dbscan_result$cluster)
} else if (clustering_method == "knn") {
     set.seed(123)
     # KNN-based clustering using k-means on distances between nearest neighbors
     knn_distances <- get.knn(precip_matrix, k = k)$nn.dist  # Get distances from k nearest neighbors
     knn_clustering <- kmeans(knn_distances, centers = k)
     precip_fitted_df$cluster <- knn_clustering$cluster
} else {
     stop("Invalid clustering method specified.")
}

# Step 3: Merge clustering results with the spatial data (shapefiles of African countries)
africa_with_clusters <- africa %>%
     left_join(precip_fitted_df, by = c("iso_a3" = "iso_code"))

# Step 4: Optionally set inferred countries to NA
if (set_inferred_to_na) {

     #africa_with_clusters <- africa_with_clusters %>%
     #     mutate(cluster = ifelse(!is.na(inferred_from_neighbor), NA, cluster))  # Set cluster to NA if inferred

     countries_with_case_data <- unique(combined_fitted_values$iso_code[is.na(combined_fitted_values$inferred_from_neighbor)])

     sel <- !(africa_with_clusters$iso_a3 %in% countries_with_case_data)
     africa_with_clusters[sel, 'cluster'] <- NA

     }

# Define cluster colors
cluster_colors <- RColorBrewer::brewer.pal(length(unique(africa_with_clusters$cluster)) + 1, "Set1")
cluster_colors <- RColorBrewer::brewer.pal(9, "Set1")[-6]  # Exclude yellow from Set1 palette
cluster_colors <- cluster_colors[1:length(unique(africa_with_clusters$cluster))]  # Adjust for the number of clusters

# Step 5: Plot the map with countries colored by their cluster assignments
map_plot <- ggplot(africa_with_clusters) +
     geom_sf(aes(fill = as.factor(cluster))) +  # Color countries by their cluster assignments
     scale_fill_manual(values = cluster_colors, na.value = "grey95") +
     labs(title = str_wrap(map_title, 30),
          subtitle = "",
          fill = "Cluster") +
     theme_minimal() +
     theme(legend.position = "bottom",
           plot.title = element_text(hjust=0.5))

# Step 6: Create a multi-panel plot to show Fourier fitted values (for precipitation or cases) for each cluster
fitted_for_plot <- combined_fitted_values %>%
     left_join(precip_fitted_df %>% select(iso_code, cluster), by = "iso_code") %>%
     filter(!is.na(cluster))

facet_plot <- ggplot(fitted_for_plot, aes(x = week, y = !!sym(fitted_column), group = iso_code, color = as.factor(cluster))) +
     geom_hline(yintercept = 0) +
     geom_line(alpha = 1) +  # Plot all lines for countries in the cluster
     facet_wrap(~ cluster, scales = "free_y") +  # Facet by cluster
     scale_color_manual(values = cluster_colors) +  # Match colors for clusters
     scale_x_continuous(breaks = c(1, 10, 20, 30, 40, 52)) +
     labs(title = str_wrap(plot_title, 40),
          x = "Week", y = "Z-score") +
     theme_minimal() +
     theme(
          legend.position = "none",
          panel.grid.minor = element_blank(),
          plot.title = element_text(hjust=0.5)
     )

# Step 7: Combine the map and the facet plot using cowplot
combined_plot <- plot_grid(map_plot, facet_plot, ncol = 2, rel_widths = c(1, 1.5), labels=c("A","B"))

# Print the combined plot
print(combined_plot)


# Save the plot as an image
png(filename = glue("./figures/seasonal_{ifelse(use_cases, 'cases', 'precip')}_{clustering_method}_cluster{ifelse(set_inferred_to_na, '_inferred', '')}.png"),
    width = 8, height = 5, units = "in", res = 300)
print(combined_plot)
dev.off()







################################################################################

# Plot map with grid points and example seasonal plot

################################################################################

country_iso_code <- "MOZ"
country_name <- MOSAIC::convert_iso3_to_country(country_iso_code)
country_shp <- sf::st_read(dsn=file.path(PATHS$DATA_SHAPEFILES, paste0(country_iso_code, "_ADM0.shp")))

grid_points <- MOSAIC::generate_country_grid_n(country_shp, n_points = 30)
coords <- st_coordinates(grid_points)
coords <- as.data.frame(coords)
colnames(coords) <- c("Longitude", "Latitude")


p1 <-
     ggplot() +
     geom_sf(data = country_shp, fill = "#fef6e1") +
     geom_sf(data = grid_points, color = "black", size = 1.5) +
     labs(title = glue("Grid of sampling points\nin {country_shp$ADM0}"),
          subtitle = "",
          x = NULL, y = NULL) +
     theme_minimal() +
     theme(
          plot.title = element_text(hjust = 0.5),
          plot.margin = margin(3, 3, 3, 3)
     )



tmp_precip <- combined_precip_data[combined_precip_data$iso_code == country_iso_code,]
tmp_fit <- combined_fitted_values[combined_fitted_values$iso_code == country_iso_code,]

p2 <-
     ggplot(tmp_precip, aes(x = factor(week))) +  # Use factor for weeks for boxplots

     geom_hline(yintercept = 0, color = "black") +

     # Replace geom_point with geom_boxplot for precipitation values and hide outliers
     #geom_boxplot(aes(y = precip_scaled, color = "Precipitation (1994-2024)"),
     #             fill = 'lightblue', outlier.shape = NA, alpha = 0.3) +
     geom_point(aes(y = precip_scaled, color = "Precipitation (1994-2024)"), size = 3, alpha = 0.05) +

     geom_point(aes(x= week, y = cases_scaled, color = "Cholera Cases (2023-2024)"), size = 2.25) +

     geom_line(data = tmp_fit, aes(x = week, y = fitted_values_fourier_precip, color = "Fourier Series (Precip)"), size = 2.5) +

     geom_line(data = tmp_fit[tmp_fit$iso_code %in% iso_codes_with_data,],
               aes(x = week, y = fitted_values_fourier_cases, color = "Fourier Series (Cases)"), size = 2.5) +

     geom_line(data = tmp_fit[tmp_fit$iso_code %in% iso_codes_no_data,],
               aes(x = week, y = fitted_values_fourier_cases, color = "Fourier Series (Cases)"), size = 2.5) +

     # Annotate the inferred country for panels with no cases data
     geom_text(data = tmp_fit %>% filter(!is.na(inferred_from_neighbor)),
               aes(x = 15, y = Inf, label = glue("Inferred from:\n{inferred_from_neighbor}")),
               vjust = 1.2, hjust = 0.5, size = 2.5, color = "#DC143C") +

     scale_x_discrete(breaks = c(1, 10, 20, 30, 40, 52)) +
     scale_y_continuous(limits = c(min(c(tmp_fit$fitted_values_fourier_precip, tmp_fit$fitted_values_fourier_cases)), 8)) +

     scale_color_manual(
          values = c(
               "Precipitation (1994-2024)" = "black",  # This won't affect the boxplot
               "Cholera Cases (2023-2024)" = "#FFA500",
               "Fourier Series (Precip)" = "#004CFF",
               "Fourier Series (Cases)" = "#DC143C"
          ),
          breaks = c(
               "Precipitation (1994-2024)",
               "Cholera Cases (2023-2024)",
               "Fourier Series (Precip)",
               "Fourier Series (Cases)"
          )
     ) +

     labs(title = "Scaled Precipitation and\nCholera Cases (Z-Score)",
          subtitle = "",
          x = "Week of Year",
          y = "Z-Score") +

     theme_minimal() +
     theme(
          plot.title = element_text(hjust = 0.5),
          axis.title.x = element_text(size = 14, margin = margin(t = 20)),
          axis.title.y = element_text(size = 14, margin = margin(r = 20)),
          axis.text = element_text(size = 12),
          legend.text = element_text(size = 12),
          legend.title = element_blank(),
          legend.position = "right",  # Position the legend at the bottom
          legend.box = "vertical",  # Arrange the legends vertically
          legend.box.just = "left",
          panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(color = "grey90", size = 0.25),
          panel.grid.minor = element_blank(),
          strip.text = element_text(size = 11),
          plot.margin = margin(3, 3, 3, 3)
     ) +

     # Arrange legends in two columns
     guides(color = guide_legend(ncol = 2, byrow = TRUE))







p2_no_legend <- p2 + theme(legend.position = "none")

# Extract the legend of p2
legend_p2 <- cowplot::get_legend(p2)

# Combine p1 and p2 without the legend in a two-panel layout
combined_plot <- plot_grid(
     p1, p2_no_legend, ncol = 2, rel_widths = c(1.2, 2), align = 'h', labels = c("A", "B")
)

# Place the legend below the combined plot in a new row
final_plot <- plot_grid(combined_plot, legend_p2, ncol = 1, rel_heights = c(1, 0.2))

# Display the final plot
print(final_plot)

png(filename = glue("./figures/seasonal_transmission_example_{country_iso_code}.png"), width = 8, height = 5.5, units = "in", res = 300)
print(final_plot)
dev.off()




