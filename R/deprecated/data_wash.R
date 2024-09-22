library(ggplot2)
library(reshape2)
library(dplyr)
library(gtools)
library(countrycode)

convert_country_to_iso3 <- function(country_names) {
     iso3_codes <- countrycode::countrycode(country_names, origin = "country.name", destination = "iso3c", warn = TRUE)
     return(iso3_codes)
}

convert_iso3_to_country <- function(iso3_codes) {
     country_names <- countrycode::countrycode(iso3_codes, origin = "iso3c", destination = "country.name")
     return(country_names)
}


afro_iso_codes <- c(
     "AGO", "BEN", "BWA", "BFA", "BDI", "CMR", "CAF", "TCD",
     "COM", "COG", "COD", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB",
     "GHA", "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT",
     "MUS", "MOZ", "NAM", "NER", "NGA", "RWA", "SEN", "SLE",
     "SOM", "ZAF", "SSD", "TGO", "UGA", "TZA", "ZMB", "ZWE"
)


################################################################################
# Make dataframe from Sikder et al 2023 data
################################################################################

chunk1 <- data.frame(
     Country = c("Angola", "Burundi", "Benin", "Burkina Faso", "Central African Republic", "Cote dIvoire",
                 "Cameroon", "Democratic Republic of Congo", "Congo", "Ethiopia", "Gabon", "Ghana", "Guinea",
                 "Gambia", "Guinea-Bissau", "Equatorial Guinea", "Kenya", "Liberia", "Madagascar", "Mali",
                 "Mozambique", "Mauritania", "Malawi", "Namibia", "Niger"),
     Piped_Water = c(32.0, 36.4, 39.1, 18.0, 12.1, 42.6, 35.7, 21.2, 27.1, 37.5, 61.9, 28.3, 23.9,
                     63.0, 23.8, 39.0, 31.5, 2.9, 23.9, 32.6, 39.9, 48.1, 21.3, 73.2, 39.6),
     Other_Improved_Water = c(26.6, 46.4, 33.2, 58.4, 46.4, 35.2, 34.6, 22.3, 34.2, 23.2, 20.7, 54.9, 49.8,
                              23.4, 34.7, 30.8, 28.5, 69.8, 19.1, 34.4, 12.5, 31.0, 62.1, 8.5, 28.0),
     Septic_or_Sewer_Sanitation = c(32.6, 5.0, 3.6, 1.3, 0.4, 15.8, 9.7, 3.9, 4.8, 1.9, 20.9, 13.3, 9.5,
                                    7.3, 7.0, 8.3, 6.2, 9.8, 3.2, 4.1, 1.3, 7.1, 1.5, 35.9, 4.7),
     Other_Improved_Sanitation = c(9.5, 47.6, 23.9, 29.6, 32.3, 29.2, 44.6, 35.9, 26.2, 17.2, 16.0, 48.3, 32.3,
                                   56.2, 46.0, 33.8, 41.5, 22.8, 8.6, 37.8, 24.2, 38.4, 40.9, 7.6, 18.4),
     Unimproved_Water = c(11.5, 11.4, 21.6, 21.7, 37.6, 14.3, 20.7, 45.3, 21.3, 23.4, 1.8, 4.7, 13.0,
                          13.4, 41.1, 16.3, 13.4, 7.5, 32.7, 29.1, 33.0, 20.4, 12.6, 10.5, 31.4),
     Surface_Water = c(29.9, 5.8, 6.1, 1.9, 4.0, 7.8, 9.0, 11.2, 17.4, 16.0, 15.6, 12.1, 13.3,
                       0.2, 0.4, 13.8, 26.6, 19.8, 24.3, 3.9, 14.6, 0.5, 4.1, 7.7, 1.0),
     Unimproved_Sanitation = c(28.4, 43.1, 7.7, 3.3, 39.1, 17.2, 37.2, 43.9, 50.3, 40.6, 49.3, 7.6, 38.6,
                               12.3, 20.8, 50.9, 33.4, 12.5, 36.8, 44.1, 35.1, 11.6, 47.7, 3.4, 14.1),
     Open_Defecation = c(29.5, 4.3, 64.8, 65.8, 28.2, 37.7, 8.5, 16.3, 18.8, 40.3, 13.8, 30.9, 19.6,
                         24.1, 26.1, 7.0, 18.9, 54.9, 51.4, 14.0, 39.4, 42.9, 9.9, 53.1, 62.8),
     Incidence_per_1000 = c(0.09904, 0.24680, 0.04665, 0.00358, 0.02886, 0.01891, 0.50913, 0.36399,
                            0.20317, 0.06755, 0.00033, 0.40156, 0.20086, 0.00612, 0.39827, 0.00100,
                            0.17645, 0.11201, 0.00895, 0.03260, 0.12538, 0.01136, 0.03755, 0.17558, 0.06494)
)

