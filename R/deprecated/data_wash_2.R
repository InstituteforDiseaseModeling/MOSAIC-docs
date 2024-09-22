library(reshape2)
library(dplyr)
library(ggplot2)
library(countrycode)




convert_country_to_iso3 <- function(country_names) {
     iso3_codes <- countrycode(country_names, origin = "country.name", destination = "iso3c", warn = TRUE)
     return(iso3_codes)
}

convert_iso3_to_country <- function(iso3_codes) {
     country_names <- countrycode(iso3_codes, origin = "iso3c", destination = "country.name")
     return(country_names)
}


afro_iso_codes <- c(
     "AGO", "BEN", "BWA", "BFA", "BDI", "CMR", "CAF", "TCD",
     "COM", "COG", "COD", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB",
     "GHA", "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT",
     "MUS", "MOZ", "NAM", "NER", "NGA", "RWA", "SEN", "SLE",
     "SOM", "ZAF", "SSD", "TGO", "UGA", "TZA", "ZMB", "ZWE"
)


year_start <- 2000
year_stop <- 2017

wash_data <- read.csv(file.path(getwd(), "data/gbd_wash_data.csv"), stringsAsFactors = FALSE)

incidence_data <- read.csv(file.path(getwd(), "data/who_afro_annual_1949_2024.csv"), stringsAsFactors = FALSE)
incidence_data <- incidence_data[incidence_data$year %in% c(year_start:year_stop),]
wash_data <- merge(wash_data, incidence_data[c('iso_code', "year", "cases_total")], by=c('iso_code', "year"))

pop_data <- read.csv(file.path(getwd(), "data/demographics_afro_2000_2023.csv"), stringsAsFactors = FALSE)
wash_data <- merge(wash_data, pop_data[,c("iso_code", "year", "population")], by=c("iso_code", "year"))

wash_data$incidence_per_1000 <- (wash_data$cases_total / (wash_data$population/1000))
head(wash_data)


if (F) {

     sikder_countries <- c("Nigeria", "Rwanda", "Sudan", "Senegal", "Sierra Leone", "Somalia", "South Sudan",
                           "Swaziland", "Chad", "Togo", "Tanzania", "Uganda", "South Africa", "Zambia", "Zimbabwe")

     wash_data <- wash_data[wash_data$iso_code %in% convert_country_to_iso3(sikder_countries),]

}


wash_data_wide <- reshape(wash_data,
                          timevar = "variable_name",
                          idvar = c("country", "iso_code", "year"),
                          direction = "wide",
                          v.names = "mean")

colnames(wash_data_wide) <- gsub("^mean\\.", "", colnames(wash_data_wide))
head(wash_data_wide)


wash_variables <- c("improved_water_other", "improved_sanitation", "improved_water",
                    "improved_sanitation_other","piped_sanitation", "piped_water", #"surface_water",
                    "open_defication", "unimproved_sanitation", "unimproved_water")
wash_variables_negative <- c("open_defication", "surface_water", "unimproved_sanitation", "unimproved_water")


for (w in wash_variables) wash_data_wide[,w] <- wash_data_wide[,w]/100
for (w in wash_variables_negative) wash_data_wide[,w] <- 1 - wash_data_wide[,w]

for (w in wash_variables) {

     sel <- !is.na(wash_data_wide[,w]) & (wash_data_wide[,w] < 0 | wash_data_wide[,w] > 1)
     wash_data_wide[sel,w] <- NA

     sel <- is.infinite(wash_data_wide[,w])
     wash_data_wide[sel,w] <- NA

     sel <- is.nan(wash_data_wide[,w])
     wash_data_wide[sel,w] <- NA
}

wash_data_wide$mean_wash <- rowMeans(wash_data_wide[, wash_variables])

head(wash_data_wide)







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
     correlation <- cor(weighted_mean, data$incidence_per_1000, use = "complete.obs")

     # Return the negative correlation because optim minimizes the objective function
     return(correlation)
}


# Set a seed for reproducibility
set.seed(123)

# Generate initial weights using a Dirichlet distribution
initial_weights <- gtools::rdirichlet(1, alpha = rep(1, length(wash_variables)))
#initial_weights <- rep(1/length(wash_variables), length(wash_variables))


# Optimize the weights to maximize the correlation with incidence
optimal_weights <- optim(par = initial_weights,
                         fn = calculate_weighted_correlation,
                         data = wash_data_wide,
                         wash_vars = wash_variables,
                         method = "L-BFGS-B",
                         lower = rep(0, length(wash_variables)),
                         upper = rep(1, length(wash_variables)),
                         control = list(maxit = 10000))

# Extract the optimized weights
best_weights <- optimal_weights$par / sum(optimal_weights$par)  # Normalize to sum to 1




# Calculate the weighted mean using the optimized weights
wash_data_wide$best_weighted_mean_wash <- rowSums(sweep(wash_data_wide[, wash_variables], 2, best_weights, `*`))

# Calculate the correlation with incidence
best_correlation <- cor(wash_data_wide$best_weighted_mean_wash, wash_data_wide$incidence_per_1000, use = "complete.obs")

# Print the best weights and the corresponding correlation
print(paste("Optimized Weights:", paste(round(best_weights, 4), collapse = ", ")))
print(paste("Best Correlation with Incidence:", round(best_correlation, 4)))



correlations <- sapply(c(wash_variables, "mean_wash", "best_weighted_mean_wash"), function(var) {
     cor(wash_data_wide[[var]], wash_data_wide$incidence_per_1000, use = "complete.obs")
})


