library(tidyverse)
library(rvest)
library(readr)
library(memoise)
library(DT)
library(markdown)
library(waiter)

# Парсим курс МИР-Белорусский рубль ---------------------------------------
get_mir_currency <- memoise(function(){
  mir_source <- 
    read_html("https://mironline.ru/support/list/kursy_mir/")
  
  rub_byn_mir <- 
    mir_source %>% 
    html_nodes("table tbody tr td span p") %>% 
    html_text() %>% 
    as.data.frame() %>% 
    mutate_all(~readr::parse_number(.,
                                    locale = locale(decimal_mark = ","))) %>% 
    slice(2) %>% 
    pull()
  
  # Парсим курс Цептер банка BYN/EUR ----------------------------------------
  zepter_source <- 
    read_html("https://www.zepterbank.by/personal/services/currency/card/")
  
  zepter_table <- 
    zepter_source %>% 
    html_nodes("table.rate.rate_long_name tbody") %>%
    html_table() %>% 
    pluck(1)
  
  rub_byn_zepter <-
    zepter_table %>% 
    mutate(conversion = X1/X3) %>% 
    dplyr::filter(X2 == "RUB") %>% 
    pull(conversion)
  
  eur_byn_zepter <- 
    zepter_table %>% 
    dplyr::filter(X2 == "EUR") %>% 
    pull(X4)
  
  # Парсим курс ЦБ ----------------------------------------------------------
  cbr_source <- 
    read_html("https://cbr.ru/currency_base/daily/")
  
  rub_eur_cbr <- 
    cbr_source %>% 
    html_nodes("table.data") %>% 
    html_table() %>%
    pluck(1) %>% 
    dplyr::filter(`Валюта` == "Евро") %>% 
    pull(`Курс`) %>% 
    readr::parse_number(locale = locale(decimal_mark = ","))
  
  # Расчет курса евро через Цептер ------------------------------------------
  rub_eur_zeptermir <- 1000/(1000/rub_byn_mir/eur_byn_zepter)
  rub_eur_zepter <- 1000/(1000/rub_byn_zepter/eur_byn_zepter)
  
  # Формирование итогового датафрейма ---------------------------------------
  tibble(
    date = format(Sys.Date(), "%d.%m.%Y"),
    rub_byn_mir,
    rub_byn_zepter,
    eur_byn_zepter,
    rub_eur_cbr,
    rub_eur_zeptermir,
    rub_eur_zepter
  )
  
})
