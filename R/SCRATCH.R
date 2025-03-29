pal <- c("#1abc9c", "#16a085", "#2ecc71", "#27ae60", "#3498db",
         "#2980b9", "#9b59b6", "#8e44ad", "#34495e", "#2c3e50",
         "#f1c40f", "#f39c12", "#e67e22", "#d35400", "#e74c3c",
         "#c0392b", "#ecf0f1", "#bdc3c7", "#95a5a6", "#7f8c8d")




################################################################################



library(ggplot2)
library(rnaturalearth)
library(sf)
library(dplyr)
library(stringr)


cholera_outbreak_countries_10yrs <- c(
     "Nigeria", "Democratic Republic of the Congo", "Somalia", "Kenya",
     "Ethiopia", "Mozambique", "Zambia", "South Sudan", "Malawi",
     "Uganda", "Zimbabwe", "Tanzania", "Cameroon", "Niger", "Burundi",
     "Angola", "Chad", "Ghana", "Sierra Leone", "Sudan", "Madagascar"
)

cholera_outbreak_countries_5yrs <- c(
     "Nigeria", "Democratic Republic of the Congo", "Somalia", "Kenya",
     "Ethiopia", "Mozambique", "Zambia", "South Sudan", "Malawi",
     "Uganda", "Zimbabwe", "Tanzania", "Cameroon", "Niger", "Burundi"
)



africa <- ne_countries(scale = "medium", continent = "Africa", returnclass = "sf")
SSA <- africa[africa$region_wb == "Sub-Saharan Africa",]
SSA_outbreak_5yr <- africa[africa$name_long %in% cholera_outbreak_countries_5yrs,]
SSA_outbreak_10yr <- africa[africa$name_long %in% cholera_outbreak_countries_10yrs,]

ggplot(data = africa) +
     geom_sf(fill = "white", color = "black") +
     geom_sf(data = SSA, aes(fill = "SSA"), color = "black") +
     geom_sf(data = SSA_outbreak_10yr, aes(fill = "SSA_outbreak_10yr"), color = "black", linetype = "solid", size = 0.8) +
     geom_sf(data = SSA_outbreak_5yr, aes(fill = "SSA_outbreak_5yr"), color = "black", linetype = "solid", size = 0.8) +
     scale_fill_manual(values = c("#ffd380", "#bc5090", "#003f5c"),
                       labels = c( "SSA countries",
                                   str_wrap("Cholera outbreak in past 10 years", 18),
                                   str_wrap("Cholera outbreak in past 5 years", 18))) +
     theme_minimal(base_size = 14) +
     theme(
          legend.position = "right",
          legend.title = element_blank(),
          legend.text = element_text(size = 10),
          legend.key.size = unit(1.25, "cm"),              # Increase the size of the legend keys
          legend.spacing.y = unit(1, "cm"),             # Add vertical space between keys
          legend.key = element_rect(color = NA)
     )




################################################################################


library(propvacc)
library(ggplot2)
library(cowplot)
library(grid)
library(stringr)
library(latex2exp)

prm_all <- get_beta_params(quantiles = c(0.0275, 0.5, 0.975),
                           probs = c(0.24, 0.52, 0.8))

samps <- rbeta(5000, shape1 = prm$shape1, shape2 = prm$shape2)
ci <- quantile(samps, probs = c(0.025, 0.5, 0.975))


df_samples <- data.frame(x = samps)

x_vals <- seq(0, 1, length.out = 5000)
y_vals <- dbeta(x_vals, prm$shape1, prm$shape2)
df_beta <- data.frame(x = x_vals, y = y_vals)

txt <- "Low estimate for \u03B8: All settings"

p1 <-
     ggplot(df_samples, aes(x = x)) +
     geom_histogram(aes(y = ..density..), bins = 50, fill = "#3498db", color='white', alpha = 0.5) +
     geom_line(data = df_beta, aes(x = x, y = y), color = "black", size = 1) +  # Plot Beta distribution
     geom_vline(xintercept = ci[c(1,3)], linetype = "dashed", color = "grey20", size = 0.25) +
     geom_vline(xintercept = ci[2], linetype = "solid", color = "grey20", size = 0.5) +
     labs(title="A", y = "Density", x = "") +
     scale_x_continuous(limits = c(0, 1.25), breaks=seq(0, 1, 0.25), expand=c(0,0)) +
     scale_y_continuous(expand=c(0.005, 0.005)) +
     theme_minimal(base_size = 14) +
     theme(
          legend.position = "none",
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color='grey80', size=0.25),
          panel.grid.minor = element_blank(),
          axis.title.x = element_text(margin = margin(t = 25)),
          axis.title.y = element_text(margin = margin(r = 25)),
          plot.margin = unit(c(0.25, 0.25, 0, 0), "inches")
     ) +
     annotation_custom(
          grob = textGrob(str_wrap(txt, 20), gp = gpar(col = "#3498db", fontsize = 11)),
          xmin = 1.125, xmax = 1.125, ymin = 1.5, ymax = 1.5
     )


prm_stratum_high_outbreak <- get_beta_params(quantiles = c(0.0275, 0.5, 0.975),
                                             probs = c(0.40, 0.78, 0.99))

samps <- rbeta(5000, shape1 = prm_stratum_high_outbreak$shape1, shape2 = prm_stratum_high_outbreak$shape2)
ci <- quantile(samps, probs = c(0.025, 0.5, 0.975))


df_samples <- data.frame(x = samps)

x_vals <- seq(0, 1, length.out = 5000)
y_vals <- dbeta(x_vals, prm_stratum_high_outbreak$shape1, prm_stratum_high_outbreak$shape2)
df_beta <- data.frame(x = x_vals, y = y_vals)

txt <- "High estimate for \u03B8: During outbreaks\n\u03B8
\u223C Beta(4.79, 1.53)"

p2 <-
     ggplot(df_samples, aes(x = x)) +
     geom_histogram(aes(y = ..density..), bins = 50, fill = "#c0392b", color='white', alpha = 0.5) +
     geom_line(data = df_beta, aes(x = x, y = y), color = "black", size = 1) +  # Plot Beta distribution
     geom_vline(xintercept = ci[c(1,3)], linetype = "dashed", color = "grey20", size = 0.25) +
     geom_vline(xintercept = ci[2], linetype = "solid", color = "grey20", size = 0.5) +
     labs(title="B", y = "Density", x = expression("Proportion of suspected cases that are true infections (" * theta * ")")) +
     scale_x_continuous(limits = c(0, 1.25), breaks=seq(0, 1, 0.25), expand=c(0,0)) +
     scale_y_continuous(expand=c(0.005, 0.005)) +
     theme_minimal(base_size = 14) +
     theme(
          legend.position = "none",
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color='grey80', size=0.25),
          panel.grid.minor = element_blank(),
          axis.title.x = element_text(margin = margin(t = 25)),
          axis.title.y = element_text(margin = margin(r = 25)),
          plot.margin = unit(c(0, 0.25, 0.25, 0), "inches")
     ) +
     annotation_custom(
          grob = textGrob(str_wrap(txt, 20), gp = gpar(col = "#c0392b", fontsize = 11)),
          xmin = 1.125, xmax = 1.125, ymin = 1.5, ymax = 1.5
     )

plot_grid(p1, p2, ncol = 1, align = 'vh')





################################################################################





