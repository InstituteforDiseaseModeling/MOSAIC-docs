library(ggplot2)
library(cowplot)

# Set parameters for the gamma distribution
shape <- 0.5  # shape parameter (k). Could also be 0.3, 0.5, 0.7, 1.0 for mean generation times of 3,5,7,10
rate <- 0.1   # rate parameter (1/scale)

# Calculate mean and 95% CI
mean_val <- shape / rate
lower_bound <- qgamma(0.025, shape = shape, rate = rate)
upper_bound <- qgamma(0.975, shape = shape, rate = rate)

# Generate the gamma distribution for x = 1:60
x <- 1:(7*8)
y <- dgamma(x, shape = shape, rate = rate)

# Create a data frame for plotting
df <- data.frame(x = x, y = y)

# Aggregate days into 7-day weeks
week_bins <- cut(x, breaks = seq(0, max(x), by = 7), include.lowest = TRUE)
week_aggregated <- aggregate(y, by = list(week_bins), FUN = sum)

# Rename columns and normalize probabilities
colnames(week_aggregated) <- c("Interval", "Total_Probability")
week_aggregated$Week <- 1:nrow(week_aggregated)
total_sum <- sum(week_aggregated$Total_Probability)
week_aggregated$Probability <- week_aggregated$Total_Probability / total_sum
week_aggregated <- week_aggregated[,-which(colnames(week_aggregated) == 'Total_Probability')]

write.csv(df, file="./figures/generation_time_days.csv", row.names = F)
write.csv(week_aggregated, file="./figures/generation_time_weeks.csv", row.names = F)

# Create the base plot for the gamma distribution
base_plot <- ggplot(df, aes(x = x, y = y)) +
     geom_bar(stat = "identity", aes(y = y), fill = "dodgerblue", color = "white", width = 0.99) +  # Per-day probabilities as bars
     geom_line(color = 'black', size = 1.5) +  # Gamma distribution line
     geom_vline(xintercept = mean_val, linetype = "solid", color = "#E41A1C", size = 1.25) +  # Mean line
     geom_vline(xintercept = upper_bound, linetype = "dashed", color = "#E41A1C", size = 0.75) +  # Upper CI line
     geom_vline(xintercept = lower_bound, linetype = "dashed", color = "#E41A1C", size = 0.75) +  # Lower CI line
     labs(title = 'A', x = 'Day', y = 'Probability') +
     theme_minimal(base_size = 16) +
     theme(
          axis.ticks.y = element_line(),
          axis.title.x = element_text(margin = margin(t = 10)),
          axis.title.y = element_text(margin = margin(r = 10)),
          panel.grid.minor = element_blank(),  # Remove minor gridlines
          panel.grid.major = element_line(color = "grey70", size=0.1)
     ) +
     scale_y_continuous(expand = c(0.001, 0.001)) +
     scale_x_continuous(breaks = seq(0, max(x), by = 7), limits = c(0, max(x)), expand = c(0.001, 0.001))  # Align gridlines with weeks

# Create a bar plot for the normalized probabilities using week numbers
bar_plot <- ggplot(week_aggregated, aes(x = Week - 0.5, y = Probability)) +
     geom_bar(stat = "identity", fill = "dodgerblue", color = "white", width = 0.95) +
     labs(title = "B", x = 'Week', y = 'Probability') +
     theme_minimal(base_size = 16) +
     theme(
          axis.ticks.y = element_line(),
          axis.title.x = element_text(margin = margin(t = 10)),
          axis.title.y = element_text(margin = margin(r = 10)),
          panel.grid.minor = element_blank(),  # Remove minor gridlines
          panel.grid.major = element_line(color = "grey70", size=0.1)
     ) +
     scale_y_continuous(expand = c(0.001, 0.001)) +
     scale_x_continuous(breaks = seq(1, max(x)/7, by = 1), limits = c(0, max(x)/7), expand = c(0.001, 0.001))  # Adjust breaks to match shifted bars

# Combine the plots using cowplot with aligned axes
combo <- plot_grid(base_plot, bar_plot, ncol = 1, align = "v")

# Display the combined plot
print(combo)


png(filename = "./figures/generation_time.png", width = 2500, height = 2000, units = "px", res=300)
combo
dev.off()
