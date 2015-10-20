library(DaymetR)
library(opentraj)
library(sp)

shinyServer(function(input, output, session) {
  ## code inside the server function will be executed once per user
  source("/home/thalles/Desktop/workspace/Canada-work/Regniere_2012_SBW_Pheno.R")
  
  # initially draw the map in a given point 
  output$hysplitPlot <- renderLeaflet({
    # Use leaflet() here, and only include aspects of the map that
    # won't need to change dynamically (at least, not unless the
    # entire map is being torn down and recreated).
    leaflet() %>%
      addTiles() %>%  # Add default OpenStreetMap map tiles
      addMarkers(layerId = "marker-position", lng=-84.304416, lat=46.503813, popup="GLFC")
  })
  

  ## the eventReactive function monitors the value, (The actionButton)
  ## and when it changes they run a block of code.
  hytraj <- eventReactive(input$runHySplit, {
    
    withProgress(message = 'Making a plot.', value = 0, {
      
      ######################
      # Increment the progress bar, and update the detail text.
      incProgress(0.1, detail = paste("Preparing data..."))
      ######################
      
      ## get the coordinate points entered by the user
      lat <- input$inputLat;
      lon <- input$inputLon;
      Year <- input$inputYear;
      
      ## get the users duration input
      trajectory.duration <- input$inputDuration;
      
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
  
  observe({
    event <- input$hysplitPlot_click
    if (is.null(event))
      return()
    
    # get latitude and longitude from the marker
    lat=event$lat
    lng=event$lng
    
    # update the ui's input 
    updateNumericInput(session, inputId = "inputLat", value = lat)
    updateNumericInput(session, inputId = "inputLon", value = lng)
    
    # create a new marker at the click's position
    leafletProxy("hysplitPlot") %>%
      removeMarker(layerId = "marker-position") %>%
      addMarkers(layerId = "marker-position", lng, lat, popup="GLFC")
  })
  
  # update the map with new data
  observe({
    lines <- hytraj()
    bbox <- bbox(lines) # get the bounding box from the lines object
    leafletProxy("hysplitPlot", data = hytraj()) %>%
      clearShapes() %>%
      fitBounds(bbox["x", "min"], bbox["y","min"], bbox["x", "max"], bbox["y", "max"]) %>%  # world view
      addPolylines()
  })
  
})