df <- data.frame(
     WHO_Region = c("African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "African Region", "Eastern Mediterranean Region", "Eastern Mediterranean Region", "Eastern Mediterranean Region", "Eastern Mediterranean Region", "Eastern Mediterranean Region", "Eastern Mediterranean Region", "European Region", "Region of the Americas", "South-East Asia Region", "South-East Asia Region", "South-East Asia Region", "South-East Asia Region"),
     Country = c("Burundi", "Cameroon", "Comoros", "Democratic Republic of the Congo", "Ethiopia", "Kenya", "Malawi", "Mozambique", "Nigeria", "South Africa", "Uganda", "United Republic of Tanzania", "Zambia", "Zimbabwe", "Afghanistan", "Pakistan", "Somalia", "Sudan", "Syrian Arab Republic", "Yemen", "Mayotte", "Haiti", "Bangladesh", "India", "Myanmar", "Nepal"),
     Cases_2024 = c(716, 49, 10338, 20771, 21254, 392, 252, 8132, 5300, 11, 89, 3721, 20219, 20036, 95301, 38636, 17246, 2410, 10420, 24308, 220, 2672, 86, 3805, 1141, 20),
     Deaths_2024 = c(3, 0, 149, 314, 182, 3, 1, 18, 165, 0, 5, 63, 637, 399, 301, 0, 137, 78, 0, 140, 2, 13, 0, 8, 1, 0),
     Cases_per_100000 = c(6, 0, 1258, 17, 29, 1, 1, 28, 2, 0, 0, 6, 103, 132, 291, 16, 105, 6, 47, 72, 69, 23, 10, 0, 0, 0),
     CFR_percentage_2024 = c(0.4, 0, 1.4, 1.5, 0.9, 0.8, 0.4, 0.2, 3.1, 0, 5.6, 1.7, 3.2, 2, 0.1, 0, 0.8, 3.2, 0, 0.6, 0.9, 0.5, 0, 0.2, 0.1, 0),
     Last_28_days_cases = c(96, 0, 196, 1246, 2086, 0, 0, 53, 3198, 0, 0, 366, 0, 0, 24951, 7932, 1490, 41, 165, 8929, 10, 0, 62, 0, 1141, 20),
     Last_28_days_deaths = c(0, 0, 2, 4, 43, 0, 0, 0, 102, 0, 5, 11, 0, 0, 10, 0, 5, 15, 0, 30, 0, 0, 0, 0, 1, 0),
     Last_28_days_CFR_percentage = c(0, 0, 1, 0.3, 2.1, 0, 0, 0, 3.2, 0, 0, 3, 0, 0, 0, 0, 0.3, 36.6, 0, 0.3, 0, 0, 0, 0, 0.1, 0),
     Monthly_cases_change_percentage = c(-2, 0, -92, -32, 26, 0, 0, -75, 192, 0, 0, 36, 0, 0, 34, -19, -23, 42, 42, 35, -88, 0, 313, 0, 0, 0),
     Monthly_deaths_change_percentage = c(0, 0, -91, -43, 258, 0, 0, 0, 149, 0, 0, 175, 0, 0, -17, 0, -50, 36.6, 0, -42, 0, 0, 0, 0, 0, 0)
)

# Display the data frame
print(df)





################################################################################

library(ggplot2)
library(minpack.lm)
library(dplyr)

d <- read.csv(file.path(getwd(), "data/cholera_country_weekly_processed.csv"), stringsAsFactors = FALSE)

# Plot cases by week for each country
ggplot(d, aes(x = week, y = cases, color = country)) +
     geom_point() +
     labs(title = "Cholera Cases by Week for Each Country",
          x = "Week",
          y = "Number of Cases",
          color = "Country") +
     theme_minimal() +
     theme(axis.text.x = element_text(angle = 45, hjust = 1),
           legend.position = "right") +
     facet_wrap(~ country, scales = "free_y")  # Facet by country



d_somalia <- d[d$country == 'Somalia',]


# Define the model function
model_func <- function(params, t) {
     beta0 <- params[1]
     a <- params[2]
     p <- params[3]
     x <- params[4]

     beta0 * (1 - a * cos((pi * t / p) - x))
}

# Define initial parameter guesses
start_params <- c(beta0 = mean(d_somalia$cases, na.rm = TRUE),
                  a = 0.5,
                  p = 52,  # Assuming weekly data with a yearly cycle
                  x = 0)

# Perform the fitting using nlsLM from minpack.lm
fit <- nlsLM(cases ~ model_func(c(beta0, a, p, x), week),
             data = d_somalia,
             start = start_params,
             control = nls.lm.control(maxiter = 1000))




# Define the function to fit the model to one country's data
fit_weekly_cases_single_country <- function(country_data) {

     # Define the model function
     model_func <- function(t, beta0, a, p, x) {
          beta0 * (1 - a * cos((pi * t / p) - x))
     }

     # Define initial parameter guesses
     start_params <- list(beta0 = max(country_data$cases, na.rm = TRUE),
                          a = 0.5,
                          p = 52,  # Assuming weekly data with a yearly cycle
                          x = 0)

     # Perform the fitting using nlsLM from minpack.lm
     fit <- nlsLM(cases ~ model_func(week, beta0, a, p, x),
                  data = country_data,
                  start = start_params,
                  control = nls.lm.control(maxiter = 1000))

     return(fit)
}

# Example usage with a single country's data
# Assuming 'cholera_data' has columns: country, week, cases

# Filter data for a specific country, e.g., "CountryName"
country_name <- "Somalia"  # Replace with the actual country name
country_data <- d[d$country == country_name,]

# Fit the model to this country's data
fit <- fit_weekly_cases_single_country(country_data)

# Get the fitted values
country_data$fitted_cases <- predict(fit)

# Plot the observed data and the fitted curve
ggplot(country_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1) +  # Fitted curve
     labs(title = paste("Fit of Model to Weekly Cholera Cases in", country_name),
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12))











library(ggplot2)
library(minpack.lm)

# The function you provided to fit the model to one country's data
fit_weekly_cases_single_country <- function(country_data) {

     # Define the model function
     model_func <- function(t, beta0, a, p, x) {
          beta0 * (1 - a * cos((pi * t / p) - x))
     }

     # Define initial parameter guesses
     start_params <- list(beta0 = max(country_data$cases, na.rm = TRUE),
                          a = 0.5,
                          p = 52,  # Assuming weekly data with a yearly cycle
                          x = 0)

     # Perform the fitting using nlsLM from minpack.lm
     fit <- nlsLM(cases ~ model_func(week, beta0, a, p, x),
                  data = country_data,
                  start = start_params,
                  control = nls.lm.control(maxiter = 1000))

     return(fit)
}

# Assuming 'd' is your data frame with columns: country, week, cases
# Get the list of unique countries
countries <- unique(d$country)

# Initialize an empty list to store the results
fitted_data_list <- list()

# Loop over each country
for (country in countries) {
     # Filter data for the current country
     country_data <- d[d$country == country, ]

     # Fit the model to the current country's data
     fit <- fit_weekly_cases_single_country(country_data)

     # Generate a sequence of 1:52 weeks for prediction
     prediction_weeks <- data.frame(week = 1:52)

     # Predict onto the 1:52 week series
     prediction_weeks$fitted_cases <- predict(fit, newdata = prediction_weeks)
     prediction_weeks$country <- country

     # Combine the fitted values with the original data
     combined_data <- merge(country_data, prediction_weeks, by = c("week", "country"), all.y = TRUE)

     # Store the results in the list
     fitted_data_list[[country]] <- combined_data
}

# Combine all the fitted data into one data frame
fitted_data <- do.call(rbind, fitted_data_list)

# Plot the observed data and the fitted curve for all countries
ggplot(fitted_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1) +  # Fitted curve
     labs(title = "Fit of Model to Weekly Cholera Cases by Country",
          x = "Week of the Year",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12)) +
     facet_wrap(~ country, scales = "free_y")  # Facet by country









library(ggplot2)
library(minpack.lm)

# Define the simple cosine wave function model
fit_weekly_cases_single_country <- function(country_data) {

     # Define the model function
     model_func <- function(t, beta0, a, p, x) {
          beta0 * (1 + a * cos(2 * pi * t / p + x))
     }

     # Define initial parameter guesses
     start_params <- list(beta0 = mean(country_data$cases, na.rm = TRUE),  # Use mean of cases
                          a = 0.5,  # Initial amplitude for cosine wave
                          p = 52,   # Assuming weekly data with a yearly cycle
                          x = 0)    # Initial phase shift for cosine wave

     # Perform the fitting using nlsLM from minpack.lm with error handling
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, a, p, x),
                data = country_data,
                start = start_params,
                control = nls.lm.control(maxiter = 1000))
     }, error = function(e) {
          print(paste("Fitting failed for", unique(country_data$country), "with error:", e$message))
          return(NULL)  # Return NULL if fitting fails
     })

     return(fit)
}

