library(markdown)
library(leaflet)


shinyUI(navbarPage("Spruce Budworm Simulation",
  tabPanel("Plot",
    tags$div(id="page-container",
      tags$head(
        # Include our custom CSS
        includeCSS("app.css"),
        includeScript("app.js")
      ),
    
      leafletOutput("hysplitPlot", width = "100%", height = "100%"),
                                 
      absolutePanel(id="side-panel-container", class = "panel panel-default", fixed = TRUE,
                    draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                    height = "auto",
                    
                    # window bar container
                    tags$div(class="window-bar-container",
                             HTML('<div id="min-max-button">
                                    <span id="min-max-icon" class="glyphicon glyphicon-minus" aria-hidden="true"></span>
                                  </div>')
                    ),
                    
                    tags$div(id="input-container",
                      numericInput(inputId = "inputYear", label = "Year", value = 2013),
                      
                      numericInput(inputId = "inputLat", label = "Latitude", value = 46),
                      
                      numericInput(inputId = "inputLon", label = "Longitude", value = -84),
                      
                      # trajectory duration input
                      numericInput(inputId = 'inputDuration', label = 'Trajectory duration', 
                                   value = 3, min = 1, max = 24),
                      
                      # add an action button to trigget the hysplit processing
                      actionButton(inputId = "runHySplit", label = "Run", class="run-button")
                    )
      )
      
    )
  )
))





