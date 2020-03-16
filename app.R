library(shiny)
library(ggplot2)
library(data.table)

ui <- fluidPage(
  
  titlePanel("COVID-19 magyar epidemiológia"),
  
  navlistPanel(
    tabPanel("Járványgörbe",
             fluidPage(
               tabsetPanel(
                 tabPanel("Grafikon",
                          plotOutput("epicurveGraph"),
                          hr(),
                          fluidRow(
                            checkboxInput("logy", "Függőleges tengely logaritmikus"),
                            checkboxInput("expfit", "Exponenciális görbe illesztése"),
                            checkboxInput("loessfit", "LOESS nem-paraméteres simítógörbe illesztése"),
                            conditionalPanel("input.expfit==1|input.loessfit==1",
                                             checkboxInput("fitci", "Konfidenciaintervallum megjelenítése")),
                            conditionalPanel("(input.expfit==1|input.loessfit==1)&input.fitci==1",
                                             numericInput("ciconf", "Megbízhatósági szint [%]:", 95, 0, 100, 1 ))
                          )), 
                 tabPanel("Számszerű adatok", rhandsontable::rHandsontableOutput("epicurveTab")), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    ),
    tabPanel("Előrejelzések"),
    tabPanel("Empirikus modellezés")
    #widths = c(3,9)
  )
)

server <- function(input, output, session) {
  
  temp <- readRDS("temp.dat")
  
  output$epicurveGraph <- renderPlot({
    temp <- cbind(temp, exp(predict(lm(log(CaseNumber) ~ NumDate, data = temp), interval = "confidence",
                                    level = input$ciconf/100)))
    p <- ggplot(temp, aes(x = NumDate, y = CaseNumber)) + geom_point()
    if(input$logy) p <- p + scale_y_log10()
    if(input$expfit) p <- p + geom_line(aes(y = fit), col = "red") + if(input$fitci) geom_ribbon(aes(ymin = lwr, ymax = upr),
                                                                                                 fill = "red", alpha = 0.2)
    if(input$loessfit) p <- p + geom_smooth(formula = y ~ x, method = "loess", col = "blue", se = input$fitci, fill = "blue",
                                            alpha = 0.2, level = input$ciconf/100)
    p
  })
  
  output$epicurveTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(temp, readOnly = TRUE)
  })
}

shinyApp( ui = ui, server = server )