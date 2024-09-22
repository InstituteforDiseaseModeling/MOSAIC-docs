library(shiny)
library(ggplot2)
library(RColorBrewer)
library(shinyWidgets)

cholera_data <- read.csv(file.path(getwd(), "data/who_global_annual/processed/who_global_1949_2024.csv"), stringsAsFactors = FALSE)

afro_totals <- aggregate(cbind(cases_total, deaths_total) ~ year, data = cholera_data, sum, na.rm = TRUE)
afro_totals$region <- "AFR0"
afro_totals$country <- "AFRO Region"
afro_totals$iso_code <- "AFRO"
afro_totals$cases_imported <- NA
afro_totals$cfr <- afro_totals$deaths_total / afro_totals$cases_total

afro_totals$cfr_lo <- mapply(function(x, n) binom.test(x, n)$conf.int[1], afro_totals$deaths_total, afro_totals$cases_total)
afro_totals$cfr_hi <- mapply(function(x, n) binom.test(x, n)$conf.int[2], afro_totals$deaths_total, afro_totals$cases_total)

cholera_data <- rbind(cholera_data, afro_totals)

country_choices <- c("AFRO Region", sort(unique(cholera_data$country[cholera_data$country != "AFRO Region"])))


ui <- fluidPage(
     titlePanel("Cholera Cases, Deaths, and CFR in AFRO Countries (1970 - 2024)"),


     sidebarLayout(
          sidebarPanel(

               radioButtons("metric", "Select Metric:",
                            choices = c("Cases" = "cases_total", "Deaths" = "deaths_total", "CFR" = "cfr"),
                            selected = "cases_total"),

               checkboxGroupInput("selected_countries", "Select Countries:",
                                  choices = c("All", country_choices),
                                  selected = "AFRO Region"),

               width = 2
          ),

          mainPanel(

               uiOutput("countryPlots"),
               width = 10
          )
     )
)

server <- function(input, output, session) {

     pal <- colorRampPalette(RColorBrewer::brewer.pal(9, "Set1"))(48)
     pal <- adjustcolor(pal, 5)

     full_years <- as.character(seq(1970, 2024, by = 1))

     observe({

          if ("All" %in% input$selected_countries) {
               selected_countries <- country_choices
               updateCheckboxGroupInput(session, "selected_countries", selected = c("All", country_choices))
          } else {
               selected_countries <- input$selected_countries
               if (length(selected_countries) != length(country_choices)) {
                    updateCheckboxGroupInput(session, "selected_countries", selected = selected_countries)
               }
          }

          y_var <- input$metric
          if (y_var == "cfr") {
               global_y_max <- 1
          } else {
               global_y_max <- max(cholera_data[[y_var]], na.rm = TRUE)
          }

          output$countryPlots <- renderUI({
               plot_output_list <- lapply(selected_countries, function(country) {
                    plotname <- paste0("plot_", gsub(" ", "_", country))
                    plotOutput(plotname, height = "300px", width = "100%")
               })
               do.call(tagList, plot_output_list)
          })

          lapply(selected_countries, function(country) {
               output[[paste0("plot_", gsub(" ", "_", country))]] <- renderPlot({

                    country_data <- cholera_data[cholera_data$country == country, ]
                    country_data$year <- factor(country_data$year, levels = full_years)
                    decade_starts <- which(levels(factor(full_years)) %in% as.character(seq(1970, 2024, by = 10)))
                    country_index <- which(unique(cholera_data$country) == country)
                    fill_color <- ifelse(country == "AFRO Region", "black", pal[country_index])

                    country_data <- country_data[!is.na(country_data[[y_var]]) & country_data[[y_var]] >= 0, ]

                    if (nrow(country_data) > 0) {
                         p <- ggplot(country_data, aes(x = year, y = get(y_var)))

                         if (y_var == "cfr") {

                              p <- p +
                                   geom_point(aes(y = cfr), color = fill_color, size = 3.5) +
                                   geom_errorbar(aes(ymin = cfr_lo, ymax = cfr_hi), size=1, width = 0, color = fill_color)
                         } else {

                              p <- p +
                                   geom_vline(xintercept = decade_starts, color = "grey80", size = 0.25) +
                                   geom_bar(stat = "identity", fill = fill_color) +
                                   geom_hline(yintercept = 0, color = "black", size = 0.25)
                         }

                         p <- p +
                              theme_minimal(base_size = 13.5) +
                              labs(x = "Year", y = ifelse(y_var == "cases_total", "Reported Cases",
                                                          ifelse(y_var == "deaths_total", "Reported Deaths", "Case Fatality Ratio (CFR)")),
                                   title = country) +
                              scale_y_continuous(labels = if (y_var == "cfr") scales::percent else scales::comma,
                                                 limits = c(0, global_y_max), expand = c(0.05, 0)) +
                              scale_x_discrete(drop = FALSE) +
                              theme(
                                   plot.title = element_text(size = 14, color = 'black', hjust = 0.5, face = "bold"),
                                   axis.text.x = element_text(size = 11, color = 'black', angle = 90, hjust = 1, vjust = 0.5),
                                   axis.text.y = element_text(size = 12, color = 'black'),
                                   axis.title.x = element_blank(),
                                   axis.title.y = element_blank(),
                                   panel.grid.minor = element_blank(),
                                   panel.grid.major.x = element_blank(),
                                   panel.grid.major.y = element_line(color = "grey80", size = 0.25),
                                   legend.position = 'none'
                              )

                         print(p)
                    } else {

                         ggplot() +
                              theme_void() +
                              labs(title = country, x = NULL, y = NULL) +
                              theme(plot.title = element_text(size = 14, color = 'black', hjust = 0.5, face = "bold"))

                    }
               })
          })
     })
}

shinyApp(ui = ui, server = server)
