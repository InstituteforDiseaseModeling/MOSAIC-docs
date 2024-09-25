
library(ggplot2)
library(rnaturalearth)
library(sf)
library(dplyr)
library(stringr)


cholera_outbreak_countries_10yrs <- c(
     "Nigeria", "Democratic Republic of the Congo", "Somalia", "Kenya",
     "Ethiopia", "Mozambique", "Zambia", "South Sudan", "Malawi",
     "Uganda", "Zimbabwe", "Tanzania", "Cameroon", "Niger", "Burundi",
     "Angola", "Chad", "Ghana", "Sierra Leone", "Sudan", "Madagascar"
)

cholera_outbreak_countries_5yrs <- c(
     "Nigeria", "Democratic Republic of the Congo", "Somalia", "Kenya",
     "Ethiopia", "Mozambique", "Zambia", "South Sudan", "Malawi",
     "Uganda", "Zimbabwe", "Tanzania", "Cameroon", "Niger", "Burundi"
)

#pal <- c("#fcecae", "#aea9bb", "#40376c")
#pal <- c("#fbf2c4", "#b8cdab", "#74a892")
#pal <- c("#f9e09d", "#a3c380", "#4f8362")
#pal <- c("#fbe8b4", "#a3c380", "#4f8362")
#pal <- c("#fdf0d5", "#c5d8b6", "#4f8362")
pal <- c("#fef6e1", "#c5d8b6", "#4f8362")

africa <- ne_countries(scale = "medium", continent = "Africa", returnclass = "sf")
SSA <- africa[africa$region_wb == "Sub-Saharan Africa",]
SSA_outbreak_5yr <- africa[africa$name_long %in% cholera_outbreak_countries_5yrs,]
SSA_outbreak_10yr <- africa[africa$name_long %in% cholera_outbreak_countries_10yrs,]

p1 <- ggplot(data = africa) +
     geom_sf(fill = "white", color = "black") +
     geom_sf(data = SSA, aes(fill = "SSA"), color = "black") +
     geom_sf(data = SSA_outbreak_10yr, aes(fill = "SSA_outbreak_10yr"), color = "black", linetype = "solid", size = 0.8) +
     geom_sf(data = SSA_outbreak_5yr, aes(fill = "SSA_outbreak_5yr"), color = "black", linetype = "solid", size = 0.8) +
     scale_fill_manual(values = pal,
                       labels = c( "Sub-Saharan Africa",
                                   str_wrap("Cholera outbreak in past 10 years", 18),
                                   str_wrap("Cholera outbreak in past 5 years", 18))) +
     theme_minimal(base_size = 13) +
     theme(
          panel.grid.major = element_line(size = 0.25),
          legend.position = "right",
          legend.title = element_blank(),
          legend.text = element_text(size = 10.5),
          legend.key.height = unit(1.25, "cm"),
          legend.key.width = unit(0.75, "cm"),
          plot.margin = unit(c(0.25, 0.25, 0.25, 0.25), "inches")
     )

p1

png(filename = "./figures/africa_map.png", width = 2000, height = 1600, units = "px", res=300)
p1
dev.off()


