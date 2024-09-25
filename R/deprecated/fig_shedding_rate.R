
set.seed(123)

psi <- runif(100, min = 0, max = 1)
psi_transform <- 1 / (1 + (1 - psi))

days_min <- 3
days_max <- 90

delta_min <- 1/days_min
delta_max <- 1/days_max
decay_rate <- delta_min + psi * (delta_max - delta_min)

png(filename = "./figures/shedding_rate.png", width = 1800, height = 1800, units = "px", res=300)

plot(psi, 1 - psi,
     xlab = expression("Climate driven environmental suitability (" * psi[jt] * ")"),
     ylab = expression("Suitability dependent decay rate (" * delta[jt] * ")"),
     pch = 19, col = "black",
     xlim = c(0, 1), ylim = c(0, 1.1),
     bty = "n")

lines(sort(psi), 1 - sort(psi), col = "#377EB8", lwd = 3, type = "l")

points(psi, 1 - psi_transform, pch = 19)
lines(sort(psi), 1 - sort(psi_transform), col='#E41A1C', lwd=3)

points(psi, decay_rate, pch = 19)
lines(psi, decay_rate, col='#4DAF4A', lwd=3)

legend("topright", legend = c(expression(delta[jt] == 1-psi[jt]),
                              expression(delta[jt] == 1-frac(1, 1 + (1 - psi[jt]))),
                              expression(delta[jt] == delta[min] + psi * (delta[max] - delta[min]))),
       col = c("#377EB8", "#E41A1C", "#4DAF4A"), lty = 1, pch = 19, lwd = 2, cex = 1.2, bty = "n")

text(x = 0, y = 1.01, "0 days", pos = 4, col = "#377EB8", cex = 1)
text(x = 0, y = 0.54, "2 days", pos = 4, col = "#E41A1C", cex = 1)
text(x = 0, y = 0.36, labels = paste0(days_min, " days"), pos = 4, col = "#4DAF4A", cex = 1)
text(x = 0.75, y = 0, labels = paste0(days_max, " days"), pos = 4, col = "#4DAF4A", cex = 1)

dev.off()