# Assuming 'd' is your data frame with columns: country, week, cases
# Get the list of unique countries
countries <- unique(d$country)

# Initialize an empty list to store the results
fitted_data_list <- list()

# Loop over each country
for (country in countries) {
     # Filter data for the current country
     country_data <- d[d$country == country, ]

     # Fit the model to the current country's data
     fit <- fit_weekly_cases_single_country(country_data)

     # Only proceed if the fit was successful
     if (!is.null(fit)) {
          # Predict onto the original time series of weeks
          country_data$fitted_cases <- predict(fit, newdata = country_data)
          # Store the results in the list
          fitted_data_list[[country]] <- country_data
     } else {
          # If fitting fails, just store the original data without fitted values
          country_data$fitted_cases <- NA
          fitted_data_list[[country]] <- country_data
     }
}

# Combine all the fitted data into one data frame
fitted_data <- do.call(rbind, fitted_data_list)

# Plot the observed data and the fitted curve for all countries
ggplot(fitted_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Fit of Simple Cosine Wave Model to Weekly Cholera Cases by Country",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12)) +
     facet_wrap(~ country, scales = "free_y")  # Facet by country







###############



# Assuming 'd' is your data frame with columns: country, week, cases
# Filter data for Burundi
burundi_data <- d[d$country == "Tanzania", ]



fit_simple_cosine <- function(data) {
     model_func <- function(t, beta0, a, p, x) {
          beta0 * (1 + a * cos(2 * pi * t / p + x))
     }
     start_params <- list(beta0 = mean(data$cases, na.rm = TRUE),
                          a = 0.5, p = 52, x = 0)
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, a, p, x),
                data = data,
                start = start_params)
     }, error = function(e) NULL)
     return(fit)
}



fit_double_cosine <- function(data) {
     model_func <- function(t, beta0, a1, p1, x1, a2, p2, x2) {
          beta0 * (1 + a1 * cos(2 * pi * t / p1 + x1) + a2 * cos(4 * pi * t / p2 + x2))
     }
     start_params <- list(beta0 = mean(data$cases, na.rm = TRUE),
                          a1 = 0.3, p1 = 52, x1 = 0,
                          a2 = 0.2, p2 = 26, x2 = 0)
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, a1, p1, x1, a2, p2, x2),
                data = data,
                start = start_params)
     }, error = function(e) NULL)
     return(fit)
}



fit_sine_cosine <- function(data) {
     model_func <- function(t, beta0, a, p, x, b, y) {
          beta0 * (1 + a * cos(2 * pi * t / p + x) + b * sin(2 * pi * t / p + y))
     }
     start_params <- list(beta0 = mean(data$cases, na.rm = TRUE),
                          a = 0.5, p = 52, x = 0,
                          b = 0.5, y = 0)
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, a, p, x, b, y),
                data = data,
                start = start_params)
     }, error = function(e) NULL)
     return(fit)
}



fit_fourier <- function(data) {
     model_func <- function(t, beta0, a1, b1, p) {
          beta0 + a1 * cos(2 * pi * t / p) + b1 * sin(2 * pi * t / p)
     }
     start_params <- list(beta0 = mean(data$cases, na.rm = TRUE),
                          a1 = 0.5, b1 = 0.5, p = 52)
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, a1, b1, p),
                data = data,
                start = start_params)
     }, error = function(e) NULL)
     return(fit)
}




fit_double_logistic <- function(data) {
     model_func <- function(t, beta0, t1, sigma1, t2, sigma2) {
          beta0 / (1 + exp(-(t - t1) / sigma1)) - beta0 / (1 + exp(-(t - t2) / sigma2))
     }
     start_params <- list(beta0 = mean(data$cases, na.rm = TRUE),
                          t1 = 15, sigma1 = 5, t2 = 35, sigma2 = 5)
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, t1, sigma1, t2, sigma2),
                data = data,
                start = start_params)
     }, error = function(e) NULL)
     return(fit)
}



fits <- list(
     "Simple Cosine" = fit_simple_cosine(burundi_data),
     "Double Cosine" = fit_double_cosine(burundi_data),
     "Sine-Cosine Combined" = fit_sine_cosine(burundi_data),
     "Fourier Series" = fit_fourier(burundi_data),
     "Double Logistic" = fit_double_logistic(burundi_data)
)




# Predict and store results in the data frame
predictions <- lapply(fits, function(fit) {
     if (!is.null(fit)) {
          return(predict(fit, newdata = burundi_data))
     } else {
          return(rep(NA, nrow(burundi_data)))
     }
})

# Combine predictions into a data frame
predictions_df <- as.data.frame(predictions)
predictions_df$week <- burundi_data$week
predictions_df$cases <- burundi_data$cases

# Reshape for plotting
library(reshape2)
predictions_melt <- melt(predictions_df, id.vars = c("week", "cases"))

# Plot the observed data and the fitted values from all models
ggplot(predictions_melt, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = value, color = variable), size = 1) +  # Fitted curves
     labs(title = "Comparison of Models for Weekly Cholera Cases in Burundi",
          x = "Week",
          y = "Number of Cases",
          color = "Model") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12))




################################################



fit_fourier <- function(data) {
     model_func <- function(t, beta0, a1, b1, p) {
          beta0 + a1 * cos(2 * pi * t / p) + b1 * sin(2 * pi * t / p)
     }
     start_params <- list(beta0 = mean(data$cases, na.rm = TRUE),
                          a1 = 0.5, b1 = 0.5, p = 52)
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, a1, b1, p),
                data = data,
                start = start_params)
     }, error = function(e) NULL)
     return(fit)
}




# Assuming 'd' is your data frame with columns: country, week, cases
# Get the list of unique countries
countries <- unique(d$country)

# Initialize an empty list to store the results
fitted_data_list <- list()

# Loop over each country
for (country in countries) {
     # Filter data for the current country
     country_data <- d[d$country == country, ]

     # Fit the Fourier Series model to the current country's data
     fit <- fit_fourier(country_data)

     # Only proceed if the fit was successful
     if (!is.null(fit)) {
          # Predict onto the original time series of weeks
          country_data$fitted_cases <- predict(fit, newdata = country_data)
          # Store the results in the list
          fitted_data_list[[country]] <- country_data
     } else {
          # If fitting fails, just store the original data without fitted values
          country_data$fitted_cases <- NA
          fitted_data_list[[country]] <- country_data
     }
}

# Combine all the fitted data into one data frame
fitted_data <- do.call(rbind, fitted_data_list)




