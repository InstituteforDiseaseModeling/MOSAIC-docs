library(minpack.lm)
library(ggplot2)
library(scales)
library(cowplot)
library(truncnorm)
library(stringr)

# Ali et al 2011: https://academic.oup.com/jid/article/204/6/912/2192169?login=false
# Clemens et al 1991:

# Create the initial dataframe with some known values
df <- data.frame(
     day = c(90, 30*36, 30*42),
     effectiveness = c(0.95, 0.65, 0.61),
     effectiveness_hi = c(0.95, 0.81, 0.81),
     effectiveness_lo = c(0.95, 0.37, 0.21),
     source = c("Assumption", "Ali et al (2011)", "Clemens et al (1991)")
)

df$source <- factor(df$source, levels=c("Ali et al (2011)", "Clemens et al (1991)", "Assumption"))

# Define the proportional decay function
proportional_decay_function <- function(par, x) {
     a <- par[1]
     b <- par[2]
     a * (1 - b) ^ x
}

# Starting values for the parameters for proportional decay model
start_values <- c(a = 0.95, b = 0.00025)  # a is the initial immune proportion, b is the decay rate

objective_function <- function(par) {
     residuals <- df$effectiveness - proportional_decay_function(par, df$day)
     residuals
}

fit <- nls.lm(par = start_values,
              fn = objective_function,
              upper = c(0.99, 1),
              lower = c(0.99, 0),
              control = nls.lm.control(maxiter = 1000))



objective_function <- function(par) {
     residuals <- df$effectiveness_hi - proportional_decay_function(par, df$day)
     residuals
}

fit_hi <- nls.lm(par = start_values,
              fn = objective_function,
              upper = c(0.99, 1),
              lower = c(0.99, 0),
              control = nls.lm.control(maxiter = 1000))

objective_function <- function(par) {
     residuals <- df$effectiveness_lo - proportional_decay_function(par, df$day)
     residuals
}

fit_lo <- nls.lm(par = start_values,
              fn = objective_function,
              upper = c(0.99, 1),
              lower = c(0.99, 0),
              control = nls.lm.control(maxiter = 1000))



# Extract the fitted parameters
fitted_parameters <- fit$par
fitted_parameters_hi <- c(fit_hi$par[1], fit_hi$par[2])
fitted_parameters_lo <- c(fit_lo$par[1], fit_lo$par[2])

# Create a new dataframe for predicted values
prediction <- data.frame(day = seq(0, 365*15, by = 1))

# Add a 'predicted' column with the model's predictions for the range of day
prediction$predicted <- proportional_decay_function(fitted_parameters, prediction$day)
prediction$predicted_lo <- proportional_decay_function(fitted_parameters_lo, prediction$day)
prediction$predicted_hi <- proportional_decay_function(fitted_parameters_hi, prediction$day)
head(prediction)


