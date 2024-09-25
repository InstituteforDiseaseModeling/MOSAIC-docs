
df <- data.frame(
     mean     = c(0.57,        # Nelson et al (2009)
                  0.25,          # Lueng and Matrajt (2021)
                  NA,          # Harris et al (2012)
                  0.238,       # Finger et al (2024)
                  0.213,       # Jackson et al (2013)
                  0.204,       # Bart et al (1970)
                  0.371,       # Bart et al (1970)
                  0.184,     # Harris et al (2008)
                  0.0005996  # Hegde et al (2023)
     ),
     ci_lo    = c(NA,          # Nelson et al (2009)
                  NA,           # Lueng and Matrajt (2021)
                  0.2,         # Harris et al (2012)
                  0.227,        # Finger et al (2024)
                  0.194,       # Jackson et al (2013)
                  NA,          # Bart et al (1970)
                  NA,          # Bart et al (1970)
                  0.256,     # Harris et al (2008)
                  0.0004998  # Hegde et al (2023)
     ),
     ci_hi    = c(NA,          # Nelson et al (2009)
                  NA,        # Lueng and Matrajt (2021)
                  0.6,         # Harris et al (2012)
                  0.25,       # Finger et al (2024)
                  0.231,       # Jackson et al (2013)
                  NA,          # Bart et al (1970)
                  NA,          # Bart et al (1970)
                  0.112,     # Harris et al (2008)
                  0.0007994  # Hegde et al (2023)
     ),
     source   = c("Nelson et al (2009)",           # Nelson et al (2009)
                  "Lueng & Matrajt (2021)",      # Lueng and Matrajt (2021)
                  "Harris et al (2012)",           # Harris et al (2012)
                  "Finger et al (2024)",           # Finger et al (2024)
                  "Jackson et al (2013)",          # Jackson et al (2013)
                  "Bart et al (1970)",             # Bart et al (1970)
                  "Bart et al (1970)",             # Bart et al (1970)
                  "Harris et al (2008)",           # Harris et al (2008)
                  "Hegde et al (2024)"             # Hegde et al (2023)
     ),
     location = c(NA,                            # Nelson et al (2009)
                  NA,                            # Lueng and Matrajt (2021)
                  "Endemic regions",             # Harris et al (2012)
                  "Haiti",                       # Finger et al (2024)
                  "Haiti",                       # Jackson et al (2013)
                  "Pakistan",                    # Bart et al (1970)
                  "Pakistan",                    # Bart et al (1970)
                  "Bangladesh",                  # Harris et al (2008)
                  "Bangladesh"                   # Hegde et al (2023)
     ),
     year     = c(2009,        # Nelson et al (2009)
                  2021,        # Lueng and Matrajt (2021)
                  2012,        # Harris et al (2012)
                  2024,        # Finger et al (2024)
                  2013,        # Jackson et al (2013)
                  1970,        # Bart et al (1970)
                  1970,        # Bart et al (1970)
                  2008,        # Harris et al (2008)
                  2023         # Hegde et al (2023)
     ),
     note     = c("Review",                                     # Nelson et al (2009)
                  "Review",                                     # Lueng and Matrajt (2021)
                  "Review",                                     # Harris et al (2012)
                  "Sero-survey and clinical data",              # Finger et al (2024)
                  "Cross-sectional sero-survey",                # Jackson et al (2013)
                  "Sero-survey during epidemic; El Tor Ogawa strain",      # Bart et al (1970)
                  "Sero-survey during epidemic; Inaba strain",         # Bart et al (1970)
                  "Household cohort",                           # Harris et al (2008)
                  "Sero-survey and clinical data"               # Hegde et al (2023)
     ),
     note2   = c("",                                     # Nelson et al (2009)
                 "",                                     # Lueng and Matrajt (2021)
                 "",                                     # Harris et al (2012)
                 "",              # Finger et al (2024)
                 "",                # Jackson et al (2013)
                 "El Tor Ogawa",      # Bart et al (1970)
                 "Inaba",         # Bart et al (1970)
                 "",                           # Harris et al (2008)
                 ""               # Hegde et al (2023)
     )
)


write.csv(df, file="./data/summary_symptomatic_cases.csv")





# Make a Beta distribution to simulate sigma (proportion of infections that are symptomatic)

quantiles <- c(0.0001, 0.0275, 0.25, 0.5, 0.75, 0.975, 0.9999)

probs <- c(min(df$ci_lo, na.rm=T),
           quantile(df$ci_lo, probs=0.0275, na.rm=T),
           quantile(df$ci_lo, probs=0.25, na.rm=T),
           mean(df$mean, na.rm=T),
           quantile(df$ci_hi, probs=0.75, na.rm=T),
           quantile(df$ci_hi, probs=0.975, na.rm=T),
           max(df$ci_hi, na.rm=T))