# Plot the observed data and the fitted curve for all countries
ggplot(fitted_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Fourier Series Model Fit to Weekly Cholera Cases by Country",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12)) +
     facet_wrap(~ country, scales = "free_y")  # Facet by country










#####################



library(ggplot2)
library(minpack.lm)

# Define the generalized Fourier series model
fit_generalized_fourier <- function(data) {
     model_func <- function(t, beta0, a1, b1, a2, b2, p) {
          beta0 + a1 * cos(2 * pi * t / p) + b1 * sin(2 * pi * t / p) +
               a2 * cos(4 * pi * t / p) + b2 * sin(4 * pi * t / p)
     }
     start_params <- list(beta0 = mean(data$cases, na.rm = TRUE),
                          a1 = 0.5, b1 = 0.5,  # First harmonic
                          a2 = 0.3, b2 = 0.3,  # Second harmonic
                          p = 52)
     fit <- tryCatch({
          nlsLM(cases ~ model_func(week, beta0, a1, b1, a2, b2, p),
                data = data,
                start = start_params)
     }, error = function(e) NULL)
     return(fit)
}




# Apply the model to Burundi
burundi_data <- d[d$country == "Burundi", ]
fit_burundi <- fit_generalized_fourier(burundi_data)
burundi_data$fitted_cases <- predict(fit_burundi, newdata = burundi_data)

# Apply the model to Tanzania
tanzania_data <- d[d$country == "Tanzania", ]
fit_tanzania <- fit_generalized_fourier(tanzania_data)
tanzania_data$fitted_cases <- predict(fit_tanzania, newdata = tanzania_data)





# Combine data for plotting
combined_data <- rbind(burundi_data, tanzania_data)

# Plot the observed data and the fitted curve for both countries
ggplot(combined_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Generalized Fourier Series Model Fit to Weekly Cholera Cases",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12)) +
     facet_wrap(~ country, scales = "free_y")  # Facet by country








#################






library(ggplot2)

# Define the generalized Fourier series model function
model_func <- function(params, t) {
     beta0 <- params[1]
     a1 <- params[2]
     b1 <- params[3]
     a2 <- params[4]
     b2 <- params[5]
     p <- params[6]
     beta0 + a1 * cos(2 * pi * t / p) + b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) + b2 * sin(4 * pi * t / p)
}

# Define the objective function to minimize (sum of squared errors)
objective_func <- function(params, t, cases) {
     sum((cases - model_func(params, t))^2)
}

# Fit the model using optim
fit_generalized_fourier_optim <- function(data) {
     start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                       a1 = 0.5, b1 = 0.5,  # First harmonic
                       a2 = 0.3, b2 = 0.3,  # Second harmonic
                       p = 52)

     fit <- tryCatch({
          optim(par = start_params,
                fn = objective_func,
                t = data$week,
                cases = data$cases,
                method = "L-BFGS-B",
                lower = c(-Inf, -Inf, -Inf, -Inf, -Inf, 50),  # Period should be close to 52
                upper = c(Inf, Inf, Inf, Inf, Inf, 54))
     }, error = function(e) NULL)

     return(fit)
}





# Apply the model to Burundi
fit_burundi <- fit_generalized_fourier_optim(burundi_data)
burundi_data$fitted_cases <- model_func(fit_burundi$par, burundi_data$week)

# Apply the model to Tanzania
fit_tanzania <- fit_generalized_fourier_optim(tanzania_data)
tanzania_data$fitted_cases <- model_func(fit_tanzania$par, tanzania_data$week)



# Combine data for plotting
combined_data <- rbind(burundi_data, tanzania_data)

# Plot the observed data and the fitted curve for both countries
ggplot(combined_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Optimized Generalized Fourier Series Model Fit to Weekly Cholera Cases",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12)) +
     facet_wrap(~ country, scales = "free_y")  # Facet by country








###################





library(ggplot2)

# Define the generalized Fourier series model function
model_func <- function(params, t) {
     beta0 <- params[1]
     a1 <- params[2]
     b1 <- params[3]
     a2 <- params[4]
     b2 <- params[5]
     p <- params[6]
     beta0 + a1 * cos(2 * pi * t / p) + b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) + b2 * sin(4 * pi * t / p)
}

# Define the objective function to minimize (sum of squared errors)
objective_func <- function(params, t, cases) {
     sum((cases - model_func(params, t))^2)
}

# Fit the model using optim
fit_generalized_fourier_optim <- function(data) {
     start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                       a1 = 0.5, b1 = 0.5,  # First harmonic
                       a2 = 0.3, b2 = 0.3,  # Second harmonic
                       p = 52)

     fit <- tryCatch({
          optim(par = start_params,
                fn = objective_func,
                t = data$week,
                cases = data$cases,
                method = "L-BFGS-B",
                lower = c(-Inf, -Inf, -Inf, -Inf, -Inf, 50),  # Period should be close to 52
                upper = c(Inf, Inf, Inf, Inf, Inf, 54))
     }, error = function(e) NULL)

     return(fit)
}





# Assuming 'd' is your data frame with columns: country, week, cases
# Get the list of unique countries
countries <- unique(d$country)

# Initialize an empty list to store the results
fitted_data_list <- list()

# Loop over each country
for (country in countries) {
     # Filter data for the current country
     country_data <- d[d$country == country, ]

     # Fit the Fourier Series model to the current country's data
     fit <- fit_generalized_fourier_optim(country_data)

     # Only proceed if the fit was successful
     if (!is.null(fit)) {
          # Predict onto the original time series of weeks
          country_data$fitted_cases <- model_func(fit$par, country_data$week)
          # Store the results in the list
          fitted_data_list[[country]] <- country_data
     } else {
          # If fitting fails, just store the original data without fitted values
          country_data$fitted_cases <- NA
          fitted_data_list[[country]] <- country_data
     }
}

# Combine all the fitted data into one data frame
fitted_data <- do.call(rbind, fitted_data_list)






# Plot the observed data and the fitted curve for all countries
ggplot(fitted_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Optimized Generalized Fourier Series Model Fit to Weekly Cholera Cases by Country",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12)) +
     facet_wrap(~ country, scales = "free_y")  # Facet by country




##############

library(ggplot2)

# Define the generalized Fourier series model function
model_func <- function(params, t) {
     beta0 <- params[1]
     a1 <- params[2]
     b1 <- params[3]
     a2 <- params[4]
     b2 <- params[5]
     p <- params[6]
     beta0 + a1 * cos(2 * pi * t / p) + b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) + b2 * sin(4 * pi * t / p)
}

# Define the objective function to minimize (sum of squared errors)
objective_func <- function(params, t, cases) {
     sum((cases - model_func(params, t))^2)
}

# Fit the model using optim with refined initial guesses and optimization settings
fit_generalized_fourier_optim <- function(data) {
     # Refine initial parameter guesses
     start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                       a1 = 0.5 * sd(data$cases, na.rm = TRUE),
                       b1 = 0.5 * sd(data$cases, na.rm = TRUE),
                       a2 = 0.3 * sd(data$cases, na.rm = TRUE),
                       b2 = 0.3 * sd(data$cases, na.rm = TRUE),
                       p = 52)

     # Fit the model using optim
     fit <- tryCatch({
          optim(par = start_params,
                fn = objective_func,
                t = data$week,
                cases = data$cases,
                method = "L-BFGS-B",
                lower = c(-Inf, -Inf, -Inf, -Inf, -Inf, 50),  # Period should be close to 52
                upper = c(Inf, Inf, Inf, Inf, Inf, 54),
                control = list(maxit = 1000))  # Increase max iterations
     }, error = function(e) NULL)

     return(fit)
}

# Assuming 'd' is your data frame with columns: country, week, cases
# Get the list of unique countries
countries <- unique(d$country)

# Initialize an empty list to store the results
fitted_data_list <- list()

# Loop over each country
for (country in countries) {
     # Filter data for the current country
     country_data <- d[d$country == country, ]

     # Fit the Fourier Series model to the current country's data
     fit <- fit_generalized_fourier_optim(country_data)

     # Only proceed if the fit was successful
     if (!is.null(fit)) {
          # Predict onto the original time series of weeks
          country_data$fitted_cases <- model_func(fit$par, country_data$week)
          # Store the results in the list
          fitted_data_list[[country]] <- country_data
     } else {
          # If fitting fails, just store the original data without fitted values
          country_data$fitted_cases <- NA
          fitted_data_list[[country]] <- country_data
     }
}

# Combine all the fitted data into one data frame
fitted_data <- do.call(rbind, fitted_data_list)