p1 <-
     ggplot() +
     geom_ribbon(data = prediction, aes(x = day, ymin = predicted_lo, ymax = predicted_hi), fill = "grey", alpha = 0.2) +  # Shaded ribbon for confidence intervals
     geom_line(data = prediction, aes(x = day, y = predicted), color = 'black', size = 1.25) +
     geom_line(data = prediction, aes(x = day, y = predicted_lo), color = '#DAA520', size = 0.75, linetype='dashed') +
     geom_line(data = prediction, aes(x = day, y = predicted_hi), color = '#6A5ACD', size = 0.75, linetype='dashed') +
     geom_point(data = df[1,], aes(x = day, y = effectiveness, color = source), fill='white', pch=21, size = 5) +  # Points for original data
     geom_point(data = df[2,], aes(x = day, y = effectiveness, color = source), size = 5) +  # Points for original data
     geom_point(data = df[3,], aes(x = day, y = effectiveness, color = source), size = 5) +
     geom_segment(data = df[2,], aes(x = day, y = effectiveness_lo, yend = effectiveness_hi, color = source), size=1.25) +  # Horizontal error bars
     geom_segment(data = df[3,], aes(x = day, y = effectiveness_lo, yend = effectiveness_hi, color = source), size=1.25) +  # Horizontal error bars
     annotate("text", x = 365 * 12.25, y = 0.75, label = bquote(epsilon == .(sprintf("%.5f", fitted_parameters_hi[2]))), color = "#6A5ACD", size = 5) +
     annotate("text", x = 365 * 12.25, y = 0.7, label = bquote(epsilon == .(sprintf("%.5f", fitted_parameters[2]))), color = "black", size = 5) +
     annotate("text", x = 365 * 12.25, y = 0.65, label = bquote(epsilon == .(sprintf("%.5f", fitted_parameters_lo[2]))), color = "#DAA520", size = 5) +
     labs(x = "Years after infection", y = "Proportion immune") +
     ggtitle("A") +
     theme_classic(base_size = 18) +
     theme(panel.grid.minor = element_blank(),  # Remove minor gridlines
           panel.grid.major.y = element_blank(),
           axis.title.x = element_text(margin = margin(t = 15)),  # Increase space between x-axis and x-axis label
           axis.title.y = element_text(margin = margin(r = 15)),
           legend.position = c(0.99, 0.975),  # Place legend inside the plot (top-right corner)
           legend.justification = c("right", "top"),  # Align the legend to the right-top
           legend.title = element_blank(),  # Remove the legend title
           legend.text = element_text(size = 11),
           legend.background = element_blank()) +
     scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
     scale_x_continuous(limits = c(0, 365*15), labels = 1:15, breaks = 365 * (1:15), expand = c(0, 0)) +  # Yearly labels and breaks
     scale_color_manual(values = c('Ali et al (2011)' = "#FF6347",
                                   'Clemens et al (1991)' = "#008B8B",
                                   'Assumption' = 'black'))

sd_epsilon <- ((fitted_parameters_lo[2] - fitted_parameters_hi[2])) / (2*1.96)
mean_epsilon <- fitted_parameters[2]

# Create the normal distribution plot (p2)
#x_vals <- seq(mean_epsilon - 4*sd_epsilon, mean_epsilon + 4*sd_epsilon, length.out = 1000)
x_vals <- seq(fitted_parameters_hi[2], fitted_parameters_lo[2], length.out = 1000)

#y_vals <- dnorm(x_vals, mean = mean_epsilon, sd = sd_epsilon)
#y_vals <- dtruncnorm(x_vals, a = fitted_parameters_hi[2], b = fitted_parameters_lo[2], mean = mean_epsilon, sd = sd_epsilon)
y_vals <- dlnorm(x_vals, meanlog = log(mean_epsilon + ((sd_epsilon^2)/2)), sdlog = 0.25)

p2 <- ggplot(data.frame(x = x_vals, y = y_vals), aes(x = x, y = y)) +
     geom_area(fill = "grey", alpha = 0.2) +  # Fill the area under the curve
     geom_line(color = "grey50", size = 1) +
     geom_vline(xintercept = mean_epsilon, linetype = "solid", color = "black", size = 1.25) +
     geom_vline(xintercept = fitted_parameters_hi[2], linetype = "dashed", color = "#6A5ACD", size = 0.75) +  # Dashed grey line at x = 0
     geom_vline(xintercept = fitted_parameters_lo[2], linetype = "dashed", color = "#DAA520", size = 0.75) +  # Dashed grey line at x = 0
     labs(x = str_wrap(expression("Decay rate in immunity from natural infection (\u03B5)"), , width = 20)) +  # Only label the x-axis
     ggtitle("B") +
     scale_y_continuous(limits = c(0, max(y_vals) * 1.1), expand = c(0, 0)) +  # Yearly labels and breaks
     theme_classic(base_size = 18) +
     theme(
          axis.title.y = element_blank(),  # Remove the y-axis label
          axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),  # Rotate x-axis labels
          axis.title.x = element_text(margin = margin(t = 30), hjust = 0.5),  # Increase space between x-axis title and labels
          plot.margin = unit(c(1.75, 0.1, 0.75, 0.1), "inches")  # Adjust margins
     )

p2

# Combine the plots
combo <- plot_grid(p1, p2, nrow = 1, rel_widths = c(2.25, 1))
combo


png(filename = "./figures/immune_durability.png", width = 3000, height = 2000, units = "px", res=300)
combo
dev.off()



