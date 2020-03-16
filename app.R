library(shiny)
library(ggplot2)
library(data.table)

RawData <- readRDS("temp.dat")
RawData$NumDate <- as.numeric(RawData$Date)-min(as.numeric(RawData$Date))
RawData <- data.table(NumDate = 0:(max(RawData$NumDate)+14),
                      Date = seq.Date(min(RawData$Date), max(RawData$Date)+14, by = "days" ),
                      CaseNumber = c(RawData$CaseNumber, rep(NA, 14)),
                      Actual = c(rep(TRUE, nrow(RawData)), rep(FALSE, 14)))
ExpFits <- lapply( 80:99, function(conflev) data.table( RawData,
                                                        exp(predict(lm(log(CaseNumber) ~ NumDate, data = RawData[Actual==TRUE]),
                                                                    newdata = data.table(
                                                                      NumDate = 0:(max(RawData[Actual==TRUE]$NumDate)+14)),
                                                                    interval = "confidence", level = conflev/100))))
names(ExpFits) <- 80:99

ui <- fluidPage(
  theme = "owntheme.css",
  
  titlePanel("COVID-19 magyar epidemiológia"),
  
  navlistPanel(
    tabPanel("Magyarázat", withMathJax(includeMarkdown("generalExplanation.md"))),
    tabPanel("Járványgörbe",
             fluidPage(
               tabsetPanel(
                 tabPanel("Grafikon",
                          plotOutput("epicurveGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   checkboxInput("logyEpicurve", "Függőleges tengely logaritmikus"),
                                   checkboxInput("expfit", "Exponenciális görbe illesztése"),
                                   checkboxInput("loessfit", "LOESS nem-paraméteres simítógörbe illesztése")
                            ),
                            column( 3,
                                    conditionalPanel("input.expfit==1|input.loessfit==1",
                                                     checkboxInput("fitciEpicurve", "Konfidenciaintervallum megjelenítése")),
                                    conditionalPanel("(input.expfit==1|input.loessfit==1)&input.fitciEpicurve==1",
                                                     numericInput("ciconfEpicurve", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            )
                          )
                 ),
                 tabPanel("Számszerű adatok", rhandsontable::rHandsontableOutput("epicurveTab")), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    ),
    tabPanel("Előrejelzések",
             fluidPage(
               tabsetPanel(
                 tabPanel("Empirikus (grafikon)",
                          plotOutput("projEmpGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   checkboxInput("logyProj", "Függőleges tengely logaritmikus"),
                                   numericInput("projperiods", "Előrejelzett napok száma", 3, 1, 14, 1)
                            ),
                            column( 3,
                                    checkboxInput("fitciProj", "Konfidenciaintervallum megjelenítése"),
                                    conditionalPanel("input.fitciProj==1",
                                                     numericInput("ciconfProj", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            )
                          )
                 ), 
                 tabPanel("Empirikus (számszerű)", rhandsontable::rHandsontableOutput("projEmpTab")), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )),
    tabPanel("Empirikus modellezés",
             fluidPage(
               tabsetPanel(
                 tabPanel("Grafikon",
                          plotOutput("projGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   checkboxInput("logy", "Függőleges tengely logaritmikus"),
                                   numericInput("projperiods", "Előrejelzett napok száma", 3, 1, 14, 1)
                            ),
                            column( 3,
                                    checkboxInput("fitci", "Konfidenciaintervallum megjelenítése"),
                                    conditionalPanel("input.fitci==1",
                                                     numericInput("ciconf", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            )
                          )
                 ), 
                 tabPanel("Számszerű adatok", rhandsontable::rHandsontableOutput("projTab")), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    )
    #widths = c(3,9)
  )
)

server <- function(input, output, session) {
  
  dataInput <- reactive({
    
  })
  
  output$epicurveGraph <- renderPlot({
    ggplot(ExpFits[[as.character(input$ciconfEpicurve)]][Actual==TRUE], aes(x = Date, y = CaseNumber)) + geom_point(size = 3) +
      labs(x = "Dátum", y = "Esetszám [fő]") +
      {if(input$logyEpicurve) scale_y_log10()} +
      {if(input$expfit) geom_line(aes(y = fit), col = "red")} +
      {if(input$expfit&input$fitciEpicurve) geom_ribbon(aes(ymin = lwr, ymax = upr), fill = "red", alpha = 0.2)} +
      {if(input$loessfit) geom_smooth(formula = y ~ x, method = "loess", col = "blue", se = input$fitciEpicurve, fill = "blue",
                                      alpha = 0.2, level = input$ciconfEpicurve/100, size = 1)}
  })
  
  output$epicurveTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[Actual==TRUE][,c("Date", "CaseNumber")], colHeaders = c("Dátum", "Esetszám [fő]"),
                                 readOnly = TRUE)
  })
  
  output$projEmpGraph <- renderPlot({
    ggplot(ExpFits[[as.character(input$ciconfProj)]][1:(sum(Actual)+input$projperiods)], aes(x = Date, y = CaseNumber)) +
      geom_point(size = 3) + geom_line(aes(y = fit), col = "red") + labs(x = "Dátum", y = "Esetszám [fő]") +
      {if(input$fitciProj) geom_ribbon(aes(ymin = lwr, ymax = upr), fill = "red", alpha = 0.2)} +
      {if(input$logyProj) scale_y_log10()}
  })
  
  output$projEmpTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(ExpFits[["95"]][,c("Date", "CaseNumber", "fit", "lwr", "upr")],
                                 colHeaders = c("Dátum", "Esetszám [fő]", "Becsült esetszám [fő]",
                                                "95% CI alsó széle [fő]", "95% CI felső széle [fő]"), readOnly = TRUE)
  })
  
}

shinyApp( ui = ui, server = server )