# Plot the observed data and the fitted curve for all countries
ggplot(fitted_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Refined Generalized Fourier Series Model Fit to Weekly Cholera Cases by Country",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12)) +
     facet_wrap(~ country, scales = "free_y")  # Facet by country



###########################
###########################
###########################
###########################
###########################
###########################



library(ggplot2)
library(dplyr)

# Define the generalized Fourier series model function
model_func <- function(params, t) {
     beta0 <- params[1]
     a1 <- params[2]
     b1 <- params[3]
     a2 <- params[4]
     b2 <- params[5]
     p <- params[6]
     beta0 + a1 * cos(2 * pi * t / p) + b1 * sin(2 * pi * t / p) +
          a2 * cos(4 * pi * t / p) + b2 * sin(4 * pi * t / p)
}

# Define the objective function to minimize (sum of squared errors)
objective_func <- function(params, t, cases) {
     sum((cases - model_func(params, t))^2)
}

# Fit the model using optim with refined initial guesses and optimization settings
fit_generalized_fourier_optim <- function(data) {
     # Refine initial parameter guesses
     start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                       a1 = 0.5 * sd(data$cases, na.rm = TRUE),
                       b1 = 0.5 * sd(data$cases, na.rm = TRUE),
                       a2 = 0.3 * sd(data$cases, na.rm = TRUE),
                       b2 = 0.3 * sd(data$cases, na.rm = TRUE),
                       p = 52)

     # Fit the model using optim
     fit <- tryCatch({
          optim(par = start_params,
                fn = objective_func,
                t = data$week,
                cases = data$cases,
                method = "L-BFGS-B",
                lower = c(-Inf, -Inf, -Inf, -Inf, -Inf, 50),  # Period should be close to 52
                upper = c(Inf, Inf, Inf, Inf, Inf, 54),
                control = list(maxit = 20000))  # Increase max iterations for better convergence
     }, error = function(e) NULL)

     return(fit)
}








################################






# Filter data for Nigeria
nigeria_data <- d[d$country == "Nigeria", ]

# Summary statistics for Nigeria's data
summary(nigeria_data)

# Plot the raw data to visually inspect the seasonal pattern
ggplot(nigeria_data, aes(x = week, y = cases)) +
     geom_point(color = "blue", size = 2) +
     labs(title = "Weekly Cholera Cases in Nigeria",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12))





fit_generalized_fourier_optim_nigeria <- function(data) {
    # Adjust initial parameter guesses specifically for Nigeria
    start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                      a1 = 0.2 * sd(data$cases, na.rm = TRUE),
                      b1 = 0.2 * sd(data$cases, na.rm = TRUE),
                      a2 = 0.1 * sd(data$cases, na.rm = TRUE),
                      b2 = 0.1 * sd(data$cases, na.rm = TRUE),
                      p = 52)

    # Fit the model using optim with L-BFGS-B method
    fit <- tryCatch({
        optim(par = start_params,
              fn = objective_func,
              t = data$week,
              cases = data$cases,
              method = "L-BFGS-B",
              lower = c(-Inf, -Inf, -Inf, -Inf, -Inf, 50),  # Constrain period close to 52
              upper = c(Inf, Inf, Inf, Inf, Inf, 54),
              control = list(maxit = 2000))  # Increase max iterations for better convergence
    }, error = function(e) NULL)

    return(fit)
}



# Assuming 'd' is your data frame with columns: country, week, cases
countries <- unique(d$country)

# Initialize an empty list to store predictions
fitted_data_list <- list()

# Define the prediction weeks (Jan 2023 to Dec 2024, 104 weeks)
prediction_weeks <- data.frame(week = 1:104)

# Loop over each country and apply the model
for (country in countries) {
     country_data <- d[d$country == country, ]

     # Fit the model to the historical data
     fit <- fit_generalized_fourier_optim(country_data)

     if (!is.null(fit)) {
          # Predict onto the future time series (Jan 2023 to Dec 2024)
          prediction_weeks$fitted_cases <- model_func(fit$par, prediction_weeks$week)
          prediction_weeks$country <- country
          fitted_data_list[[country]] <- prediction_weeks
     } else {
          print(paste("Model fitting failed for", country))
     }
}

# Combine all fitted predictions into one data frame
fitted_data <- do.call(rbind, fitted_data_list)




# Plot the predictions for all countries
ggplot(fitted_data, aes(x = week, y = fitted_cases, color = country)) +
     geom_point(data=d, aes(x=week, y=cases), color='black') +
     geom_line(size = 1) +  # Fitted curve for all countries
     labs(title = "Generalized Fourier Series Model Predictions (Jan 2023 - Dec 2024)",
          x = "Week",
          y = "Predicted Number of Cases") +
     facet_wrap(~ country, scales = "free_y") +  # Facet by country
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12),
           legend.position = "none")

###########################
###########################
###########################
###########################
###########################
###########################





library(ggplot2)
library(dplyr)

# Define the simple cosine wave model function
fit_simple_cosine <- function(data) {
     # Define the model function
     model_func <- function(t, beta0, a, p, x) {
          beta0 * (1 + a * cos(2 * pi * t / p + x))
     }

     # Define initial parameter guesses
     start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                       a = 0.5,  # Initial amplitude for cosine wave
                       p = 52,   # Assuming weekly data with a yearly cycle
                       x = 0)    # Initial phase shift for cosine wave

     # Perform the fitting using optim
     fit <- tryCatch({
          optim(par = start_params,
                fn = function(params) sum((data$cases - model_func(data$week, params[1], params[2], params[3], params[4]))^2),
                method = "L-BFGS-B",
                lower = c(-Inf, 0, 50, -Inf),  # Ensure positive amplitude and period close to 52
                upper = c(Inf, 1, 54, Inf),
                control = list(maxit = 1000))
     }, error = function(e) NULL)

     return(fit)
}




# Filter data for Nigeria
nigeria_data <- d[d$country == "Nigeria", ]

# Fit the simple cosine wave model to Nigeria's data
fit_nigeria <- fit_simple_cosine(nigeria_data)

# Check if the model fit was successful and predict fitted values
if (!is.null(fit_nigeria)) {
     nigeria_data$fitted_cases <- with(nigeria_data, fit_nigeria$par[1] * (1 + fit_nigeria$par[2] * cos(2 * pi * week / fit_nigeria$par[3] + fit_nigeria$par[4])))
} else {
     nigeria_data$fitted_cases <- NA
     print("Simple cosine wave model fitting failed for Nigeria.")
}




# Plot the observed data and the fitted curve for Nigeria
ggplot(nigeria_data, aes(x = week)) +
     geom_point(aes(y = cases), color = "blue", size = 2) +  # Observed data
     geom_line(aes(y = fitted_cases), color = "red", size = 1) +  # Fitted curve
     labs(title = "Simple Cosine Wave Model Fit to Weekly Cholera Cases in Nigeria",
          x = "Week",
          y = "Number of Cases") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12))













############
############
############
###########
#############
############



library(rnaturalearth)
library(sp)




# Function to retrieve the nearest neighbor for a given country
get_nearest_neighbor <- function(country_name) {
     # Load the world map data
     world <- ne_countries(scale = "medium", returnclass = "sf")

     # Extract the country of interest
     country <- world[world$admin == country_name, ]

     if (nrow(country) == 0) {
          stop("Country not found in the dataset.")
     }

     # Calculate the centroids of all countries
     centroids <- coordinates(world)

     # Calculate the centroid of the target country
     target_centroid <- coordinates(country)

     # Compute the distance between the target country and all other countries
     distances <- spDistsN1(centroids, target_centroid, longlat = TRUE)

     # Find the nearest neighbor, excluding the country itself
     nearest_index <- which.min(distances[-which(world$admin == country_name)])
     nearest_country <- world$admin[nearest_index]

     return(nearest_country)
}

# Example usage:
nearest_neighbor <- get_nearest_neighbor("Ethiopia")
print(paste("The nearest neighbor to Ethiopia is:", nearest_neighbor))


cholera_countries <- unique(cholera_data$country)

# Load the world map data
world <- ne_countries(scale = "medium", returnclass = "sf")

# Filter the world map to include only the countries present in the cholera data
cholera_map <- world[world$name %in% cholera_countries, ]

# Plot the map with highlighted countries
ggplot() +
     geom_sf(data = world, fill = "lightgray", color = "white") +
     geom_sf(data = cholera_map, fill = "red", color = "black") +
     labs(title = "Countries Present in Cholera Data",
          subtitle = "Highlighted in Red",
          caption = "Data source: rnaturalearth") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           plot.subtitle = element_text(size = 12),
           axis.text = element_blank(),
           axis.ticks = element_blank(),
           axis.title = element_blank())






