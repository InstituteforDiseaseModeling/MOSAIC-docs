
df <- read.csv("./data/harris_2009_cholera_symptomatic_rate.csv")
df <- read.csv("./data/harris_2009_cholera_symptomatic_rate_2.csv")

# Rename columns to 'Age' and 'Probability'
colnames(df) <- c("Age", "Probability")

# Round Age to integers
df$Age <- round(df$Age)

# Round Probability to two digits
df$Probability <- round(df$Probability, 2)

# Calculate mean, standard deviation, and 95% CI for Probability
mean_prob <- mean(df$Probability)
sd_prob <- sd(df$Probability)
n <- nrow(df)
error_margin <- qnorm(0.975) * sd_prob / sqrt(n)
ci_lower <- mean_prob - error_margin
ci_upper <- mean_prob + error_margin

# Print summary
cat("Mean Probability:", mean_prob, "\n")
cat("Standard Deviation:", sd_prob, "\n")
cat("95% CI: [", ci_lower, ",", ci_upper, "]\n")


# Load necessary libraries
library(ggplot2)
library(cowplot)

# Assuming df is already loaded and processed

# Bar plot of Age vs. Probability
bar_plot <- ggplot(df, aes(x = factor(Age), y = Probability)) +
     geom_bar(stat = "identity", fill = "dodgerblue", color = "black", alpha = 0.7) +
     labs(title = "Age vs. Probability", x = "Age", y = "Probability") +
     theme_minimal(base_size = 16)

# Histogram of Probability values collapsed by Age
hist_plot <- ggplot(df, aes(x = Probability)) +
     geom_histogram(binwidth = 0.02, fill = "grey", color = "black", alpha = 0.7) +
     coord_flip() +
     labs(x = "Probability", y = "Count") +
     theme_minimal(base_size = 16) +
     theme(axis.text.y = element_blank(),
           axis.ticks.y = element_blank())

# Combine the plots side by side
combined_plot <- plot_grid(bar_plot, hist_plot, ncol = 2, rel_widths = c(3, 1))

# Display the combined plot
print(combined_plot)
