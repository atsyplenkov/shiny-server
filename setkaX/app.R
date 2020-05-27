library(shiny)
library(tidyverse)
library(glue)
library(sf)
library(leaflet)
library(mapview)

ui <- fluidPage(
  titlePanel("SETKOSTROITEL X"),
  sidebarLayout(
    
    sidebarPanel(
      
      fileInput("file",
                label="Загружать CSVs сюда",
                accept = ".csv",
                multiple = TRUE),
      
      downloadButton("downloadmif", "Скачать .mif"),
      downloadButton("downloadmid", "Скачать .mid"),
      
      # author info
      shiny::hr(),
      em(
        span("Created by "),
        a("Anatoly Tsyplenkov", href = "mailto:atsyplenkov@gmail.com"),
        span(", Apr 2020"),
        br(), br()
      )
      
    ),
    # Main:
    mainPanel(
      
      leafletOutput("mymap"),
      tableOutput("mytable")
      
    )
  )
) 

server <- function(input, output) {
  
  # Set the maximum file size
  options(shiny.maxRequestSize = 200*1024^2)
  
  Dataset_bind <- reactive({
    
    if (is.null(input$file)) {
      # User has not uploaded a file yet
      return(data.frame())
    }
    
    # Calculate the duration of progress bar loading
    N <- round(file.size(path.expand(input$file$datapath)) / 1024^2)
    
    # Add progress bar
    withProgress(message = 'Reading data', value = 0, {
      
      for(i in 1:N){
        
        # Long Running Task
        Sys.sleep(0.5)
        
        # Update progress
        incProgress(1/N)
      }
      
      df <- tibble(filename = input$file$datapath) %>%
        mutate(file_contents = map(filename,
                                   ~read_csv(., skip = 2))) %>% 
        unnest(file_contents) %>% 
        filter(K != 1) %>% 
        dplyr::select(-Z, -K) %>% 
        group_by(filename) %>%
        nest() %>% 
        mutate(Jmax = map(data, ~max(.x$J)),
               Imax = map(data, ~max(.x$I))) %>% 
        unnest(c(data, Jmax, Imax)) %>% 
        group_by(filename, Jmax, Imax, I, J) %>% 
        nest()
      
      # 2) I = 0, sort descending
      df_I0 <- df %>% 
        filter(I == 0) %>% 
        unnest(data) %>% 
        group_by(filename) %>% 
        nest() %>% 
        mutate(data = map(data, ~rowid_to_column(.)),
               data = map(data, ~arrange(.x ,-.x$rowid))) %>% 
        unnest(data) %>% 
        ungroup() %>% 
        dplyr::select(filename, Jmax, X, Y)
      
      # 3) J = 0 
      df_J0 <- df %>% 
        filter(J == 0) %>% 
        unnest(data) %>% 
        ungroup() %>% 
        dplyr::select(filename, Jmax, X, Y) %>% 
        dplyr::slice(-1)
      
      # 4) I = MAX 
      df_Imax <- df %>% 
        filter(I == Imax) %>% 
        unnest(data) %>% 
        ungroup() %>% 
        dplyr::select(filename, Jmax, X, Y) %>% 
        slice(-1)
      
      # 5) J = MAX 
      df_Jmax <- df %>% 
        filter(J == Jmax) %>% 
        unnest(data) %>% 
        group_by(filename) %>% 
        nest() %>% 
        mutate(data = map(data, ~rowid_to_column(.)),
               data = map(data, ~arrange(.x ,-.x$rowid))) %>% 
        unnest(data) %>% 
        ungroup() %>% 
        dplyr::select(filename, Jmax, X, Y) %>% 
        dplyr::slice(-1)
      
      # 6) Bind
      df_bind <- bind_rows(df_I0, df_J0, df_Imax, df_Jmax) 
      
      return(df_bind)
      
    })
  })
  
  Dataset <- reactive({
    
    df_prep <- Dataset_bind() %>% 
      group_by(filename) %>% 
      mutate_at(vars(-group_cols()),
                ~as.character(.)) %>%
      nest() %>% 
      mutate(data = map(data,
                        ~add_row(.x, X = as.character(nrow(.)),
                                 Y = "", .before = 1)),
             data = map(data,
                        ~add_row(.x, X = "Pen", Y = "(1,1,1)")),
             data = map(data,
                        ~add_row(.x, X = "Region", Y = "1", .before = 1))
      ) %>%
      unnest(data) %>% 
      ungroup() %>% 
      dplyr::select(-filename) %>% 
      add_row(X = "Data", Y = "", .before = 1)
    
    return(df_prep)
  })
  
  Table <- reactive({
    
    nfiles <- length(input$file$datapath)
    
    # jmax_vector <- Dataset() %>% 
    #     dplyr::select(Jmax) %>%
    #     dplyr::mutate(Jmax = as.numeric(Jmax)) %>%
    #     # filter(!is.na(Jmax)) %>% 
    #     pull(Jmax) %>%
    #     unique()
    
    jmax_vector <- Dataset_bind() %>% 
      group_by(filename) %>%
      summarise(Jmax_ = unique(Jmax)) %>% 
      pull()
    
    ruslo <- tibble(ruslo = glue::glue("русло{seq(from = 1, to = nfiles, by = 1)},{jmax_vector},,,,1"))
    
    return(ruslo)
    
  })
  
  ### Download .mif
  output$downloadmif <- downloadHandler(
    filename = function() {
      paste0(x = gsub(input$file[[1]],
                      pattern = ".csv",
                      replacement = ""), ".mif")
    },
    content = function(file) {
      write.table(x = Dataset() %>% 
                    dplyr::select(-Jmax), file, sep = " ",
                  row.names = F, col.names = F, dec = ".",
                  quote = F, fileEncoding = "UTF-8")
    }
  )
  ### Download .mid
  output$downloadmid <- downloadHandler(
    filename = function() {
      paste0(x = gsub(input$file[[1]],
                      pattern = ".csv",
                      replacement = ""), ".mid")
    },
    content = function(file) {
      write.table(x = Table(), file, sep = " ",
                  row.names = F, col.names = F, dec = ".",
                  quote = F, fileEncoding = "windows-1251")
    }
  )
  
  ### Show map:
  output$mymap <- renderLeaflet({
    
    if (is.null(input$file)) return(NULL)
    
    m <- Dataset_bind() %>% 
      dplyr::select(X, Y) %>% 
      st_as_sf(coords = c("X", "Y")) %>% 
      mapview(fill = "cyan",
              color = "white",
              alpha = 0.1,
              map.types = c("CartoDB.DarkMatter"),
              legend = FALSE
              # popup = popupImage("https://jeroenooms.github.io/images/banana.gif",
              # src = "remote")
      )
    
    m@map
    
  })
  
  output$mytable <- renderTable({
    
    if (is.null(input$file)) return(NULL)
    
    Table()
    
  },
  align = "c", bordered = T, striped = T
  )
  
}

shinyApp(ui = ui, server = server)