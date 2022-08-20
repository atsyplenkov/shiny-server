pageWithSidebar(
  headerPanel('Расчет курса валют через Цептер-банк'),
  sidebarPanel(
    numericInput('mymoney',
                 'Сколько рос. руб. вы хотите перевести?',
                 1000,
                 min = 1,
                 max = Inf),
    hr(),
    h4("По схеме МИР-БЕЛКАРТ-VISA¹:"),
    h4(textOutput("rub1")),
    helpText("С учетом ожидания возвращения разницы курса"),
    h4("По схеме МИР-БЕЛКАРТ-VISA²:"),
    h4(textOutput("rub2")),
    helpText("Моментально"),
    hr(),
    numericInput('desired',
                 'Сколько евро вы хотите получить?',
                 100,
                 min = 1,
                 max = Inf),
    hr(),
    h4("По схеме МИР-БЕЛКАРТ-VISA¹:"),
    h4(textOutput("eur1")),
    helpText("С учетом ожидания возвращения разницы курса"),
    h4("По схеме МИР-БЕЛКАРТ-VISA²:"),
    h4(textOutput("eur2")),
    helpText("Моментально")

    
  ),
  mainPanel(
    h3("Курсы валют по состоянию на", textOutput("date")),
    DTOutput("table1"),
    hr(),
    includeMarkdown("include.md")

  )
)