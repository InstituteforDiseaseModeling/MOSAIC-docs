
library(propvacc)
library(ggplot2)
library(cowplot)
library(grid)
library(stringr)
library(latex2exp)

prm_all <- get_beta_params(quantiles = c(0.0275, 0.5, 0.975),
                           probs = c(0.24, 0.52, 0.8))

samps <- rbeta(5000, shape1 = prm_all$shape1, shape2 = prm_all$shape2)
ci <- quantile(samps, probs = c(0.025, 0.5, 0.975))


df_samples <- data.frame(x = samps)

x_vals <- seq(0, 1, length.out = 5000)
y_vals <- dbeta(x_vals, prm_all$shape1, prm_all$shape2)
df_beta <- data.frame(x = x_vals, y = y_vals)

txt <- "Low estimate: All settings"

p1 <-
     ggplot(df_samples, aes(x = x)) +
     geom_histogram(aes(y = ..density..), bins = 50, fill = "#3498db", color='white', alpha = 0.5) +
     geom_line(data = df_beta, aes(x = x, y = y), color = "black", size = 1) +
     geom_vline(xintercept = ci[c(1,3)], linetype = "dashed", color = "grey20", size = 0.25) +
     geom_vline(xintercept = ci[2], linetype = "solid", color = "grey20", size = 0.5) +
     labs(title="A", y = "Density", x = "") +
     scale_x_continuous(limits = c(0, 1.3), breaks=seq(0, 1, 0.25), expand=c(0,0)) +
     scale_y_continuous(expand=c(0.005, 0.005)) +
     theme_minimal(base_size = 12) +
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
          grob = textGrob(str_wrap(txt, 15), gp = gpar(col = "#3498db", fontsize = 10)),
          xmin = 1.2, xmax = 1.2, ymin = 1.5, ymax = 1.5
     )


prm_stratum_high_outbreak <- get_beta_params(quantiles = c(0.0275, 0.5, 0.975),
                                             probs = c(0.40, 0.78, 0.99))

samps <- rbeta(5000, shape1 = prm_stratum_high_outbreak$shape1, shape2 = prm_stratum_high_outbreak$shape2)
ci <- quantile(samps, probs = c(0.025, 0.5, 0.975))


df_samples <- data.frame(x = samps)

x_vals <- seq(0, 1, length.out = 5000)
y_vals <- dbeta(x_vals, prm_stratum_high_outbreak$shape1, prm_stratum_high_outbreak$shape2)
df_beta <- data.frame(x = x_vals, y = y_vals)

txt <- "High estimate: During outbreaks"

p2 <-
     ggplot(df_samples, aes(x = x)) +
     geom_histogram(aes(y = ..density..), bins = 50, fill = "#c0392b", color='white', alpha = 0.5) +
     geom_line(data = df_beta, aes(x = x, y = y), color = "black", size = 1) +
     geom_vline(xintercept = ci[c(1,3)], linetype = "dashed", color = "grey20", size = 0.25) +
     geom_vline(xintercept = ci[2], linetype = "solid", color = "grey20", size = 0.5) +
     labs(title="B", y = "Density", x = expression("Proportion of suspected cases that are true infections (" * rho * ")")) +
     scale_x_continuous(limits = c(0, 1.3), breaks=seq(0, 1, 0.25), expand=c(0,0)) +
     scale_y_continuous(expand=c(0.005, 0.005)) +
     theme_minimal(base_size = 12) +
     theme(
          legend.position = "none",
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color='grey80', size=0.25),
          panel.grid.minor = element_blank(),
          axis.title.x = element_text(margin = margin(t = 25), hjust=-0.1),
          axis.title.y = element_text(margin = margin(r = 25)),
          plot.margin = unit(c(0, 0.25, 0.25, 0), "inches")
     ) +
     annotation_custom(
          grob = textGrob(str_wrap(txt, 18), gp = gpar(col = "#c0392b", fontsize = 10)),
          xmin = 1.2, xmax = 1.2, ymin = 1.5, ymax = 1.5
     )

combo <- plot_grid(p1, p2, ncol = 1, align = 'vh')
combo

png(filename = "./figures/suspected_cases.png", width = 2000, height = 1500, units = "px", res=300)
combo
dev.off()
