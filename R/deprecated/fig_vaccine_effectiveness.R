
library(minpack.lm)
library(ggplot2)
library(scales)
library(cowplot)


# Data are from Malembaka et al 2024: https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(23)00742-9/fulltext

# Create the initial dataframe with some known values
df <- data.frame(
     month = c(mean(c(12, 17)), mean(c(24, 36))),
     effectiveness = c(0.527, 0.447),
     effectiveness_hi = c(0.674, 0.594),
     effectiveness_lo = c(0.314, 0.248),
     month_min = c(12, 24),
     month_max = c(17, 36)
)

print("Initial DataFrame:")
print(df)

# Define the Weibull decay model function
weibull_decay_function <- function(par, x) {
     a <- par[1]
     b <- par[2]
     c <- par[3]
     a * exp(-(x / b)^c)
}

# Starting values for the parameters for Weibull model (with c > 1 for increasing decay rate)
start_values <- c(a = 0.5375, b = 50, c = 3.3)

# Fit the model using nls.lm(), using the non-NA values for fitting
fit <- nls.lm(par = start_values,
              fn = function(par) {
                   residuals <- df$effectiveness - weibull_decay_function(par, df$month)
                   residuals
              },
              control = nls.lm.control(maxiter = 10000)  # Increase max iterations to 1000
)

# Extract the fitted parameters
fitted_parameters <- fit$par
print("Fitted Parameters:")
print(fitted_parameters)

# Create a new dataframe for predicted values
prediction_month <- data.frame(month = seq(0, 120, by = 1))

# Add a 'predicted' column with the model's predictions for the range of month
prediction_month$predicted <- weibull_decay_function(fitted_parameters, prediction_month$month)
prediction_month$predicted_lo <- prediction_month$predicted_hi <- NA

n <- 470

for (i in 1:nrow(prediction_month)) {

     tmp <- prop.test(prediction_month$predicted[i]*n, n)
     prediction_month$predicted_lo[i] <- tmp$conf.int[1]
     prediction_month$predicted_hi[i] <- tmp$conf.int[2]

}

# Display the dataframe with predicted values
print("Prediction DataFrame:")
print(prediction_month)




# Get beta distribution for vaccine effectiveness

quants <- c(0.001, 0.25, 0.5, 0.75, 0.999)
probs <- c(
     min(df$effectiveness_lo),
     mean(df$effectiveness_lo),
     median(df$effectiveness),
     mean(df$effectiveness_hi),
     max(df$effectiveness_hi)
)

prm <- get_beta_params(quantiles=quants, probs=probs)
#prm <- get_beta_params(probs=c(0.527, 0.447))
samps <- rbeta(1000, shape1 = prm$shape1, shape2 = prm$shape2)
ci <- quantile(samps, probs = c(0.025, 0.975))





p1 <-
     ggplot() +
     geom_ribbon(data = prediction_month, aes(x = month, ymin = predicted_lo, ymax = predicted_hi), fill = "grey", alpha = 0.4) +  # Shaded ribbon for confidence intervals
     geom_line(data = prediction_month, aes(x = month, y = predicted), color = "grey20", size = 1.25) +  # Line for predicted values
     geom_rect(aes(xmin = 0, xmax = 36, ymin = ci[1], ymax = ci[2]), fill = "dodgerblue", alpha = 0.1) +  # Shaded area from 24 to 48 months
     geom_segment(aes(x = 0, xend = 36, y = mean(samps)), linetype = "solid", linewidth=1.5, color = "dodgerblue") +  # Horizontal line at mean effectiveness
     geom_point(data = df, aes(x = month, y = effectiveness), color = "red", size = 5) +  # Points for original data
     geom_segment(data = df, aes(x = month_min, xend = month_max, y = effectiveness), color = "red", size=1.25) +  # Vertical error bars
     geom_segment(data = df, aes(x = month, y = effectiveness_lo, yend = effectiveness_hi), color = "red", size=1.25) +  # Horizontal error bars
     geom_vline(xintercept = 36, linetype = "dashed", color = "black") +  # Vertical line at 36 months
     labs(x = "Years after vaccination", y = "Effectiveness of One Dose OCV") +
     ggtitle('A') +
     theme_classic(base_size = 18) +
     theme(panel.grid.minor = element_blank(),  # Remove minor gridlines
           panel.grid.major.y = element_line(color='grey70', size=0.1),
           axis.title.x = element_text(margin = margin(t = 15)),  # Increase space between x-axis and x-axis label
           axis.title.y = element_text(margin = margin(r = 15)),
           plot.margin = unit(c(0.1, 0, 0.1, 0.1), "inches")) +
     scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
     scale_x_continuous(limits = c(0, 8*12), labels = 1:10, breaks = 12 * (1:10), expand = c(0, 0))  # Yearly labels and breaks



df_samples <- data.frame(x = samps)


p2 <-
     ggplot(df_samples, aes(x = x)) +
     geom_histogram(aes(y = ..density..), bins = 35, fill = "grey50", color='white', alpha = 0.7) +
     annotate("rect", xmin = ci[1], xmax = ci[2], ymin = -Inf, ymax = Inf, fill = "dodgerblue", alpha = 0.2, color = NA) +
     geom_vline(xintercept = mean(samps), linetype = "solid", linewidth=1, size=1.5, color = "dodgerblue") +  # Vertical line at 36 months
     stat_function(fun = dbeta, args = list(shape1 = prm$shape1, shape2 = prm$shape2), color = "black", size = 0.8) +
     labs(y = "Density") +
     theme_classic(base_size = 18) +
     ggtitle('B') +
     theme(panel.grid.minor = element_blank(),  # Remove minor gridlines
           panel.grid.major.y = element_line(color='grey70', size=0.1),
           axis.title.y = element_blank(),  # Increase space between x-axis and x-axis label
           axis.title.x = element_text(margin = margin(t = 15)),
           axis.ticks = element_line(),
           axis.text.y = element_blank(),
           plot.margin = unit(c(0.1, 0.1, 0.1, 0), "inches")) +
     scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
     scale_y_continuous(expand = c(0, 0.01)) +
     coord_flip()

png(filename = "./figures/vaccine_effectiveness.png", width = 3000, height = 1500, units = "px", res=300)
cowplot::plot_grid(p1, p2, nrow=1, rel_widths = c(3,1), align = "vh", axis='tb')
dev.off()




# Immunity due to natural infection


