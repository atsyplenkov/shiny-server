function(input, output, session) {
  
  waiter_hide() # will hide *on_load waiter
  
  data <- reactiveValues(data = NULL,
                         long = NULL)
  
  observeEvent(input$mymoney, {
    
    req(input$mymoney)
    
    data$data <- get_mir_currency()
    data$long <- data$data %>% 
      dplyr::select(-1) %>% 
      tidyr::gather(var, val) %>% 
      mutate(Kypc = c(
        "RUB/BYN в системе МИР",
        "RUB/BYN Цептер банк",
        "EUR/BYN Цептер банк",
        "RUB/EUR ЦБР",
        "RUB/EUR через МИР-Цептер¹",
        "RUB/EUR через МИР-Цептер²"
      )) %>% 
      transmute(Kypc,
                value = round(val, 2))
    
  })
  
  # Render DT
  output$table1 <- renderDT({
    datatable(data = data$long,
              selection = "none",
              options = list(dom = 't'),
              rownames = F,
              style = 'bootstrap',
              class = 'table-bordered table-condensed')
  })
  
  # Сегодняшняя дата
  output$date <-
    renderPrint({
      dataset <- data$data
      cat(dataset$date)
    })
  
  output$rub1 <- 
    renderPrint({
      dataset <- data$data
      
      itog <- round(input$mymoney / dataset$rub_eur_zeptermir, 2)
      
      cat(paste0(itog, " EUR"))
      
    })
  
  output$rub2 <- 
    renderPrint({
      dataset <- data$data
      
      itog <- round(input$mymoney / dataset$rub_eur_zepter, 2)
      
      cat(paste0(itog, " EUR"))
      
    })
  
  output$eur1 <- 
    renderPrint({
      dataset <- data$data
      
      itog <- round(input$desired * dataset$rub_eur_zeptermir, 2)
      
      cat(paste0(itog, " RUB"))
      
    })
  
  output$eur2 <- 
    renderPrint({
      dataset <- data$data
      
      itog <- round(input$desired * dataset$rub_eur_zepter, 2)
      
      cat(paste0(itog, " RUB"))
      
    })
  
}