chunk2 <- data.frame(
     Country = c("Nigeria", "Rwanda", "Sudan", "Senegal", "Sierra Leone", "Somalia", "South Sudan",
                 "Swaziland", "Chad", "Togo", "Tanzania", "Uganda", "South Africa", "Zambia", "Zimbabwe"),
     Piped_Water = c(11.1, 33.9, 28.3, 56.8, 16.1, 32.3, 3.2, 54.3, 18.9, 27.6, 38.2, 18.0, 87.6, 28.4, 32.9),
     Other_Improved_Water = c(53.1, 39.8, 44.7, 12.3, 40.3, 52.8, 30.9, 16.9, 36.3, 33.9, 20.4, 57.8, 3.9, 28.9, 42.6),
     Septic_or_Sewer_Sanitation = c(15.8, 0.6, 0.1, 15.8, 4.8, 7.6, 0.7, 16.2, 1.6, 10.4, 4.9, 0.2, 55.4, 3.7, 32.3),
     Other_Improved_Sanitation = c(27.1, 84.1, 20.3, 53.7, 42.7, 27.5, 12.1, 62.3, 13.5, 20.3, 29.1, 78.7, 19.8, 32.2, 29.4),
     Unimproved_Water = c(19.4, 15.1, 21.5, 30.5, 19.4, 5.3, 48.7, 10.1, 37.5, 18.9, 25.0, 13.6, 2.3, 27.4, 14.6),
     Surface_Water = c(16.4, 11.2, 5.6, 0.4, 24.2, 9.6, 17.2, 18.7, 7.2, 19.7, 16.4, 10.6, 6.2, 15.4, 9.9),
     Unimproved_Sanitation = c(22.0, 13.4, 27.0, 6.9, 28.0, 7.8, 18.9, 8.7, 15.4, 9.2, 49.0, 10.2, 20.8, 43.6, 6.9),
     Open_Defecation = c(35.2, 1.9, 52.7, 23.6, 24.5, 57.1, 68.4, 12.8, 69.5, 60.1, 17.0, 10.9, 4.0, 20.6, 31.4),
     Incidence_per_1000 = c(0.10247, 0.01835, 0.00598, 0.00072, 1.89451, 1.27452, 0.61066, 0.00065,
                            0.86626, 0.01796, 0.18485, 0.03673, 0.00103, 0.11792, 0.03265)
)

wash_data <- rbind(chunk1, chunk2)
head(wash_data)

# Put on 0 to 1 scale and make present risk variables as complement (1 - value)
wash_variables <- colnames(wash_data)[2:9]
wash_variables_protective <- colnames(wash_data)[2:5]
wash_variables_risk <- colnames(wash_data)[6:9]

wash_data[,wash_variables] <- wash_data[,wash_variables]/100
wash_data[,wash_variables_risk] <- 1 - wash_data[,wash_variables_risk]

wash_data$iso_code <- convert_country_to_iso3(wash_data$Country)
wash_data$Country <- convert_iso3_to_country(wash_data$iso_code)
wash_data$Country[wash_data$iso_code == 'COD'] <- "Democratic Republic of Congo"
wash_data$Country[wash_data$iso_code == 'COG'] <- "Congo"







################################################################################
# Find weighted index
################################################################################

# Define the function to calculate weighted mean and return the negative correlation (for optimization)
calculate_weighted_correlation <- function(weights, data, wash_vars) {
     # Ensure weights sum to 1
     weights <- weights / sum(weights)

     # Calculate the weighted mean of WASH variables
     weighted_mean <- rowSums(sweep(data[, wash_vars], 2, weights, `*`))

     # Calculate the correlation with incidence
     correlation <- cor(weighted_mean, data$Incidence_per_1000, use = "complete.obs")

     # Return the negative correlation because optim minimizes the objective function
     return(correlation)
}


# Set a seed for reproducibility
set.seed(123)

# Generate initial weights using a Dirichlet distribution
#initial_weights <- gtools::rdirichlet(1, alpha = rep(1, length(wash_variables)))
initial_weights <- rep(1/length(wash_variables), length(wash_variables))


# Optimize the weights to maximize the correlation with incidence
optimal_weights <- optim(par = initial_weights,
                         fn = calculate_weighted_correlation,
                         data = wash_data,
                         wash_vars = wash_variables,
                         method = "L-BFGS-B",
                         lower = rep(0, length(wash_variables)),
                         upper = rep(1, length(wash_variables)),
                         control = list(maxit = 5000))

# Extract the optimized weights
best_weights <- optimal_weights$par / sum(optimal_weights$par)  # Normalize to sum to 1




