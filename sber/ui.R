fluidPage(
  
  useWaiter(), # dependencies
  waiterShowOnLoad(spin_fading_circles()), # shows before anything else
  
  # Add progress bar
  add_busy_spinner(spin = "folding-cube",
                   color = "#3fbdc3",
                   height = "40px",
                   width = "40px"),
  
  shinyjs::useShinyjs(),
  
  titlePanel("Рерайтер"),
  fluidRow(
    column(6, wellPanel(
      textAreaInput("text", "Введите текст",
                    resize = "vertical",  
                    width = "100%",
                    height = "160px"),
      actionButton("update", "Переписать!"),
      div(style="height: 80px;",
          sliderInput("temperature",
                      "Температура",
                      min = 0.1, max = 1.9, 
                      value = 1,
                      step = 0.01)),
      div(style="height: 80px;",
      sliderInput("top_k",
                  "top_k",
                  min = 1, max = 200, 
                  value = 55,
                  step = 1)),
      div(style="height: 80px;",
      sliderInput("top_p",
                  "top_p",
                  min = 0.1, max = 2, 
                  value = 0.7,
                  step = 0.01)),
      hr(),
      includeMarkdown("include.md")
    )),
    column(6,
           h4("Лучший вариант:"),
           textOutput("text"),
           hr(),
           h5("Другие варианты:"),
           uiOutput("other")
    )
  )
)

