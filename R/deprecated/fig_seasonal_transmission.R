
library(ggplot2)
library(RColorBrewer)
library(latex2exp)

beta_t <- function(
          beta_0, # base transmission ratet,
          t,      # time step(s)
          a,      # amplitude
          p,      # periodic cycles
          x       # phase
){
     beta_0 * (1 - a * cos(((pi*t)/p) - x))
}

y <- beta_t(t=1:52, beta_0=1, a=0.3, p=26, x=4)
df <- data.frame(t=1:52, beta=y)
pal <- brewer.pal(9, 'Set1')

p1 <- ggplot(data=df) +
     annotate('rect', xmin=1, xmax=14, ymin=-Inf, ymax=Inf, alpha=0.3, fill='dodgerblue') +
     geom_point(aes(x=t, y=beta), size=3) +
     geom_line(aes(x=t, y=beta), size=0.8) +
     geom_hline(yintercept=1, linetype=2, color=pal[1]) +
     annotate('text', x=33, y=1.04, label=TeX('$\\beta_{j0}^{hum}$'), size=5, col=pal[1]) +
     ggtitle('Temporally forced transmission rate') +
     ylab(TeX('Transmission rate at time $t$ ($\\beta_{jt}^{hum}$)')) + xlab('Week of year') +
     theme_classic() +
     theme(axis.text.x=element_text(size=10),
           axis.text.y=element_text(size=10),
           axis.title.x=element_text(size=12, margin=margin(t=15)),
           axis.title.y=element_text(size=12, margin=margin(r=15)))

p1

png(filename = "./figures/seasonal_transmission.png", width = 2000, height = 1250, units = "px", res=300)
p1
dev.off()


