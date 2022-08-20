function(input, output) {
  
  waiter_hide() # will hide *on_load waiter
  
  phrases <- reactiveValues(data = NULL)
  
  observeEvent(input$update, {
    
    disable("update")
    
    phrases$data <- rephrase(x = input$text,
                             temperature = input$temperature,
                             top_p = input$top_p,
                             top_k = input$top_k)
    enable("update")
  })
  
  output$text <- renderText({
    phrases$data %>% 
      pluck(1) 
  })
  
  # output$other <- renderText({
    # phrases$data[2] 
  # })
  
  output$other <- renderUI(
    HTML(
      renderMarkdown(
        text = paste0("- ",
                      phrases$data[[2]],
                      "\n")
      )
      # paste0("<ul><li>",
      #        phrases$data[[2]],
      #        "</li><li>")
    )
  )
  
  
}
