library(countrycode)

convert_country_to_iso3 <- function(country_names) {
     iso3_codes <- countrycode(country_names, origin = "country.name", destination = "iso3c", warn = TRUE)
     return(iso3_codes)
}

convert_iso3_to_country <- function(iso3_codes) {
     country_names <- countrycode(iso3_codes, origin = "iso3c", destination = "country.name")
     return(country_names)
}



afro_iso_codes <- c(
     "DZA", "AGO", "BEN", "BWA", "BFA", "BDI", "CPV", "CMR", "CAF", "TCD",
     "COM", "COG", "COD", "CIV", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB",
     "GHA", "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT",
     "MUS", "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE",
     "SOM", "ZAF", "SSD", "TGO", "UGA", "TZA", "ZMB", "ZWE"
)

d <- read.csv(file.path(getwd(), "data/cholera_country_weekly.csv"))

d$iso_code <- convert_country_to_iso3(d$country)
d$country <- convert_iso3_to_country(d$iso_code)

d <- d[d$iso_code %in% afro_iso_codes,]


d$country[d$iso_code == 'COD'] <- "Democratic Republic of Congo"
d$country[d$iso_code == 'COG'] <- "Congo"

d <- d[order(d$year, d$week, d$country),]

colnames(d)[colnames(d) == "cases_by_week"] <- 'cases'
colnames(d)[colnames(d) == "deaths_by_week"] <- 'deaths'

d <- d[,c("country", "iso_code", "week", "cases", "deaths")]

head(d)



write.csv(d, file=file.path(getwd(), "data/cholera_country_weekly_processed.csv"), row.names = FALSE)

