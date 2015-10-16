library(shiny)
library(DaymetR)
library(opentraj)
library(leaflet)

## Code placed outside the server function, will be executed once time only

## Run to calculate the phenology
## source("/home/thalles/Desktop/workspace/Canada-work/Regniere_2012_SBW_Pheno.R")

# add inputs and outputs into the fluidPage function
ui <- fluidPage(
  includeCSS("styles.css"),
  includeScript("https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/jquery-ui.min.js"),
  includeScript('app.js'),
  
  # Application title
  titlePanel("Spruce Budworm Spread Simulator"),
  
  tags$div(class="data-container",
    # side bar container
    tags$div(id="side-bar-container", class="top-side-bar",
      # window bar container
      tags$div(class="window-bar-container",
        HTML('<div id="min-max-button">
                <span id="min-max-icon" class="glyphicon glyphicon-minus" aria-hidden="true"></span>
              </div>')
      ),
      
      # side bar input container
      tags$div(id="input-container",
        
               HTML('<div class="form-group">
                      <label class="h5 input-labels" for="inputYear">Year</label>
                      <input type="number" class="input-controllers form-control shiny-bound-input" id="inputYear" value="2013">
                     </div>'),
               
               HTML('<div class="form-group">
                      <label class="h5 input-labels" for="inputLat">Latitude</label>
                      <input type="number" class="input-controllers form-control shiny-bound-input" id="inputLat" value="46">
                     </div>'),
               
               HTML('<div class="form-group">
                      <label class="h5 input-labels" for="inputLon">Longitude</label>
                      <input type="number" class="input-controllers form-control shiny-bound-input" id="inputLon" value="-84">
                    </div>'),      
               HTML('<div class="form-group">
                      <label class="h5 input-labels" for="inputDuration">Trajectory duration</label>
                      <input type="number" class="input-controllers form-control shiny-bound-input" id="inputDuration" value="3" min="1" max="24">
                    </div>'),  

               
        ##numericInput(inputId = "inputYear", label = "Year", value = 2013),
        
        ##numericInput(inputId = "inputLat", label = "Latitude", value = 46),
        
        ##numericInput(inputId = "inputLon", label = "Longitude", value = -84),
        
        # trajectory duration input
        # numericInput(inputId = 'inputDuration', label = 'Trajectory duration', 
        #            value = 3, min = 1, max = 24),
        
        # add an action button to trigget the hysplit processing
        actionButton(inputId = "runHySplit", label = "Run", class="run-button")
      )
    ),
    fluidRow(
      column(12,
         # Show a plot of the generated distribution
         #mainPanel(
           # creates a space to display the output
           # plotOutput("hysplitPlot") # code for displaying maps using the R plot function
           leafletOutput("hysplitPlot") # make space in the UI for displaying leaflet map output
         #)
      )
    )
  )
)

server <- function(input, output) {
  ## code inside the server function will be executed once per user
  
  ## the eventReactive function monitors the value, (The actionButton)
  ## and when it changes they run a block of code.
  hytraj <- eventReactive(input$runHySplit, {
    
    withProgress(message = 'Making a plot.', value = 0, {
      
      ######################
      # Increment the progress bar, and update the detail text.
      incProgress(0.1, detail = paste("Preparing data..."))
      ######################
    
      ## get the coordinate points entered by the user
      lat <- input$inputLat
      lon <- input$inputLon
      Year <- input$inputYear
      
      ## get the users duration input
      trajectory.duration <- input$inputDuration;
      
      print(Year)
      print(lat)
      print(lon)
      print(trajectory.duration)

      
      ## Load Daily MinT, MaxT and Precip from Daymet output
      ## Use the first point in the output, should do a loop if there are several points
      download.daymet(site="daymet.df",lat=lat,lon=lon,start_yr=Year,end_yr=Year,internal=TRUE)
      Tmin <- daymet.df$data$tmin..deg.c.
      Tmax <- daymet.df$data$tmax..deg.c.
      Day <- daymet.df$data$yday
      
      ######################
      # Increment the progress bar, and update the detail text.
      incProgress(0.1, detail = paste("Whether data downloaded."))
      ######################
      
      ## Run to calculate the phenology
      Pheno <- SBW.Pheno(Year,Day,unlist(Tmin),unlist(Tmax))
      
      # Calculate the median of the adult emergence as start date for 
      # Hysplit and 7 days after the start as end date
      Start_date <- median(Pheno$E.Adult)
      Stop_date <- Start_date+7
      
      tz <- "EST"
      
      # convert the start and end dates from Julian to Regular dates
      # Use the following to convert julian dates of adult emergence to actual dates
      Start_date <- strptime(paste(Year,Start_date),"%Y %j", tz = tz)
      Stop_date <- strptime(paste(Year,Stop_date),"%Y %j", tz = tz)
      
      # get the dates in between the Start_date and Stop_date range
      dates <- seq(as.POSIXct(Start_date, tz), as.POSIXct(Stop_date, tz), by = paste("1 day", sep=" "))
      
      # path to hysplit
      hy.path <- "/home/thalles/hysplit/trunk/"
      
      # path to the output directory
      out <- "/home/thalles/hysplit/trunk/working/"
      
      #path to the meteorological files
      met <- "/home/thalles/hysplit-july-2013/weather/2013/"
      
      height <- 100
      ID <- 1
      output.file.name <- "phone"
      
      ######################
      # Increment the progress bar, and update the detail text.
      incProgress(0.2, detail = paste("Phenology calculated."))
      ######################
      
      
      # Run hysplit
      traj <- ProcTraj(lat = lat, lon = lon, name = output.file.name,
                       hour.interval = 1,
                       met = met, out = out, 
                       duration = trajectory.duration, height = height, hy.path = hy.path, ID = ID, dates=dates,
                       start.hour = "19:00", end.hour = "23:00",
                       tz = "EST", clean.files = T ) 
      
      
      # Increment the progress bar, and update the detail text.
      incProgress(0.5, detail = paste("Preparing trajectories"))
      
      # Transform to Spatial lines
      crs <- "+proj=longlat +datum=NAD83 +no_defs +ellps=GRS80 +towgs84=0,0,0"
      hytraj07.lines <- Df2SpLines(traj, crs)
      
      # apparently the leaflet only works if we transform the splines to that CRS
      hytraj07.lines = spTransform(hytraj07.lines, CRS("+init=epsg:4326"))
      
      
      # Increment the progress bar, and update the detail text.
      incProgress(0.1, detail = paste("Plot calculation done."))
    
    }) # end of progress bar
    
    # return the lines object
    hytraj07.lines
  })
  
  # displays the leaflet map object
  output$hysplitPlot <- renderLeaflet({
    leaflet(data=hytraj()) %>%
      addTiles() %>% # Add default OpenStreetMap map tiles
      addPolylines()
  })
  
#   Old function for displaying the map from the PlotTraj() function from opentraj
#   # store the output in the output$ list
#   output$hysplitPlot <- renderPlot({
#     # print(hytraj())
#     
#     PlotTraj(hytraj())
#   })

}

shinyApp(ui=ui, server=server)