prm <- get_beta_params(quantiles=quantiles, probs=probs)

samps <- rbeta(1000, shape1 = prm$shape1, shape2 = prm$shape2)
ci <- quantile(samps, probs = c(0.025, 0.5, 0.975))
df_samples <- data.frame(x = samps)

x_vals <- seq(0, 1, length.out = 1000)
y_vals <- dbeta(x_vals, prm$shape1, prm$shape2)
df_beta <- data.frame(x = x_vals, y = y_vals)

p1 <-
     ggplot(df_samples, aes(x = x)) +
     geom_histogram(aes(y = ..density..), bins = 35, fill = "#1B4F72", color='white', alpha = 0.5) +
     #stat_function(fun = dbeta, args = list(shape1 = prm$shape1, shape2 = prm$shape2), color = "black", size = 1) +
     geom_line(data = df_beta, aes(x = x, y = y), color = "black", size = 1) +  # Plot Beta distribution
     geom_vline(xintercept = ci[c(1,3)], linetype = "dashed", color = "grey20", size = 0.25) +
     geom_vline(xintercept = ci[2], linetype = "dashed", color = "grey20", size = 0.25) +
     labs(title = "A", x = "", y = "") +
     scale_x_continuous(limits = c(-0.02, 1.25), breaks=seq(0, 1, 0.25), expand=c(0,0)) +
     scale_y_continuous(expand=c(0.005, 0.005)) +
     theme_minimal(base_size = 14) +
     theme(
          legend.position = "none",
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color='grey80', size=0.25),
          panel.grid.minor = element_blank(),
          axis.title.x = element_text(margin = margin(t = 30), hjust=0.3),
          plot.margin = unit(c(0.25, 0.25, 0, 0), "inches")
     )



# How does this compare with previous studies?



#pal <- c("#1B4F72", "#239B56", "#884EA0", "#D35400", "#7D3C98", "#566573", "#CD6155", "#5D6D7E", "#AF601A")
pal <- c("#274001", "#828a00", "#D35400", "#7D3C98", "#1B4F72", "#a62f03", "#400d01", "#4d8584")

p2 <-
     ggplot(df, aes(x = source, y = mean, color = source)) +
     geom_hline(yintercept = ci[c(1,3)], linetype = "dashed", color = "grey20", size = 0.25) +
     geom_hline(yintercept = ci[2], linetype = "dashed", color = "grey20", size = 0.25) +
     geom_rect(aes(xmin = as.numeric(factor(source)) - 0.2,
                   xmax = as.numeric(factor(source)) + 0.2,
                   ymin = ci_lo, ymax = ci_hi,
                   fill = source),
               alpha = 0.3, color=NA) +
     geom_rect(aes(xmin = as.numeric(factor(source)) - 0.2,
                   xmax = as.numeric(factor(source)) + 0.2,
                   ymin = mean-0.0025, ymax = mean+0.0025, fill = source)) +
     geom_text(aes(label = note2), vjust = -1, hjust = 1.25, size=3) +
     annotate("text", x = 1, y = 1.02, hjust = 0, vjust = 0.5,  label = "Pakistan", color = pal[1], alpha=0.7, size = 3.5) +
     annotate("text", x = 2, y = 1.02, hjust = 0, vjust = 0.5, label = "Haiti", color = pal[2], alpha=0.7, size = 3.5) +
     annotate("text", x = 3, y = 1.02, hjust = 0, vjust = 0.5, label = "Bangladesh", color = pal[3], alpha=0.7, size = 3.5) +
     annotate("text", x = 4, y = 1.02, hjust = 0, vjust = 0.5, label = "Endemic regions", color = pal[4], alpha=0.7, size = 3.5) +
     annotate("text", x = 5, y = 1.02, hjust = 0, vjust = 0.5, label = "Bangladesh", color = pal[5], alpha=0.7, size = 3.5) +
     annotate("text", x = 6, y = 1.02, hjust = 0, vjust = 0.5, label = "Haiti", color = pal[6], alpha=0.7, size = 3.5) +
     labs(title = "B", x = "", y = "Proportion of infections that are symptomatic") +
     scale_fill_manual(values = pal) +
     scale_color_manual(values = pal) +
     scale_y_continuous(limits = c(-0.02, 1.25), breaks=seq(0, 1, 0.25), expand=c(0,0)) +
     theme_minimal(base_size = 14) +
     theme(
          legend.position = "none",
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color='grey80', size=0.25),
          panel.grid.minor = element_blank(),
          axis.title.x = element_text(margin = margin(t = 30), hjust=0.3),
          axis.title.y = element_text(margin = margin(r = 15)),
          plot.margin = unit(c(0, 0.25, 0.25, 0), "inches")
     ) +
     coord_flip()


