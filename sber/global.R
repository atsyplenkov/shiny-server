library(dplyr)
library(purrr)
library(shiny)
library(httr)
library(markdown)
library(stringr)
library(shinybusy)
library(shinyjs)
library(waiter)

rephrase <- function(x,
                     temperature = 0.9,
                     top_k =  50,
                     top_p = 0.7){
  
  x <- 
    x %>% 
    trimws() %>% 
    str_remove("\n") %>% 
    str_remove("\t")
  
  URL = 'https://api.aicloud.sbercloud.ru/public/v2/rewriter/predict'
  params = paste0('{"instances": [{"text": "',
                  x,
                  '", "temperature": ', temperature,
                  ', "top_k": ',
                  top_k,
                  ', "top_p": ',
                  top_p,
                  ', "range_mode": "bertscore"}]}')
  
  r <- POST(url = URL,
            body = params,
            content_type("application/json"))
  
  result <- content(r)
  
  list(
    best = result$prediction_best[[1]],
    other = unlist(result$predictions_all)
  )
  
}

rephrase("Вася ела малину. Ей было очень вкусно", temperature = 1.5)
