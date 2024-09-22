
library(minpack.lm)
library(ggplot2)
library(scales)
library(cowplot)
library(propvacc)
library(latex2exp)

# Data are from Malembaka et al 2024: https://www.thelancet.com/journals/laninf/article/PIIS1473-3099(23)00742-9/fulltext

# Create the initial dataframe with some known values
df <- data.frame(
     day = c(60,              # Azman 2016
             mean(c(7, 180)), # Qadri 2016
             mean(c(7, 730)), # Qadri 2018
             mean(c(30*12, 30*17)),  # Malembaka 2024
             mean(c(30*24, 30*36))), # Malembaka 2024
     effectiveness = c(0.873, 0.4, 0.39, 0.527, 0.447),
     effectiveness_hi = c(0.99, 0.6, 0.52, 0.674, 0.594),
     effectiveness_lo = c(0.702, 0.11, 0.23, 0.314, 0.248),
     day_min = c(NA, 7, 7, 30*12, 30*24),
     day_max = c(NA, 180, 730, 30*17, 30*36),
     source = c('Azman et al (2016)', 'Qadri et al (2016)', 'Qadri et al (2018)', 'Malembaka et al (2024)', 'Malembaka et al (2024)')
)


proportional_decay_function <- function(par, x) {
     a <- par[1]
     b <- par[2]
     a * (1 - b) ^ x
}

objective_function <- function(par) {
     residuals <- df$effectiveness - proportional_decay_function(par, df$day)
     residuals
}


starting_values <- c(a = 0.7, b = 0.001)  # a is the initial immune proportion, b is the decay rate

fit <- nls.lm(par = starting_values,
              fn = objective_function,
              upper = c(1, 1),
              lower = c(0, 0),
              control = nls.lm.control(maxiter = 1000)  # Increase max iterations to 10000
)

s <- summary(fit)
se <- s$coefficients[,"Std. Error"]

fitted_parameters <- fit$par
fitted_parameters_hi <- c(fit$par[1]+1.96*se[1], fit$par[2])
fitted_parameters_lo <- c(fit$par[1]-1.96*se[1], fit$par[2])
print(fitted_parameters)

prediction <- data.frame(day = seq(0, 365*10, by = 1))
prediction$predicted <- proportional_decay_function(fitted_parameters, prediction$day)
prediction$predicted_lo <- proportional_decay_function(fitted_parameters_lo, prediction$day)
prediction$predicted_hi <- proportional_decay_function(fitted_parameters_hi, prediction$day)
head(prediction)


# Get beta distribution for vaccine effectiveness
quants <- c(0.02775, 0.5, 0.974)
probs <- c(fitted_parameters_lo[1], fitted_parameters[1], fitted_parameters_hi[1])
prm <- get_beta_params(quantiles=quants, probs=probs)
samps <- rbeta(1000, shape1 = prm$shape1, shape2 = prm$shape2)
ci <- quantile(samps, probs = c(0.025, 0.975))


p1 <-
     ggplot() +
     geom_ribbon(data = prediction, aes(x = day, ymin = predicted_lo, ymax = predicted_hi), fill = "grey", alpha = 0.3) +  # Shaded ribbon for confidence intervals
     geom_line(data = prediction, aes(x = day, y = predicted), color = "black", size = 1.25) +  # Line for predicted values
     geom_hline(aes(yintercept = fitted_parameters[1]), linetype = "solid", linewidth=0.5, color = "grey30") +  # Horizontal line at mean effectiveness
     geom_hline(aes(yintercept = fitted_parameters_lo[1]), linetype = "dashed", linewidth=0.25, color = "grey40") +  # Horizontal line at mean effectiveness
     geom_hline(aes(yintercept = fitted_parameters_hi[1]), linetype = "dashed", linewidth=0.25, color = "grey40") +  # Horizontal line at mean effectiveness
     geom_point(data = df, aes(x = day, y = effectiveness, color = source), size = 5) +  # Points for original data
     geom_segment(data = df, aes(x = day_min, xend = day_max, y = effectiveness, color = source), size = 1.25) +  # Vertical error bars
     geom_segment(data = df, aes(x = day, y = effectiveness_lo, yend = effectiveness_hi, color = source), size = 1.25) +  # Horizontal error bars
     annotate("text", x = 365 * 8.25, y = 0.45, label = bquote(omega == .(sprintf("%.5f", fitted_parameters['b']))), color = "black", size = 5) +
     labs(x = "Years after vaccination", y = "Effectiveness of One Dose OCV") +
     ggtitle('A') +
     theme_classic(base_size = 18) +
     theme(panel.grid.minor = element_blank(),  # Remove minor gridlines
           panel.grid.major.y = element_blank(),
           axis.title.x = element_text(margin = margin(t = 15)),  # Increase space between x-axis and x-axis label
           axis.title.y = element_text(margin = margin(r = 15)),
           plot.margin = unit(c(0.1, 0.3, 0.1, 0), "inches"),
           legend.position = c(0.99, 0.975),  # Place legend inside the plot (top-right corner)
           legend.justification = c("right", "top"),  # Align the legend to the right-top
           legend.title = element_blank(),  # Remove the legend title
           legend.text = element_text(size = 10),
           legend.background = element_blank()) +  # Make the legend text smaller
     scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
     scale_x_continuous(limits = c(0, 10*365), labels = 1:10, breaks = 365 * (1:10), expand = c(0, 0)) +  # Yearly labels and breaks
     scale_color_manual(values = c('Azman et al (2016)' = '#DC143C',
                                   'Qadri et al (2016)' = '#9370DB',
                                   'Qadri et al (2018)' = '#FF8C00',
                                   'Malembaka et al (2024)' = '#32CD32'))  # Manually set colors for each source



df_samples <- data.frame(x = samps)

p2 <-
     ggplot(df_samples, aes(x = x)) +
     geom_histogram(aes(y = ..density..), bins = 35, fill = "lightblue", color='white', alpha = 0.7) +
     stat_function(fun = dbeta, args = list(shape1 = prm$shape1, shape2 = prm$shape2), color = "black", size = 0.8) +
     geom_vline(aes(xintercept = fitted_parameters[1]), linetype = "solid", linewidth=0.5, color = "grey30") +  # Horizontal line at mean effectiveness
     geom_vline(aes(xintercept = fitted_parameters_lo[1]), linetype = "dashed", linewidth=0.25, color = "grey40") +  # Horizontal line at mean effectiveness
     geom_vline(aes(xintercept = fitted_parameters_hi[1]), linetype = "dashed", linewidth=0.25, color = "grey40") +  # Horizontal line at mean effectiveness
     labs(x = expression("Initial one dose OCV effectiveness (" * phi * ")"), y = "Density") +
     theme_classic(base_size = 18) +
     ggtitle('B') +
     theme(panel.grid.minor = element_blank(),  # Remove minor gridlines
           panel.grid.major.y = element_blank(),
           #axis.title.y = element_blank(),  # Increase space between x-axis and x-axis label
           axis.title.x = element_text(margin = margin(t = 15)),
           axis.ticks = element_line(),
           #axis.text.y = element_blank(),
           plot.margin = unit(c(0.1, 0, 0.1, 0.1), "inches")) +
     scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
     scale_y_continuous(breaks = 0:5, expand = c(0, 0.01)) +
     coord_flip()


combo <- cowplot::plot_grid(p1, p2, nrow=1, rel_widths = c(3,1.1), align = "vh", axis='tb')
combo

png(filename = "./figures/vaccine_effectiveness.png", width = 3000, height = 1500, units = "px", res=300)
combo
dev.off()