# Add 'Mean_WASH' to the list of variables for plotting
wash_data_long <- melt(wash_data_wide,
                       id.vars = c("country", "iso_code", "year", "incidence_per_1000"),
                       measure.vars = c(wash_variables, "mean_wash", "best_weighted_mean_wash"),
                       variable.name = "wash_variable",
                       value.name = "value")

# Add the correlation as a label
wash_data_long <- wash_data_long %>%
     group_by(wash_variable) %>%
     mutate(correlation_label = paste0("r = ", round(correlations[wash_variable], 2)))

wash_data_long <- merge(wash_data_long, weights_table, by="wash_variable", all.x=TRUE)


head(wash_data_long)



weighted_wash_index <- data.frame()
for (i in afro_iso_codes) {

     if (i %in% wash_data_long$iso_code) {

          sel <- wash_data_long$iso_code == i
          tmp <- wash_data_long[sel,]
          tmp <- tmp[complete.cases(tmp[,c("value", "weight")]),]

          tmp <- data.frame(
               country = NA,
               iso_code = i,
               weighted_wash_index = weighted.mean(x=tmp$value, w=tmp$weight)
          )

     } else {

          tmp <- data.frame(
               country = NA,
               iso_code = i,
               weighted_wash_index = NA
          )
     }

     weighted_wash_index <- rbind(tmp, weighted_wash_index)
}


weighted_wash_index$country <- convert_iso3_to_country(weighted_wash_index$iso_code)
weighted_wash_index$country[weighted_wash_index$iso_code == 'COD'] <- "Democratic Republic of Congo"
weighted_wash_index$country[weighted_wash_index$iso_code == 'COG'] <- "Congo"

# Exceptions
# If Equitorial Guinea NA substitute Cameroon value
sel <- weighted_wash_index$iso_code == 'GNQ'
if (is.na(weighted_wash_index$weighted_wash_index[sel])) {

     weighted_wash_index$weighted_wash_index[sel] <-
          weighted_wash_index$weighted_wash_index[weighted_wash_index$iso_code == 'CMR']
}

# Mauritius <- Comoros
sel <- weighted_wash_index$iso_code == 'MUS'
if (is.na(weighted_wash_index$weighted_wash_index[sel])) {

     weighted_wash_index$weighted_wash_index[sel] <-
          weighted_wash_index$weighted_wash_index[weighted_wash_index$iso_code == 'COM']
}

# Botswana <- Namibia
sel <- weighted_wash_index$iso_code == 'BWA'
if (is.na(weighted_wash_index$weighted_wash_index[sel])) {

     weighted_wash_index$weighted_wash_index[sel] <-
          weighted_wash_index$weighted_wash_index[weighted_wash_index$iso_code == 'NAM']
}


# View the result
print(weighted_wash_index)



# Plot each WASH variable, including the Mean_WASH, against Incidence_per_1000 using facets and display correlation
ggplot(wash_data_long[!(wash_data_long$wash_variable %in% c("mean_wash", "best_weighted_mean_wash")),], aes(x = value, y = incidence_per_1000)) +
     geom_point(color = "black", size = 2) +
     geom_smooth(method = "lm", se = FALSE, color = "blue") +
     facet_wrap(~ as.character(wash_variable), ncol = 3) +
     geom_text(aes(label = correlation_label), x = Inf, y = Inf, hjust = 1.1, vjust = 1.5, size = 4, color = "black") +
     labs(title = "Relationship Between WASH Variables and Cholera Incidence",
          x = "WASH Variable Value",
          y = "Incidence per 1,000") +
     scale_x_continuous(limits = c(0,1)) +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12),
           strip.text = element_text(size = 12, face = "bold"))

# Plot each WASH variable, including the Mean_WASH, against Incidence_per_1000 using facets and display correlation
ggplot(wash_data_long[wash_data_long$wash_variable %in% c("mean_wash", "best_weighted_mean_wash"),], aes(x = value, y = incidence_per_1000)) +
     geom_point(color = "black", size = 2) +
     geom_smooth(method = "lm", se = FALSE, color = "red") +
     facet_wrap(~ as.character(wash_variable), nrow=1) +
     geom_text(aes(label = correlation_label), x = Inf, y = Inf, hjust = 1.1, vjust = 1.5, size = 4, color = "black") +
     labs(title = "Relationship Between WASH Variables and Cholera Incidence",
          x = "WASH Variable Value",
          y = "Incidence per 1,000") +
     scale_x_continuous(limits = c(0,1)) +
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12),
           strip.text = element_text(size = 12, face = "bold"))






# Plot the Best Weighted Mean as a bar plot with country on the x-axis
ggplot(weighted_wash_index, aes(x = reorder(country, -weighted_wash_index), y = weighted_wash_index)) +
     geom_bar(stat = "identity", fill = "steelblue") +  # Bar plot
     geom_hline(yintercept = 0) +
     labs(title = "Best Weighted Mean of WASH Variables by Country",
          x = NULL,
          y = "Best Weighted Mean of WASH Variables") +
     scale_y_continuous(expand=c(0,0)) +  # Set y-axis limits from 0 to 1
     theme_minimal() +
     theme(plot.title = element_text(size = 16, face = "bold"),
           axis.title = element_text(size = 14, margin = margin(t = 20, r = 20)),
           axis.ticks.x = element_line(size=0.75),
           axis.text = element_text(size = 11),
           axis.text.x = element_text(angle = 70, hjust = 1, vjust=1.01),
           panel.grid.minor = element_blank(),
           panel.grid.major.x = element_blank())  # Rotate x-axis labels for readability





# Create a data frame with WASH variables and their corresponding optimized weights
weights_table <- data.frame(
     wash_variable = wash_variables,
     weight = as.vector(round(best_weights, 4))  # Round the weights to 4 decimal places for readability
)

# Print the table
print(weights_table)
