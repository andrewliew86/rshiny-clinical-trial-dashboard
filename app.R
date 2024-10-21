# app.R
library(shiny)
library(shinydashboard)
library(leaflet)
library(DT)
library(tidyverse)
library(lubridate)
library(plotly)
library(countrycode)

# UI
ui <- dashboardPage(
  dashboardHeader(title = "Clinical Trials Dashboard"),
  dashboardSidebar(disable = TRUE),  # Disabled sidebar for more space
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper {
          margin-left: 0 !important;
        }
        .box {
          box-shadow: 2px 2px 10px rgba(0,0,0,0.1);
        }
      "))
    ),
    fluidRow(
      # Top row with summary boxes
      valueBoxOutput("total_trials", width = 3),
      valueBoxOutput("total_countries", width = 3),
      valueBoxOutput("total_phases", width = 3),
      valueBoxOutput("interventional_rate", width = 3)
    ),
    fluidRow(
      # Second row with status and phase distribution
      column(width = 6,
             box(
               title = "Trial Phases",
               plotlyOutput("status_donut"),
               width = NULL,
               height = 300
             )
      ),
      column(width = 6,
             box(
               title = "Top Sponsors",
               plotlyOutput("sponsor_bar"),
               width = NULL,
               height = 300
             )
      )
    ),
    fluidRow(
      # Fourth row with time series and sponsors
      column(width = 12,
             box(
               title = "Trials Over Time",
               plotlyOutput("time_scatter"),
               width = NULL,
               height = 300
             )
      )
    ),
    fluidRow(
      # Bottom row with detailed data table
      column(width = 12,
             box(
               title = "Detailed Trial Information",
               DTOutput("trials_table"),
               width = NULL
             )
      )
    )
  )
)

# Server
server <- function(input, output) {
    base_data <- read_csv("./data/sql_query.csv") %>%
      # Keep only year data from dates
      mutate(start_date =  year(start_date))
      
    # Expanded data for map
    expanded_data <- base_data %>%
      separate_rows(countries, sep = "\\|")
    
    # Expanded data for sponsorts
    sponsor_counts <- base_data %>%
      separate_rows(sponsors, sep = "\\|") %>%
      # Tuncate names that are too long
      mutate(sponsors = str_trunc(sponsors, 25, side = c("right"))) %>%
      count(sponsors) %>%
      arrange(desc(n)) %>%
      top_n(10, n)
  
  # Summary Boxes
  output$total_trials <- renderValueBox({
    valueBox(
      nrow(base_data),
      "Total Trials",
      icon = icon("flask"),
      color = "blue"
    )
  })
  
  output$total_countries <- renderValueBox({
    valueBox(
      n_distinct(expanded_data$countries),
      "Countries",
      icon = icon("globe"),
      color = "purple"
    )
  })
  
  output$total_phases <- renderValueBox({
    valueBox(
      n_distinct(base_data$phase),
      "Trial Phases",
      icon = icon("list"),
      color = "green"
    )
  })
  
  output$interventional_rate <- renderValueBox({
    interventional_rate <- mean(base_data$study_type == "INTERVENTIONAL") * 100
    valueBox(
      paste0(round(interventional_rate), "%"),
      "Interventional Trial Rates",
      icon = icon("check-circle"),
      color = "red"
    )
  })
  
  # Status Donut Chart
  output$status_donut <- renderPlotly({
    phase_counts <- base_data %>%
      drop_na(phase) %>%
      filter(phase != "NA") %>%
      count(phase) %>%
      mutate(percentage = n/sum(n) * 100)
    
    # Reorder labels for donut legend
    phase_counts$phase <- factor(phase_counts$phase,
                                 levels = c(
                                   "PHASE1",
                                   "PHASE1/PHASE2",
                                   "PHASE2",
                                   "PHASE2/PHASE3",
                                   "PHASE3",
                                   "PHASE4"
                                   )
                                 )
    
    plot_ly(phase_counts, labels = ~phase, values = ~n, type = 'pie',
            hole = 0.6,sort = FALSE) %>%
      layout(showlegend = TRUE,
             margin = list(t = 30),
             height = 250)
  })
  
  
  
  # Number of trials over time
  output$time_scatter <- renderPlotly({
    base_data <- base_data %>%
      group_by(start_date) %>%  # Group by year
      summarise(count = n()) %>%
      arrange(start_date)
    
    
    plot_ly(base_data, x = ~start_date, y= ~count, type = 'scatter', mode = 'markers+lines',
            marker = list(size = 10, color = '#1f77b4'),
            line = list(color = 'lightgray', width = 2)) %>%
      layout(xaxis = list(title = "Start Date"),
             yaxis = list(title = "Trial Count"),
             margin = list(t = 30),
             height = 250)

    
  })
  
  # Sponsor Bar Chart
  output$sponsor_bar <- renderPlotly({

    plot_ly(sponsor_counts, x = ~n, y =  ~reorder(sponsors,n), type = 'bar',
            marker = list(color = '#1f77b4')) %>%
      layout(xaxis = list(title = "Number of Trials"),
             yaxis = list(title = NA),
             margin = list(t = 30, b = 80),
             height = 250)
  })
  
  # Detailed Data Table
  output$trials_table <- renderDT({
    datatable(
      base_data,
      options = list(
        pageLength = 5,
        scrollX = TRUE
      ),
      style = 'bootstrap'
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)