# Load the necessary libraries
library(ggplot2)
library(reshape2)

# Load the data
cholera_data <- read.csv(file.path(getwd(), "data/cholera_country_weekly_processed.csv"), stringsAsFactors = FALSE)

# Define a lookup table for nearest neighbors (example)
nearest_neighbors <- list(
     "Country1" = "Neighbor1",
     "Country2" = "Neighbor2",
     "Ethiopia" = "Kenya",  # Example: Assume Kenya is the nearest neighbor
     # Add other countries and their nearest neighbors here
)

# Define the simple cosine wave model function
fit_simple_cosine <- function(data) {
     model_func <- function(t, beta0, a, p, x) {
          beta0 * (1 + a * cos(2 * pi * t / p + x))
     }

     # Define initial parameter guesses
     start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                       a = 0.5,  # Initial amplitude for cosine wave
                       p = 52,   # Assuming weekly data with a yearly cycle
                       x = 0)    # Initial phase shift for cosine wave

     # Perform the fitting using optim
     fit <- tryCatch({
          optim(par = start_params,
                fn = function(params) sum((data$cases - model_func(data$week, params[1], params[2], params[3], params[4]))^2),
                method = "L-BFGS-B",
                lower = c(-Inf, 0, 50, -Inf),
                upper = c(Inf, 1, 54, Inf),
                control = list(maxit = 1000))
     }, error = function(e) NULL)

     return(fit)
}

# Get the list of unique countries
countries <- unique(cholera_data$country)

# Initialize an empty list to store the results
fitted_data_list <- list()

# Define the weeks 1 to 52 for prediction
prediction_weeks <- data.frame(week = 1:52)

# Loop over each country and apply the cosine wave model including neighbor data
for (country in countries) {
     country_data <- cholera_data[cholera_data$country == country, ]

     # Get the nearest neighbor's data
     neighbor <- nearest_neighbors[[country]]
     if (!is.null(neighbor)) {
          neighbor_data <- cholera_data[cholera_data$country == neighbor, ]
          combined_data <- rbind(country_data, neighbor_data)
     } else {
          combined_data <- country_data
     }

     # Fit the simple cosine wave model to the combined data
     fit <- fit_simple_cosine(combined_data)

     # Check if the model fit was successful and predict fitted values
     if (!is.null(fit)) {
          country_data$fitted_cases <- with(country_data, fit$par[1] * (1 + fit$par[2] * cos(2 * pi * week / fit$par[3] + fit$par[4])))
          prediction_weeks$fitted_cases <- fit$par[1] * (1 + fit$par[2] * cos(2 * pi * prediction_weeks$week / fit$par[3] + fit$par[4]))
     } else {
          country_data$fitted_cases <- NA
          prediction_weeks$fitted_cases <- NA
          print(paste("Simple cosine wave model fitting failed for", country))
     }

     # Combine the historical data and the predicted data for weeks 1 to 52
     country_data$period <- "Historical"
     prediction_weeks$period <- "Prediction"
     prediction_weeks$country <- country
     combined_country_data <- rbind(country_data, prediction_weeks)

     # Store the combined data in the list
     fitted_data_list[[country]] <- combined_country_data
}

# Combine all fitted data into one data frame
fitted_data <- do.call(rbind, fitted_data_list)

# Plot the observed data and predictions for all countries
ggplot(fitted_data, aes(x = week)) +
     geom_point(aes(y = cases, color = period), size = 2, na.rm = TRUE) +  # Observed data
     geom_line(aes(y = fitted_cases, color = period), size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Simple Cosine Wave Model Fit and Predictions (Including Nearest Neighbor Data)",
          x = "Week",
          y = "Number of Cases") +
     facet_wrap(~ country, scales = "free_y") +  # Facet by country
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12))









# Filter the data for Zimbabwe, Mozambique, and Malawi
selected_countries <- c("Zimbabwe", "Mozambique", "Malawi")
selected_countries <- c("Nigeria", "Cameroon", "Togo")
combined_data <- cholera_data[cholera_data$country %in% selected_countries, ]




# Define the simple cosine wave model function
fit_simple_cosine <- function(data) {
     model_func <- function(t, beta0, a, p, x) {
          beta0 * (1 + a * cos(2 * pi * t / p + x))
     }

     # Define initial parameter guesses
     start_params <- c(beta0 = mean(data$cases, na.rm = TRUE),
                       a = 0.5,  # Initial amplitude for cosine wave
                       p = 52,   # Assuming weekly data with a yearly cycle
                       x = 0)    # Initial phase shift for cosine wave

     # Perform the fitting using optim
     fit <- tryCatch({
          optim(par = start_params,
                fn = function(params) sum((data$cases - model_func(data$week, params[1], params[2], params[3], params[4]))^2),
                method = "L-BFGS-B",
                lower = c(-Inf, 0, 50, -Inf),
                upper = c(Inf, 1, 54, Inf),
                control = list(maxit = 1000))
     }, error = function(e) NULL)

     return(fit)
}

# Fit the cosine wave model to the combined data
fit_combined <- fit_simple_cosine(combined_data)

# Predict the fitted values for the combined data
if (!is.null(fit_combined)) {
     combined_data$fitted_cases <- with(combined_data,
                                        fit_combined$par[1] * (1 + fit_combined$par[2] *
                                                                    cos(2 * pi * week / fit_combined$par[3] + fit_combined$par[4])))
} else {
     combined_data$fitted_cases <- NA
     print("Simple cosine wave model fitting failed for the combined data.")
}




# Plot the observed data and predictions for Zimbabwe, Mozambique, and Malawi
ggplot(combined_data, aes(x = week)) +
     geom_point(aes(y = cases, color = country), size = 2, na.rm = TRUE) +  # Observed data
     geom_line(aes(y = fitted_cases, color = country), size = 1, na.rm = TRUE) +  # Fitted curve
     labs(title = "Simple Cosine Wave Model Fit to Combined Data of Zimbabwe, Mozambique, and Malawi",
          x = "Week",
          y = "Number of Cases",
          color = "Country") +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12))







tmp <- arrow::read_parquet(file=file.path(PATHS$DATA_CLIMATE, "climate_data_MRI_AGCM3_2_S_temperature_2m_max_1970-01-01_2030-12-31_DZA.parquet"))










