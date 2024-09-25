library(propvacc)
library(ggplot2)
library(dplyr)
library(glue)
library(RColorBrewer)

cholera_data <- read.csv(file.path(getwd(), "data/who_afro_annual_1949_2024.csv"), stringsAsFactors = FALSE)

cholera_data$cfr <- cholera_data$deaths_total / cholera_data$cases_total
cholera_data$cfr_lo <- cholera_data$cfr_hi <- NA
cholera_data$shape2 <- cholera_data$shape1 <- NA

for (i in 1:nrow(cholera_data)) {

     if (!is.na(cholera_data$cases_total[i]) & !is.na(cholera_data$deaths_total[i])) {

          if (cholera_data$cases_total[i] > 0) {

               cholera_data$cfr_lo[i] <- binom.test(x=cholera_data$deaths_total[i], n=cholera_data$cases_total[i])$conf.int[1]
               cholera_data$cfr_hi[i] <- binom.test(x=cholera_data$deaths_total[i], n=cholera_data$cases_total[i])$conf.int[2]

               prm <- propvacc::get_beta_params(quantiles=c(0.0275, 0.5, 0.975),
                                                probs=c(cholera_data$cfr_lo[i], cholera_data$cfr[i], cholera_data$cfr_hi[i]))

               cholera_data$shape1[i] <- prm$shape1
               cholera_data$shape2[i] <- prm$shape2
          }
     }
}

head(cholera_data)


cholera_data_recent <- cholera_data[cholera_data$year >= 2014,]

cholera_data_recent <- aggregate(cbind(cases_total, deaths_total) ~ country, data = cholera_data[cholera_data$year >= 2021,], sum, na.rm = TRUE)
cholera_data_recent <- cholera_data_recent[complete.cases(cholera_data_recent),]
cholera_data_recent <- cholera_data_recent[cholera_data_recent$cases_total > (3/0.02),]

cholera_data_recent$cfr <- cholera_data_recent$deaths_total / cholera_data_recent$cases_total
cholera_data_recent$cfr_lo <- cholera_data_recent$cfr_hi <- NA
cholera_data_recent$shape2 <- cholera_data_recent$shape1 <- NA

for (i in 1:nrow(cholera_data_recent)) {

     cholera_data_recent$cfr_lo[i] <- binom.test(x=cholera_data_recent$deaths_total[i], n=cholera_data_recent$cases_total[i])$conf.int[1]
     cholera_data_recent$cfr_hi[i] <- binom.test(x=cholera_data_recent$deaths_total[i], n=cholera_data_recent$cases_total[i])$conf.int[2]

     prm <- propvacc::get_beta_params(quantiles=c(0.0275, 0.5, 0.975),
                                      probs=c(cholera_data_recent$cfr_lo[i], cholera_data_recent$cfr[i], cholera_data_recent$cfr_hi[i]))

     cholera_data_recent$shape1[i] <- prm$shape1
     cholera_data_recent$shape2[i] <- prm$shape2


}

head(cholera_data_recent)

plot(cholera_data_recent$cases_total, cholera_data_recent$cfr)



missing_countries <- setdiff(unique(cholera_data$country), cholera_data_recent$country)

sel <- cholera_data_recent$country == "AFRO Region"

missing_data <- data.frame(
     country = missing_countries,
     cases_total = NA,
     deaths_total = NA,
     cfr = cholera_data_recent$cfr[sel],
     cfr_lo = cholera_data_recent$cfr_lo[sel],
     cfr_hi = cholera_data_recent$cfr_hi[sel],
     shape1 = cholera_data_recent$shape1[sel],
     shape2 = cholera_data_recent$shape2[sel],
     stringsAsFactors = FALSE
)

cholera_data_recent <- rbind(cholera_data_recent, missing_data)

# Set countries with CFR = 0 to have CFR average of AFRO
afro_region_values <- cholera_data_recent[cholera_data_recent$country == "AFRO Region", ]

sel <- which(cholera_data_recent$cfr == 0)
cholera_data_recent$cfr[sel] <- afro_region_values$cfr
cholera_data_recent$cfr_lo[sel] <- afro_region_values$cfr_lo
cholera_data_recent$cfr_hi[sel] <- afro_region_values$cfr_hi
cholera_data_recent$shape1[sel] <- afro_region_values$shape1
cholera_data_recent$shape2[sel] <- afro_region_values$shape2

head(cholera_data_recent[sel, ])
head(cholera_data_recent)

write.csv(cholera_data_recent, file=file.path(getwd(), "figures/case_fatality_ratio_2014_2024.csv"), row.names = FALSE)





################################################################################
# Plot actual CFR mean and CIs
################################################################################

# Define the color palette
pal <- colorRampPalette(RColorBrewer::brewer.pal(9, "Set1"))(48)
pal <- adjustcolor(pal, 5)
pal <- c('black', pal)

d <- cholera_data_recent
d$country <- factor(d$country, levels=c("AFRO Region", sort(unique(d$country[d$country != "AFRO Region"]))))

afro_mean_cfr <- d$cfr[d$country == "AFRO Region"]