combo <- plot_grid(p1, p2, ncol = 1, rel_heights = c(1, 1.5), align='vh')
combo


png(filename = "./figures/proportion_symptomatic.png", width = 2400, height = 2400, units = "px", res=300)
combo
dev.off()




#########################

quantiles <- c(0.0001, 0.0275, 0.25, 0.5, 0.75, 0.975, 0.9999)

sel <- !(df$source == 'Hegde et al (2024)')

probs <- c(min(df$ci_lo[sel], na.rm=T),
           quantile(df$ci_lo[sel], probs=0.0275, na.rm=T),
           quantile(df$ci_lo[sel], probs=0.25, na.rm=T),
           mean(df$mean[sel], na.rm=T),
           quantile(df$ci_hi[sel], probs=0.75, na.rm=T),
           quantile(df$ci_hi[sel], probs=0.975, na.rm=T),
           max(df$ci_hi[sel], na.rm=T))

prm <- get_beta_params(quantiles=quantiles, probs=probs)
x_vals <- seq(0, 1, length.out = 100)
y_vals <- dbeta(x_vals, prm$shape1, prm$shape2)
b <- data.frame(x = x_vals, y = y_vals)

ggplot(b, aes(x = x, y = y)) +
     geom_area(fill = "grey", alpha = 0.2) +  # Fill the area under the curve
     geom_line(size = 1.5) +  # Line width similar to lwd=2
     geom_vline(xintercept = prm$shape1/(sum(unlist(prm))), linetype = "dashed", color = "black", size = 0.5) +
     labs(x = "", y = "Probability density") +
     scale_x_continuous(limits = c(-0.02, 1.25), breaks=seq(0, 1, 0.25), expand=c(0,0)) +
     scale_y_continuous(expand=c(0.005, 0.005)) +
     theme_minimal(base_size = 14) +
     theme(
          legend.position = "none",
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(color='grey80', size=0.25),
          panel.grid.minor = element_blank(),
          axis.title.x = element_text(margin = margin(t = 30), hjust=0.3),
          axis.title.y = element_text(margin = margin(r = 30)),
          plot.margin = unit(c(0.3, 0.3, 0.3, 0), "inches")
     )






#################


sel <- !(df$source == 'Hegde et al (2024)')

quantiles <- c(0.0001, 0.0275,0.25, 0.5, 0.75, 0.975, 0.9999)

par(mfrow=c(2,2))

probs <- c(
     min(df$ci_lo, na.rm=T),
     quantile(df$ci_lo, probs=0.0275, na.rm=T),
     quantile(df$ci_lo, probs=0.25, na.rm=T),
     mean(df$mean, na.rm=T),
     quantile(df$ci_hi, probs=0.75, na.rm=T),
     quantile(df$ci_hi, probs=0.975, na.rm=T),
     max(df$ci_hi, na.rm=T)
)

prm <- get_beta_params(quantiles=quantiles, probs=probs)
curve(dbeta(x, prm$shape1, prm$shape2), 0, 1, lwd=2,
      xlab="Proportion symptomatic", ylab='Probability density')
#abline(v=probs, col='blue', lty=2)
abline(v=probs[3], col='blue')


probs <- c(
     min(df$ci_lo[sel], na.rm=T),
     quantile(df$ci_lo[sel], probs=0.0275, na.rm=T),
     quantile(df$ci_lo[sel], probs=0.25, na.rm=T),
     mean(df$mean[sel], na.rm=T),
     quantile(df$ci_hi[sel], probs=0.75, na.rm=T),
     quantile(df$ci_hi[sel], probs=0.975, na.rm=T),
     max(df$ci_hi[sel], na.rm=T)
)

prm <- get_beta_params(quantiles=quantiles, probs=probs)
curve(dbeta(x, prm$shape1, prm$shape2), 0, 1, lwd=2,
      xlab="Proportion symptomatic", ylab='Probability density')
abline(v=probs, col='blue')




prm <- get_beta_params(mu=mean(df$mean, na.rm=T), sigma=var(df$mean, na.rm=T))
curve(dbeta(x, prm$shape1, prm$shape2), 0, 1, lwd=2,
      xlab="Proportion symptomatic", ylab='Probability density')
abline(v=mean(df$mean, na.rm=T), col='red')


prm <- get_beta_params(mu=mean(df$mean[sel], na.rm=T), sigma=var(df$mean[sel], na.rm=T))
curve(dbeta(x, prm$shape1, prm$shape2), 0, 1, lwd=2,
      xlab="Proportion symptomatic", ylab='Probability density')
abline(v=mean(df$mean[sel], na.rm=T), col='red')