<div id="transitions-table"></div>
     ## Table of stochastic transitions
     ```{r transitions, echo=FALSE, message=FALSE, warning=FALSE}

tbl <- data.frame(
     "Term" = c(
          "**$\\mathbf{S}$ (susceptible)**",
          "$+ b_{jt} N_{jt}$",
          "$+ \\varepsilon R_{jt}$",
          "$+ \\omega_1 V_{1,jt}$",
          "$+ \\omega_2 V_{2,jt}$",
          "$- \\nu_{1,jt}S_{jt}/(S_{jt} + E_{jt})$",
          "$- \\Lambda^{S}_{j,t+1}$",
          "$+ \\Psi^S_{j,t+1}$",
          "$- d_{jt} S_{jt}$",
          "**$\\mathbf{V_1}$ (one-dose OCV)**",
          "$+ \\nu_{1,jt} S_{jt}/(S_{jt} + E_{jt})$",
          "$- \\omega_1 V_{1,jt}$",
          "$- \\Lambda^{V_1}_{j,t+1}$",
          "$+ \\Psi^{V_1}_{j,t+1}$",
          "$- d_{jt} V_{1,jt}$",
          "**$\\mathbf{V_2}$ (two-dose OCV)**",
          "$+ \\nu_{2,jt}$",
          "$- \\omega_2 V_{2,jt}$",
          "$- \\Lambda^{V_2}_{j,t+1}$",
          "$+ \\Psi^{V_2}_{j,t+1}$",
          "$- d_{jt} V_{2,jt}$",
          "**$\\mathbf{E}$ (exposed)**",
          "$+ \\Lambda_{j,t+1}$",
          "$+ \\Psi_{j,t+1}$",
          "$- \\iota E_{jt}$",
          "$- d_{jt} E_{jt}$",
          "**$\\mathbf{I_1}$ (symptomatic)**",
          "$+ \\sigma\\,\\iota\\,E_{jt}$",
          "$- \\gamma_1 I_{1,jt}$",
          "$- \\mu_j I_{1,jt}$",
          "$- d_{jt} I_{1,jt}$",
          "**$\\mathbf{I_2}$ (asymptomatic)**",
          "$+ (1-\\sigma)\\,\\iota\\,E_{jt}$",
          "$- \\gamma_2 I_{2,jt}$",
          "$- d_{jt} I_{2,jt}$",
          "**$\\mathbf{W}$ (environment)**",
          "$+ \\zeta_1 I_{1,jt}$",
          "$+ \\zeta_2 I_{2,jt}$",
          "$- \\delta_{jt} W_{jt}$",
          "**$\\mathbf{R}$ (recovered)**",
          "$+ \\gamma_1 I_{1,jt}$",
          "$+ \\gamma_2 I_{2,jt}$",
          "$- \\varepsilon R_{jt}$",
          "$- d_{jt} R_{jt}$"
     ),
     Description = c(
          "",
          "New individuals entering the susceptible class from births.",
          "Loss of immunity for recovered individuals.",
          "Waning immunity from one-dose OCV.",
          "Waning immunity from two-dose OCV.",
          "Susceptible individuals receiving one-dose OCV (leaving $S$).",
          "Human-to-human force of infection on the susceptible class.",
          "Environment-to-human force of infection on the susceptible class.",
          "Background death among susceptible individuals.",
          "",
          "Entry of susceptible individuals into the one-dose vaccinated class.",
          "Waning immunity in the one-dose vaccinated class.",
          "Human-to-human force of infection on the one-dose vaccinated class.",
          "Environment-to-human force of infection on one-dose vaccinated class.",
          "Background death among one-dose vaccinated individuals.",
          "",
          "Transition of one-dose vaccinated individuals to the two-dose vaccinated class (full course of OCV).",
          "Waning immunity in the two-dose vaccinated class.",
          "Human-to-human force of infection on the two-dose vaccinated class.",
          "Environment-to-human force of infection on the two-dose vaccinated class.",
          "Background death among two-dose vaccinated individuals.",
          "",
          "Human-to-human force of infection contributing to new exposures.",
          "Environment-to-human force of infection contributing to new exposures.",
          "Progression of exposed individuals toward the infectious class.",
          "Background death among exposed individuals.",
          "",
          "Exposed individuals progressing to symptomatic infection.",
          "Recovery from symptomatic infection.",
          "Deaths due to symptomatic infection.",
          "Background death among individuals with symptomatic infection.",
          "",
          "Exposed individuals progressing to asymptomatic infection.",
          "Recovery from asymptomatic infection.",
          "Background death among individuals with asymptomatic infection.",
          "",
          "Amount of *V. cholerae* (cells/ml) shed into the environment by symptomatic individuals.",
          "Amount of *V. cholerae* (cells/ml) shed into the environment by asymptomatic individuals.",
          "Decay of viable *V. cholerae* in the environment.",
          "",
          "Recovery of individuals with symptomatic infection.",
          "Recovery of individuals with asymptomatic infection.",
          "Loss of immunity for recovered individuals.",
          "Background death among recovered individuals."
     ),
     "Stochastic Transition" = c(
          "",
          "$\\text{Binom}\\big( N_{jt},\\; 1 - \\exp(-b_{jt}) \\big)$",
          "$\\text{Binom}\\big( R_{jt},\\; 1 - \\exp(-\\varepsilon) \\big)$",
          "$\\text{Binom}\\big( V_{1,jt},\\; 1 - \\exp(-\\omega_1) \\big)$",
          "$\\text{Binom}\\big( V_{2,jt},\\; 1 - \\exp(-\\omega_2) \\big)$",
          "$\\text{Pois}\\Big( \\nu_{1,jt} \\cdot \\frac{S_{jt}}{(S_{jt}+E_{jt})} \\Big)$",
          # Updated lambda term for susceptible:
          "$\\text{Binom}\\Big((1-\\tau_{j})S_{jt},\\ 1 - \\exp\\big({-\\beta_{jt}^{\\text{hum}} ((1-\\tau_{j})I_{jt} + \\sum_{\\forall i \\not= j} (\\pi_{ij}\\tau_iI_{it}))^{\\alpha_1} / N_{jt}^{\\alpha_2}}\\big)\\Big)$",
          # Updated psi term for susceptible:
          "$\\text{Binom}\\Big((1-\\tau_{j})S_{jt},\\ 1 - \\exp\\big({-\\beta_{jt}^{\\text{env}} (1-\\theta_j) W_{jt} / (\\kappa+W_{jt})}\\big)\\Big)$",
          "$\\text{Binom}\\big( S_{jt},\\; 1 - \\exp(-d_{jt}) \\big)$",
          "",
          "$\\text{Pois}\\Big( \\nu_{1,jt} \\cdot \\frac{S_{jt}}{(S_{jt}+E_{jt})} \\Big)$",
          "$\\text{Binom}\\big( V_{1,jt},\\; 1 - \\exp(-\\omega_1) \\big)$",
          # Updated lambda term for one-dose OCV:
          "$\\text{Binom}\\Big((1-\\tau_{j})(1-\\phi_1)V_{1,jt},\\ 1 - \\exp\\big({-\\beta_{jt}^{\\text{hum}} ((1-\\tau_{j})I_{jt} + \\sum_{\\forall i \\not= j} (\\pi_{ij}\\tau_iI_{it}))^{\\alpha_1} / N_{jt}^{\\alpha_2}}\\big)\\Big)$",
          # Updated psi term for one-dose OCV:
          "$\\text{Binom}\\Big((1-\\tau_{j})(1-\\phi_1)V_{1,jt},\\ 1 - \\exp\\big({-\\beta_{jt}^{\\text{env}} (1-\\theta_j) W_{jt} / (\\kappa+W_{jt})}\\big)\\Big)$",
          "$\\text{Binom}\\big( V_{1,jt},\\; 1 - \\exp(-d_{jt}) \\big)$",
          "",
          "$\\text{Pois}\\big( \\nu_{2,jt} \\big)$",
          "$\\text{Binom}\\big( V_{2,jt},\\; 1 - \\exp(-\\omega_2) \\big)$",
          # Updated lambda term for two-dose OCV:
          "$\\text{Binom}\\Big((1-\\tau_{j})(1-\\phi_2)V_{2,jt},\\ 1 - \\exp\\big({-\\beta_{jt}^{\\text{hum}} ((1-\\tau_{j})I_{jt} + \\sum_{\\forall i \\not= j} (\\pi_{ij}\\tau_iI_{it}))^{\\alpha_1} / N_{jt}^{\\alpha_2}}\\big)\\Big)$",
          # Updated psi term for two-dose OCV:
          "$\\text{Binom}\\Big((1-\\tau_{j})(1-\\phi_2)V_{2,jt},\\ 1 - \\exp\\big({-\\beta_{jt}^{\\text{env}} (1-\\theta_j) W_{jt} / (\\kappa+W_{jt})}\\big)\\Big)$",
          "$\\text{Binom}\\big( V_{2,jt},\\; 1 - \\exp(-d_{jt}) \\big)$",
          "",
          "$\\Lambda^{S}_{j,t+1} + \\Lambda^{V_1}_{j,t+1} + \\Lambda^{V_2}_{j,t+1}$",
          "$\\Psi^{S}_{j,t+1} + \\Psi^{V_1}_{j,t+1} + \\Psi^{V_2}_{j,t+1}$",
          "$\\text{Binom}\\big( E_{jt},\\; 1 - \\exp(-\\iota) \\big)$",
          "$\\text{Binom}\\big( E_{jt},\\; 1 - \\exp(-d_{jt}) \\big)$",
          "",
          "$\\text{Binom}\\big( \\sigma E_{jt},\\; 1 - \\exp(-\\iota) \\big)$",
          "$\\text{Binom}\\big( I_{1,jt},\\; 1 - \\exp(-\\gamma_1) \\big)$",
          "$\\text{Binom}\\big( I_{1,jt},\\; 1 - \\exp(-\\mu_j) \\big)$",
          "$\\text{Binom}\\big( I_{1,jt},\\; 1 - \\exp(-d_{jt}) \\big)$",
          "",
          "$\\text{Binom}\\big( (1-\\sigma) E_{jt},\\; 1 - \\exp(-\\iota) \\big)$",
          "$\\text{Binom}\\big( I_{2,jt},\\; 1 - \\exp(-\\gamma_2) \\big)$",
          "$\\text{Binom}\\big( I_{2,jt},\\; 1 - \\exp(-d_{jt}) \\big)$",
          "",
          "$\\text{Pois}\\big( \\zeta_1 I_{1,jt} \\big)$",
          "$\\text{Pois}\\big( \\zeta_2 I_{2,jt} \\big)$",
          "$\\text{Pois}\\big( \\delta_{jt} W_{jt} \\big)$",
          "",
          "$\\text{Binom}\\big( I_{1,jt},\\; 1 - \\exp(-\\gamma_1) \\big)$",
          "$\\text{Binom}\\big( I_{2,jt},\\; 1 - \\exp(-\\gamma_2) \\big)$",
          "$\\text{Binom}\\big( R_{jt},\\; 1 - \\exp(-\\varepsilon) \\big)$",
          "$\\text{Binom}\\big( R_{jt},\\; 1 - \\exp(-d_{jt}) \\big)$"
     )
)

knitr::kable(tbl, caption = "Stochastic Transitions and their descriptions for each term in the difference equations")

```

