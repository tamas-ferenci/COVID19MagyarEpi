library(shiny)
library(ggplot2)
library(data.table)

RawData <- readRDS("temp.dat")

r2R0gamma <- function(r, si_mean, si_sd) {
  (1+r*si_sd^2/si_mean)^(mu^2/sigma^2)
}
lm2R0gamma_sample <- function(x, si_mean, si_sd, n = 100) {
  df <- nrow(x$model) - 2 # degrees of freedom of t distribution
  r <- x$coefficients[2]
  std_r <- stats::coef(summary(x))[, "Std. Error"][2]
  r_sample <- r + std_r * stats::rt(n, df)
  r2R0gamma(r_sample, si_mean, si_sd)
}

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
                            column(3,
                                   conditionalPanel("input.expfit==1|input.loessfit==1",
                                                    checkboxInput("fitciEpicurve", "Konfidenciaintervallum megjelenítése")),
                                   conditionalPanel("(input.expfit==1|input.loessfit==1)&input.fitciEpicurve==1",
                                                    numericInput("ciconfEpicurve", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            ),
                            column(3,
                                   conditionalPanel("input.expfit==1|input.loessfit==1",
                                                    sliderInput("windowEpicurve", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                                                nrow(RawData), c(1, nrow(RawData)), 1))
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
                            column(3,
                                   checkboxInput("fitciProj", "Konfidenciaintervallum megjelenítése"),
                                   conditionalPanel("input.fitciProj==1",
                                                    numericInput("ciconfProj", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            ),
                            column(3,
                                   sliderInput("windowProj", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                               nrow(RawData), c(1, nrow(RawData)), 1)
                            )
                          )
                 ), 
                 tabPanel("Empirikus (számszerű)", rhandsontable::rHandsontableOutput("projEmpTab")), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    ),
    tabPanel("R becslés növekedési ráta alapján",
             fluidPage(
               tabsetPanel(
                 tabPanel("Grafikon",
                          plotOutput("grGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuGrGraph", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdGrGraph", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowGrGraph", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                               nrow(RawData), c(1, nrow(RawData)), 1)
                            )
                          )
                 ), 
                 tabPanel("Számszerű adatok",
                          rhandsontable::rHandsontableOutput("grTab"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuGrTab", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdGrTab", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowGrTab", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                               nrow(RawData), c(1, nrow(RawData)), 1)
                            )
                          )
                 ), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    ),
    tabPanel("Elágazó folyamat-elvű modellezés",
             fluidPage(
               tabsetPanel(
                 tabPanel("Reprodukciós szám (teljes görbe)",
                          h4("Az egész görbe alapján számolt R, és a becslés bizonytalanságát jellemző eloszlása:"),
                          plotOutput("branchFullGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImu", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsd", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            )
                          )
                 ), 
                 #tabPanel("Számszerű adatok", rhandsontable::rHandsontableOutput("projTab")), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    ), widths = c(2, 8)
  )
)

server <- function(input, output, session) {
  
  output$epicurveGraph <- renderPlot({
    pred <- as.data.table(exp(predict(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                         subset = NumDate>=(input$windowEpicurve[1]-1)&NumDate<=(input$windowEpicurve[2]-1)),
                                      newdata = RawData, interval = "confidence", level = input$ciconfEpicurve/100)))
    pred$Date <- RawData$Date
    print(pred)
    ggplot(RawData, aes(x = Date, y = CaseNumber)) + geom_point(size = 3) + labs(x = "Dátum", y = "Esetszám [fő]") +
      {if(input$logyEpicurve) scale_y_log10()} +
      {if(input$expfit) geom_line(data = pred, aes(y = fit), col = "red")} +
      {if(input$expfit&input$fitciEpicurve) geom_ribbon(data = pred, aes(y = fit, ymin = lwr, ymax = upr), fill = "red",
                                                        alpha = 0.2)} +
      {if(input$loessfit) geom_smooth(data = subset(RawData, NumDate>=(input$windowEpicurve[1]-1)&
                                                      NumDate<=(input$windowEpicurve[2]-1)),
                                      formula = y ~ x, method = "loess", col = "blue", se = input$fitciEpicurve, fill = "blue",
                                      alpha = 0.2, level = input$ciconfEpicurve/100, size = 1)}
  })
  
  output$epicurveTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[,c("Date", "CaseNumber")], colHeaders = c("Dátum", "Esetszám [fő]"), readOnly = TRUE)
  })
  
  output$projEmpGraph <- renderPlot({
    pred <- as.data.table(exp(predict(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                         subset = NumDate>=input$windowProj[1]&NumDate<=input$windowProj[2]),
                                      newdata = data.table(NumDate = 0:(nrow(RawData)+input$projperiods-1)),
                                      interval = "confidence", level = input$ciconfProj/100)))
    pred$Date <- seq.Date(min(RawData$Date), max(RawData$Date)+input$projperiods, by = "days")
    ggplot(RawData, aes(x = Date, y = CaseNumber)) +
      geom_point(size = 3) + geom_line(data = pred, aes(y = fit), col = "red") + labs(x = "Dátum", y = "Esetszám [fő]") +
      {if(input$fitciProj) geom_ribbon(data = pred, aes(y = fit, ymin = lwr, ymax = upr), fill = "red", alpha = 0.2)} +
      {if(input$logyProj) scale_y_log10()}
  })
  
  output$projEmpTab <- rhandsontable::renderRHandsontable({
    pred <- as.data.table(exp(predict(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                         subset = NumDate>=(input$windowProj[1]-1)&NumDate<=(input$windowProj[2]-1)),
                                      newdata = data.table(NumDate = 0:(nrow(RawData)+input$projperiods-1)),
                                      interval = "confidence", level = input$ciconfProj/100)))
    pred$Date <- seq.Date(min(RawData$Date), max(RawData$Date)+input$projperiods, by = "days")
    pred$CaseNumber <- c(RawData$CaseNumber, rep(NA, input$projperiods))
    rhandsontable::rhandsontable(pred[,c("Date", "CaseNumber", "fit", "lwr", "upr")],
                                 colHeaders = c("Dátum", "Esetszám [fő]", "Becsült esetszám [fő]",
                                                "95% CI alsó széle [fő]", "95% CI felső széle [fő]"), readOnly = TRUE)
  })
  
  output$grGraph <- renderPlot({
    res <- data.frame(R0 = lm2R0gamma_sample(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                                subset = NumDate>=(input$windowGrGraph[1]-1)&
                                                  NumDate<=(input$windowGrGraph[2]-1)), input$SImuGrGraph, input$SImuGrGraph))
    ggplot(res,aes(R0)) + geom_density() + labs(y = "") + xlim(c(0.9, NA)) + geom_vline(xintercept = 1, col = "red", size = 2)
  })
  
  output$grTab <- rhandsontable::renderRHandsontable({
    res <- summary(lm2R0gamma_sample(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                        subset = NumDate>=(input$windowGrTab[1]-1)&NumDate<=(input$windowGrTab[2]-1)),
                                     input$SImuGrTab, input$SImuGrTab))
    rhandsontable::rhandsontable(data.table(`Változó` = c("Minimum", "Alsó kvartilis", "Medián", "Átlag",
                                                          "Felső kvartilis", "Maximum" ),
                                            `Érték` = as.numeric(res) ), readOnly = TRUE)
  })
}

shinyApp( ui = ui, server = server )