# Calculate the weighted mean using the optimized weights
wash_data$Weighted_Mean_WASH <- rowSums(sweep(wash_data[, wash_variables], 2, best_weights, `*`))

# Calculate the correlation with incidence
best_correlation <- cor(wash_data$Weighted_Mean_WASH, wash_data$Incidence_per_1000, use = "complete.obs")

# Print the best weights and the corresponding correlation
print(paste("Optimized Weights:", paste(round(best_weights, 4), collapse = ", ")))
print(paste("Best Correlation with Incidence:", round(best_correlation, 4)))






################################################################################
# Plot relationships bt WASH and incidence
################################################################################

wash_data$Mean_WASH <- rowMeans(wash_data[, wash_variables])

# Add the Best Weighted Mean to the list of variables for plotting
wash_data_long <- melt(wash_data, id.vars = c("Country", "Incidence_per_1000"),
                       measure.vars = c(wash_variables, "Mean_WASH", "Weighted_Mean_WASH"), variable.name = "WASH_Variable", value.name = "Value")

wash_data_long$protective <- ifelse(wash_data_long$WASH_Variable %in% wash_variables_protective, 1, 0)
wash_data_long$risk <- ifelse(wash_data_long$WASH_Variable %in% wash_variables_risk, 1, 0)
wash_data_long$means <- ifelse(wash_data_long$WASH_Variable %in% c("Mean_WASH", "Weighted_Mean_WASH"), 1, 0)

# Recalculate correlations to include Weighted_Mean_WASH
correlations_weighted <- sapply(c(wash_variables, "Mean_WASH", "Weighted_Mean_WASH"), function(var) {
     cor(wash_data[[var]], wash_data$Incidence_per_1000, use = "complete.obs")
})


wash_data_long <- wash_data_long %>%
     group_by(WASH_Variable) %>%
     mutate(correlation_label = paste0("r = ", round(correlations_weighted[WASH_Variable], 2)))





tmp <- wash_data_long[wash_data_long$protective == 1,]
tmp$WASH_Variable <- gsub("_", " ", tmp$WASH_Variable)
tmp$WASH_Variable <- factor(tmp$WASH_Variable,
                            levels=c("Piped Water", "Septic or Sewer Sanitation", "Other Improved Water", "Other Improved Sanitation"))

p1 <-
     ggplot(tmp, aes(x = Value, y = Incidence_per_1000)) +
     geom_point(color = "black", size = 2, alpha=0.6) +
     geom_smooth(color = "#2ecc71", method = "lm", se = FALSE, size = 1) +
     facet_wrap(~ WASH_Variable, scales = "free_x") +
     geom_text(aes(label = correlation_label), x = Inf, y = Inf, hjust = 1.75, vjust = 2, size = 3.5, color = "black") +
     labs(title = "A",
          subtitle = "Protective WASH variables",
          x = NULL,
          y = "Incidence per 1,000") +
     scale_x_continuous(limits = c(0,1)) +
     theme_minimal() +
     theme(plot.title = element_text(size = 13, face = "bold"),
           plot.subtitle = element_text(size = 13, face='bold', hjust = 0.5),
           axis.title.x = element_text(size = 12, margin = margin(t = 20)),
           axis.title.y = element_text(size = 12, margin = margin(r = 20)),
           axis.text = element_text(size = 10),
           strip.text = element_text(size = 12),
           legend.position = "none",
           panel.grid.minor = element_blank())




tmp <- wash_data_long[wash_data_long$risk == 1,]
tmp$WASH_Variable <- gsub("_", " ", tmp$WASH_Variable)
tmp$WASH_Variable <- factor(tmp$WASH_Variable,
                            levels=c("Surface Water", "Open Defecation", "Unimproved Water", "Unimproved Sanitation"))


p2 <-
     ggplot(tmp, aes(x = Value, y = Incidence_per_1000)) +
     geom_point(color = "black", size = 2, alpha=0.6) +
     geom_smooth(color = "#e67e22", method = "lm", se = FALSE, size = 1) +
     facet_wrap(~ WASH_Variable, scales = "free_x") +
     geom_text(aes(label = correlation_label), x = Inf, y = Inf, hjust = 1.75, vjust = 2, size = 3.5, color = "black") +
     labs(title = "B",
          subtitle = "Risk WASH variables (1-value)",
          x = NULL,
          y = "Incidence per 1,000") +
     scale_x_continuous(limits = c(0,1)) +
     theme_minimal() +
     theme(plot.title = element_text(size = 13, face = "bold"),
           plot.subtitle = element_text(size = 13, face='bold', hjust = 0.5),
           axis.title.x = element_text(size = 12, margin = margin(t = 20)),
           axis.title.y = element_text(size = 12, margin = margin(r = 20)),
           axis.text = element_text(size = 10),
           strip.text = element_text(size = 12),
           legend.position = "none",
           panel.grid.minor = element_blank())