<div id="vaccination-table"></div>
     ## Table of vaccination model terms

```{r vaccination-table, echo=FALSE, message=FALSE, warning=FALSE}


vacc_terms <- data.frame(
     Compartment = c(
          "$V^{\\text{imm}}_{1,j,t+1}$",
          "$V^{\\text{sus}}_{1,j,t+1}$",
          "$V^{\\text{inf}}_{1,j,t+1}$",
          "$V^{\\text{imm}}_{2,j,t+1}$",
          "$V^{\\text{sus}}_{2,j,t+1}$",
          "$V^{\\text{inf}}_{2,j,t+1}$",
          "$V_{1,j,t}$",
          "$V_{2,j,t}$"
     ),
     Population = c(
          "Effectively immunized one-dose recipients",
          "Still susceptible one-dose recipients",
          "Infected one-dose recipients",
          "Effectively immunized two-dose recipients",
          "Still susceptible two-dose recipients",
          "Infected two-dose recipients",
          "Total one-dose recipients",
          "Total two-dose recipients"
     ),
     Equation = c(
          "$V^{\\text{imm}}_{1,j,t+1} = V^{\\text{imm}}_{1,jt}$ <br> $+\\,\\displaystyle\\frac{\\phi_1\\,\\nu_{1,jt}\\,S_{jt}}{(S_{jt}+E_{jt})}$ <br> $-\\,\\omega_1\\,V^{\\text{imm}}_{1,jt}$ <br> $-\\,\\displaystyle\\frac{\\nu_{2,jt}\\,V^{\\text{imm}}_{1,jt}}{(V^{\\text{imm}}_{1,jt}+V^{\\text{sus}}_{1,jt})}$ <br> $-\\,d_{jt}\\,V^{\\text{imm}}_{1,jt}$",
          "$V^{\\text{sus}}_{1,j,t+1} = V^{\\text{sus}}_{1,jt}$ <br> $+\\,\\displaystyle\\frac{(1-\\phi_1)\\,\\nu_{1,jt}\\,S_{jt}}{(S_{jt}+E_{jt})}$ <br> $+\\,\\omega_1\\,V^{\\text{imm}}_{1,jt}$ <br> $-\\,(\\Lambda^{V_1}_{j,t+1}+\\Psi^{V_1}_{j,t+1})$ <br> $-\\,\\displaystyle\\frac{\\nu_{2,jt}\\,V^{\\text{sus}}_{1,jt}}{(V^{\\text{imm}}_{1,jt}+V^{\\text{sus}}_{1,jt})}$ <br> $-\\,d_{jt}\\,V^{\\text{sus}}_{1,jt}$",
          "$V^{\\text{inf}}_{1,j,t+1} = V^{\\text{inf}}_{1,jt}$ <br> $+\\,(\\Lambda^{V_1}_{j,t+1}+\\Psi^{V_1}_{j,t+1})$ <br> $-\\,d_{jt}\\,V^{\\text{inf}}_{1,jt}$ <br> \\quad $\\mathbf{(tracking only)}$",
          "$V^{\\text{imm}}_{2,j,t+1} = V^{\\text{imm}}_{2,jt}$ <br> $+\\,\\phi_2\\,\\nu_{2,jt}$ <br> $-\\,\\omega_2\\,V^{\\text{imm}}_{2,jt}$ <br> $-\\,d_{jt}\\,V^{\\text{imm}}_{2,jt}$",
          "$V^{\\text{sus}}_{2,j,t+1} = V^{\\text{sus}}_{2,jt}$ <br> $+\\,(1-\\phi_2)\\,\\nu_{2,jt}$ <br> $+\\,\\omega_2\\,V^{\\text{imm}}_{2,jt}$ <br> $-\\,(\\Lambda^{V_2}_{j,t+1}+\\Psi^{V_2}_{j,t+1})$ <br> $-\\,d_{jt}\\,V^{\\text{sus}}_{2,jt}$",
          "$V^{\\text{inf}}_{2,j,t+1} = V^{\\text{inf}}_{2,jt}$ <br> $+\\,(\\Lambda^{V_2}_{j,t+1}+\\Psi^{V_2}_{j,t+1})$ <br> $-\\,d_{jt}\\,V^{\\text{inf}}_{2,jt}$ <br> \\quad $\\mathbf{(tracking only)}$",
          "$V_{1,j,t} = V^{\\text{imm}}_{1,j,t} + V^{\\text{sus}}_{1,j,t} + V^{\\text{inf}}_{1,j,t}$",
          "$V_{2,j,t} = V^{\\text{imm}}_{2,j,t} + V^{\\text{sus}}_{2,j,t} + V^{\\text{inf}}_{2,j,t}$"
     ),
     Notes = c(
          "+ Incoming newly vaccinated <br> - Waning vaccine immunity (⇒ $V^{\\text{sus}}_{1}$) <br> - Second dose recipients (⇒ $V_{2}$ compartment)",
          "+ Incoming newly vaccinated <br> + Waning vaccine immunity <br> - Infected (⇒ $E_{j,t}$) <br> - Second dose recipients (⇒ $V_{2}$ compartment)",
          "+ One-dose recipients infected (⇒ $E_{j,t}$) <br> **Compartment used for tracking only.**",
          "+ Incoming second dose recipients <br> - Waning vaccine immunity (⇒ $V^{\\text{sus}}_{2}$)",
          "+ Incoming second dose recipients <br> + Waning vaccine immunity <br> - Infected (⇒ $E_{j,t}$)",
          "+ Infected two-dose recipients (⇒ $E_{j,t}$) <br> **Compartment used for tracking only.**",
          "Sum of all one-dose sub-compartments. Tracked only and approximately equal to reported OCV campaign data. <br> **Compartment used for tracking only.**",
          "Sum of all two-dose sub-compartments. Tracked only and approximately equal to reported OCV campaign data. <br> **Compartment used for tracking only.**"
     ),
     stringsAsFactors = FALSE
)

knitr::kable(vacc_terms,
             col.names = c("Compartment", "Population", "Equation", "Notes"),
             caption = "Table of vaccination model terms.",
             escape = FALSE) %>%
     kableExtra::kable_styling(full_width = TRUE)



```





(10^7)/(10^5) * 0.01
(10^9)/(10^5) * 0.01