# Plot 1: CFR with CIs
p1 <-
     ggplot(d, aes(x = country, y = cfr, color = country)) +
     geom_hline(yintercept = afro_mean_cfr, linetype = "solid", color = "black", size = 0.25) +
     geom_point(size = 3.5) +
     geom_errorbar(aes(ymin = cfr_lo, ymax = cfr_hi), width = 0, size = 1) +
     scale_color_manual(values = pal) +  # Apply the custom color palette
     scale_x_discrete(limits = rev(levels(d$country))) +
     labs(title="A", y = "Case Fatality Ratio (CFR)") +
     theme_minimal() +
     theme(axis.text.x = element_text(size = 10),
           axis.text.y = element_text(size = 10),
           axis.title.x = element_text(margin = margin(t = 20)),
           axis.title.y = element_blank(),
           panel.grid.minor = element_blank(),
           panel.grid.major.x = element_line(size=0.25),
           panel.grid.major.y = element_blank(),
           legend.position = "none") +
     coord_flip()

# Plot 2: Bar plot for cases_total with sqrt transformation and original scale labels

pretty(d$cases_total)

p2 <-
     ggplot(d, aes(x = country, y = cases_total, fill = country)) +
     geom_hline(yintercept = 0, linetype = "solid", color = "black", size = 0.25) +
     geom_bar(stat = "identity") +
     scale_fill_manual(values = pal) +  # Apply the custom color palette
     scale_y_sqrt(breaks = c(1000, 25000, 100000, 250000, 500000),
                  labels = scales::comma,,
                  expand = c(0,0)) +  # Original scale labels
     scale_x_discrete(limits = rev(levels(d$country))) +
     labs(title="B", x = NULL, y = "Total Cases") +
     theme_minimal() +
     theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
           axis.text.y = element_blank(),
           axis.title.x = element_text(margin = margin(t = 20)),
           axis.title.y = element_blank(),
           panel.grid.minor = element_blank(),
           panel.grid.major.x = element_line(size=0.25),
           panel.grid.major.y = element_blank(),
           legend.position = "none") +
     coord_flip()

# Combine the two plots using cowplot
combined_plot <- plot_grid(p1, p2, ncol = 2, align = "h", rel_widths = c(2, 1))
combined_plot

# Save the combined plot
png(filename = "./figures/case_fatality_ratio_and_cases_total_by_country.png", width = 2000, height = 3000, units = "px", res = 300)
print(combined_plot)
dev.off()





################################################################################
# Plot examples of Beta distributions
################################################################################

# Define the color palette used in the previous plot
pal <- colorRampPalette(RColorBrewer::brewer.pal(9, "Set1"))(48)
pal <- adjustcolor(pal, 5)
pal <- c('black', pal)

# Create a named vector for the color palette to ensure matching colors
names(pal) <- c("AFRO Region", sort(unique(cholera_data_recent$country[cholera_data_recent$country != "AFRO Region"])))

# Identify the country with the highest CFR
highest_cfr_country <- cholera_data_recent %>%
     filter(!is.na(cfr)) %>%
     filter(country != "AFRO Region") %>%
     arrange(desc(cfr)) %>%
     slice(1) %>%
     pull(country)

# Identify the country with the lowest CFR
lowest_cfr_country <- cholera_data_recent %>%
     filter(!is.na(cfr)) %>%
     filter(country != "AFRO Region") %>%
     arrange(cfr) %>%
     slice(1) %>%
     pull(country)

# Filter data for the selected countries
tmp <- cholera_data_recent %>%
     filter(country %in% c("AFRO Region", highest_cfr_country, lowest_cfr_country))

# Generate beta density data
x_vals <- seq(0, 1, length.out = 1000)

beta_density <- tmp %>%
     filter(!is.na(shape1) & !is.na(shape2)) %>%
     group_by(country) %>%
     do(data.frame(x = x_vals,
                   density = dbeta(x_vals, shape1 = .$shape1, shape2 = .$shape2),
                   country = .$country)) %>%
     ungroup()

# Split the data to control the layering order
afro_data <- beta_density %>% filter(country == "AFRO Region")
other_data <- beta_density %>% filter(country != "AFRO Region")

# Create the plot with AFRO Region line on top
p2 <-
     ggplot() +
     geom_line(data = other_data, aes(x = x, y = density, color = country), size = 1.6) +
     geom_line(data = afro_data, aes(x = x, y = density, color = country), size = 1.6) +  # AFRO Region on top
     coord_cartesian(xlim = c(0, 0.15), ylim = c(0, 12)) +  # Zoom in on the x-axis
     labs(x = "Case Fatality Ratio (CFR)",
          y = "Density") +
     scale_color_manual(values = pal[c("AFRO Region", highest_cfr_country, lowest_cfr_country)]) +  # Set colors to match previous plot
     scale_x_continuous(expand = c(0.005, 0.005)) +
     scale_y_continuous(expand = c(0.005, 0.005)) +
     theme_minimal() +
     theme(legend.position = "right",
           legend.title = element_blank(),
           legend.text = element_text(size = 10.5),
           plot.title = element_text(size = 16, face = "bold"),
           plot.subtitle = element_text(size = 12),
           axis.title = element_text(size = 14),
           axis.text = element_text(size = 12),
           axis.title.x = element_text(margin = margin(t = 20)),
           axis.title.y = element_text(margin = margin(r = 20)))

p2


png(filename = "./figures/case_fatality_ratio_beta_distributions.png", width = 2000, height = 1500, units = "px", res=300)
p2
dev.off()