tmp <- wash_data_long[wash_data_long$means == 1,]
tmp$WASH_Variable <- gsub("_", " ", tmp$WASH_Variable)
tmp$WASH_Variable <- factor(tmp$WASH_Variable,
                            levels=c("Weighted Mean WASH", "Mean WASH"))

p3 <-
     ggplot(tmp, aes(x = Value, y = Incidence_per_1000)) +
     geom_point(color = "black", size = 2, alpha=0.6) +
     geom_smooth(color = "#9b59b6", method = "lm", se = FALSE, size = 1) +
     facet_wrap(~ WASH_Variable, scales = "free_x") +
     geom_text(aes(label = correlation_label), x = Inf, y = Inf, hjust = 1.75, vjust = 2, size = 3.5, color = "black") +
     labs(title = "C",
          subtitle = "Mean WASH variables",
          x = "WASH variable value",
          y = "Incidence per 1,000") +
     scale_x_continuous(limits = c(0,1)) +
     theme_minimal() +
     theme(plot.title = element_text(size = 13, face='bold'),
           plot.subtitle = element_text(size = 13, face='bold', hjust = 0.5),
           axis.title.x = element_text(size = 12, margin = margin(t = 20)),
           axis.title.y = element_text(size = 12, margin = margin(r = 20)),
           axis.text = element_text(size = 10),
           strip.text = element_text(size = 12),
           legend.position = "none",
           panel.grid.minor = element_blank())


combo <- cowplot::plot_grid(p1, p2, p3, ncol=1, rel_heights = c(1,1,0.7), align = "vh", axis='tb')
combo



png(filename = "./figures/wash_incidence_correlation.png", height = 3200, width = 2000, units = "px", res=300)
combo
dev.off()



################################################################################
# Plot values of optimized weighted mean WASH index by country
# There are the values used in the model as theta_j
################################################################################

p4 <-
ggplot(wash_data, aes(x = reorder(Country, -Weighted_Mean_WASH), y = Weighted_Mean_WASH)) +
     geom_bar(stat = "identity", fill = "steelblue") +
     geom_hline(yintercept = 0) +
     labs(x = NULL, y = "Optimized Weighted Mean\nof WASH Variables (θ)") +  # Wrap the y-axis title and add (θ)
     scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
     theme_minimal() +
     theme(
          plot.title = element_text(size = 16, face = "bold"),
          axis.ticks.x = element_line(size = 0.5),
          axis.ticks.y = element_line(size = 0.5),
          axis.text = element_text(size = 12),
          axis.text.x = element_text(angle = 45, hjust = 1),
          axis.title.y = element_text(size = 14, margin = margin(r = 20), lineheight = 1.2),  # Lineheight for wrapping
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank()
     )





png(filename = "./figures/wash_index_by_country.png", height = 1750, width = 2750, units = "px", res=300)
p4
dev.off()





weights_table <- data.frame(
     WASH_variable = wash_variables,
     Optimized_weight = round(best_weights, 3)
)

weights_table$WASH_variable <- gsub("_", " ", weights_table$WASH_variable)

weights_table <- weights_table[c(1,3,2,4,6,7,5,8),]
print(weights_table)

write.csv(weights_table, file=file.path(getwd(), "figures/wash_table.csv"), row.names = FALSE)


################################################################################
################################################################################
################################################################################

# Confidence intervals


# Function to calculate the correlation and its 95% CI using bootstrapping
bootstrap_correlation <- function(data, wash_var, n_bootstrap = 1000) {
     correlations <- replicate(n_bootstrap, {
          sample_indices <- sample(1:nrow(data), replace = TRUE)
          sampled_data <- data[sample_indices, ]
          cor(sampled_data[[wash_var]], sampled_data$Incidence_per_1000, use = "complete.obs")
     })

     # Calculate mean and 95% CI
     mean_cor <- mean(correlations)
     ci_lower <- quantile(correlations, 0.025)
     ci_upper <- quantile(correlations, 0.975)

     return(c(mean = mean_cor, ci_lower = ci_lower, ci_upper = ci_upper))
}


# Calculate mean and 95% CI for each WASH variable's correlation coefficient
correlation_results <- sapply(unique(as.character(wash_data_long$WASH_Variable)), function(var) {
     bootstrap_correlation(wash_data, var)
})

# Convert results to a data frame
correlation_results_df <- data.frame(
     WASH_Variable = as.character(wash_data_long$WASH_Variable),
     Mean_Correlation = correlation_results["mean", ],
     CI_Lower = correlation_results["ci_lower.2.5%", ],
     CI_Upper = correlation_results["ci_upper.97.5%", ]
)

# Print the correlation results with CIs
print(correlation_results_df)
