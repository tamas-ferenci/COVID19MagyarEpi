library(shiny)
library(ggplot2)
library(data.table)

RawData <- readRDS("RawData.dat")

r2R0gamma <- function(r, si_mean, si_sd) {
  (1+r*si_sd^2/si_mean)^(si_mean^2/si_sd^2)
}
lm2R0gamma_sample <- function(x, si_mean, si_sd, n = 100) {
  df <- nrow(x$model) - 2
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
                                   checkboxInput("logyProjGraph", "Függőleges tengely logaritmikus"),
                                   numericInput("projperiodsGraph", "Előrejelzett napok száma", 3, 1, 14, 1)
                            ),
                            column(3,
                                   checkboxInput("fitciProjGraph", "Konfidenciaintervallum megjelenítése"),
                                   conditionalPanel("input.fitciProjGraph==1",
                                                    numericInput("ciconfProjGraph", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            ),
                            column(3,
                                   sliderInput("windowProjGraph", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                               nrow(RawData), c(1, nrow(RawData)), 1)
                            )
                          )
                 ), 
                 tabPanel("Empirikus (számszerű)",
                          rhandsontable::rHandsontableOutput("projEmpTab"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("projperiodsTab", "Előrejelzett napok száma", 3, 1, 14, 1)
                            ),
                            column(3,
                                   numericInput("ciconfProjTab", "Megbízhatósági szint [%]:", 95, 0, 100, 1)
                            ),
                            column(3,
                                   sliderInput("windowProjTab", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                               nrow(RawData), c(1, nrow(RawData)), 1)
                            )
                          )
                 ), 
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("projExplanation.md")))
               )
             )
    ),
    tabPanel("R becslés növekedési ráta alapján",
             fluidPage(
               tabsetPanel(
                 tabPanel("Eloszlás (teljes vagy ablakozott görbe)",
                          h4("A teljes, vagy ablakozott görbe alapján számolt R, és a becslés bizonytalanságát ",
                             "jellemző eloszlása"),
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
                 tabPanel("Számszerű adatok (teljes vagy ablakozott görbe)",
                          h4("Az R becslésének adatai"),
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
                 tabPanel("Grafikon (csúszóablak)",
                          h4("Az R alakulása az időben"),
                          plotOutput("grSwGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuGrSwGraph", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdGrSwGraph", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowLenGrSwGraph", "Csúszóablak szélessége [nap]:", 1, nrow(RawData), 7, 1)
                            )
                          )
                 ), 
                 tabPanel("Számszerű adatok (csúszóablak)",
                          h4("Az R becslésének adatai"),
                          rhandsontable::rHandsontableOutput("grSwTab"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuGrSwTab", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdGrSwTab", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowLenGrSwTab", "Csúszóablak szélessége [nap]:", 1, nrow(RawData), 7, 1)
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("grExplanation.md")))
               )
             )
    ),
    tabPanel("R becslés elágazó folyamat-elven",
             fluidPage(
               tabsetPanel(
                 tabPanel("Eloszlás (teljes vagy ablakozott görbe)",
                          h4("A teljes, vagy ablakozott görbe alapján számolt R, és a becslés bizonytalanságát ",
                             "jellemző eloszlása"),
                          plotOutput("branchGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuBranchGraph", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdBranchGraph", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowBranchGraph", "Ablakozás a görbeillesztéshez [nap]:", 2,
                                               nrow(RawData), c(2, nrow(RawData)), 1)
                            )
                          )
                 ), 
                 tabPanel("Számszerű adatok (teljes vagy ablakozott görbe)",
                          h4("Az R becslésének adatai"),
                          rhandsontable::rHandsontableOutput("branchTab"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuBranchTab", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdBranchTab", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowBranchTab", "Ablakozás a görbeillesztéshez [nap]:", 2,
                                               nrow(RawData), c(2, nrow(RawData)), 1)
                            )
                          )
                 ),
                 tabPanel("Grafikon (csúszóablak)",
                          h4("Az R alakulása az időben"),
                          plotOutput("branchSwGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuBranchSwGraph", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdBranchSwGraph", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowLenBranchSwGraph", "Csúszóablak szélessége [nap]:", 1, nrow(RawData), 7, 1)
                            )
                          )
                 ), 
                 tabPanel("Számszerű adatok (csúszóablak)",
                          h4("Az R becslésének adatai"),
                          rhandsontable::rHandsontableOutput("branchSwTab"),
                          hr(),
                          fluidRow(
                            column(3,
                                   numericInput("SImuBranchSwTab", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("SIsdBranchSwTab", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("windowLenBranchSwTab", "Csúszóablak szélessége [nap]:", 1, nrow(RawData), 7, 1)
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("branchExplanation.md")))
               )
             )
    ),
    tabPanel("S(E)IR modellek",
             fluidPage(
               tabsetPanel(
                 tabPanel("Grafikon",
                          h4("TODO")
                          # h4("Az egész görbe alapján számolt R, és a becslés bizonytalanságát jellemző eloszlása:"),
                          # plotOutput("branchFullGraph"),
                          # hr(),
                          # fluidRow(
                          #   column(3,
                          #          numericInput("SImu", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                          #          numericInput("SIsd", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                          #   )
                          # )
                 )#, 
                 #tabPanel("Számszerű adatok", rhandsontable::rHandsontableOutput("projTab")), 
                 #tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    ),
    tabPanel("Automatikus jelentésgenerálás",
             numericInput("ciconfReport", "Megbízhatósági szint [%]:", 95, 0, 100, 1),
             numericInput("SImuReport", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
             numericInput("SIsdReport", "A serial interval szórása:", 4.75, 0.01, 20, 0.01),
             downloadButton("report", "Jelentés letöltése (PDF)")
    ),  widths = c(2, 8)
  )
)

server <- function(input, output, session) {
  
  output$epicurveGraph <- renderPlot({
    pred <- as.data.table(exp(predict(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                         subset = NumDate>=(input$windowEpicurve[1]-1)&NumDate<=(input$windowEpicurve[2]-1)),
                                      newdata = RawData, interval = "confidence", level = input$ciconfEpicurve/100)))
    pred$Date <- RawData$Date
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
                                         subset = NumDate>=input$windowProjGraph[1]&NumDate<=input$windowProjGraph[2]),
                                      newdata = data.table(NumDate = 0:(nrow(RawData)+input$projperiodsGraph-1)),
                                      interval = "confidence", level = input$ciconfProjGraph/100)))
    pred$Date <- seq.Date(min(RawData$Date), max(RawData$Date)+input$projperiodsGraph, by = "days")
    ggplot(RawData, aes(x = Date, y = CaseNumber)) +
      geom_point(size = 3) + geom_line(data = pred, aes(y = fit), col = "red") + labs(x = "Dátum", y = "Esetszám [fő]") +
      {if(input$fitciProjGraph) geom_ribbon(data = pred, aes(y = fit, ymin = lwr, ymax = upr), fill = "red", alpha = 0.2)} +
      {if(input$logyProjGraph) scale_y_log10()}
  })
  
  output$projEmpTab <- rhandsontable::renderRHandsontable({
    pred <- as.data.table(exp(predict(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                         subset = NumDate>=(input$windowProjTab[1]-1)&NumDate<=(input$windowProjTab[2]-1)),
                                      newdata = data.table(NumDate = 0:(nrow(RawData)+input$projperiodsTab-1)),
                                      interval = "confidence", level = input$ciconfProjTab/100)))
    pred$Date <- seq.Date(min(RawData$Date), max(RawData$Date)+input$projperiodsTab, by = "days")
    pred$CaseNumber <- c(RawData$CaseNumber, rep(NA, input$projperiodsTab))
    rhandsontable::rhandsontable(pred[,c("Date", "CaseNumber", "fit", "lwr", "upr")],
                                 colHeaders = c("Dátum", "Esetszám [fő]", "Becsült esetszám [fő]",
                                                "95% CI alsó széle [fő]", "95% CI felső széle [fő]"), readOnly = TRUE)
  })
  
  output$grGraph <- renderPlot({
    res <- data.frame(R0 = lm2R0gamma_sample(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                                subset = NumDate>=(input$windowGrGraph[1]-1)&
                                                  NumDate<=(input$windowGrGraph[2]-1)), input$SImuGrGraph, input$SImuGrGraph))
    ggplot(res,aes(R0)) + geom_density() + labs(y = "") + xlim(c(0.9, NA)) + geom_vline(xintercept = 1, col = "red", size = 2) +
      expand_limits(x = 1)
  })
  
  output$grTab <- rhandsontable::renderRHandsontable({
    res <- summary(lm2R0gamma_sample(lm(log(CaseNumber) ~ NumDate, data = RawData,
                                        subset = NumDate>=(input$windowGrTab[1]-1)&NumDate<=(input$windowGrTab[2]-1)),
                                     input$SImuGrTab, input$SImuGrTab))
    rhandsontable::rhandsontable(data.table(`Változó` = c("Minimum", "Alsó kvartilis", "Medián", "Átlag",
                                                          "Felső kvartilis", "Maximum" ),
                                            `Érték` = as.numeric(res) ), readOnly = TRUE)
  })
  
  output$grSwGraph <- renderPlot({
    res <- zoo::rollapply(RawData$CaseNumber, input$windowLenGrSwGraph, function(cn)
      lm2R0gamma_sample(lm(log(cn) ~ I(1:input$windowLenGrSwGraph)), input$SImuGrSwGraph, input$SIsdGrSwGraph))
    res <- data.table(do.call(rbind, lapply(1:nrow(res), function(i)
      c( mean(res[i,], na.rm = TRUE), quantile(res[i,], c(0.025, 0.975), na.rm = TRUE)))), check.names = TRUE)
    res$Date <- RawData$Date[input$windowLenGrSwGraph:nrow(RawData)]
    ggplot(res,aes(x = Date)) + geom_line(aes(y = V1), col = "blue") +
      geom_ribbon(aes(ymin = X2.5., ymax = X97.5.), fill = "blue", alpha = 0.2) + geom_hline(yintercept = 1, color = "red") +
      labs(x = "Dátum", y = "R") + expand_limits(y = 1)
  })
  
  output$grSwTab <- rhandsontable::renderRHandsontable({
    res <- zoo::rollapply(RawData$CaseNumber, input$windowLenGrSwTab, function(cn)
      lm2R0gamma_sample(lm(log(cn) ~ I(1:input$windowLenGrSwTab)), input$SImuGrSwTab, input$SImuGrSwTab))
    res <- data.table(do.call(rbind, lapply(1:nrow(res), function(i)
      c( mean(res[i,], na.rm = TRUE), quantile(res[i,], c(0.025, 0.975), na.rm = TRUE)))), check.names = TRUE)
    res$Date <- RawData$Date[input$windowLenGrSwTab:nrow(RawData)]
    rhandsontable::rhandsontable(res[,c(4,1:3)], colHeaders = c("Dátum", "R", "95% CI alsó széle [fő]",
                                                                "95% CI felső széle [fő]"), readOnly = TRUE)
  })
  
  output$branchGraph <- renderPlot({
    res <- data.table(R0 = EpiEstim::sample_posterior_R(EpiEstim::estimate_R(
      RawData$CaseNumber, method = "parametric_si",
      config = EpiEstim::make_config(list(mean_si = input$SImuBranchGraph, std_si = input$SIsdBranchGraph,
                                          t_start = input$windowBranchGraph[1], t_end = input$windowBranchGraph[2])))))
    ggplot(res,aes(R0)) + geom_density() + labs(y = "") + xlim(c(0.9, NA)) + geom_vline(xintercept = 1, col = "red", size = 2) +
      expand_limits(x = 1)
  })
  
  output$branchTab <- rhandsontable::renderRHandsontable({
    res <- summary(EpiEstim::sample_posterior_R(EpiEstim::estimate_R(
      RawData$CaseNumber, method = "parametric_si",
      config = EpiEstim::make_config(list(mean_si = input$SImuBranchTab, std_si = input$SIsdBranchTab,
                                          t_start = input$windowBranchTab[1], t_end = input$windowBranchTab[2])))))
    rhandsontable::rhandsontable(data.table(`Változó` = c("Minimum", "Alsó kvartilis", "Medián", "Átlag",
                                                          "Felső kvartilis", "Maximum" ),
                                            `Érték` = as.numeric(res) ), readOnly = TRUE)
  })
  
  output$branchSwGraph <- renderPlot({
    res <- EpiEstim::estimate_R(RawData$CaseNumber, method = "parametric_si",
                                config = EpiEstim::make_config(list(mean_si = input$SImuBranchGraph,
                                                                    std_si = input$SIsdBranchGraph)))$R
    res$Date <- RawData$Date[(input$windowLenGrSwGraph+1):nrow(RawData)]
    ggplot(res,aes(x = Date)) + geom_line(aes(y = `Mean(R)`), col = "blue") +
      geom_ribbon(aes(ymin = `Quantile.0.025(R)`, ymax = `Quantile.0.975(R)`), fill = "blue", alpha = 0.2) +
      geom_hline(yintercept = 1, color = "red") + labs(x = "Dátum", y = "R") + expand_limits(y = 1)
  })
  
  output$branchSwTab <- rhandsontable::renderRHandsontable({
    res <- EpiEstim::estimate_R(RawData$CaseNumber, method = "parametric_si",
                                config = EpiEstim::make_config(list(mean_si = input$SImuBranchGraph,
                                                                    std_si = input$SIsdBranchGraph)))$R
    res$Date <- RawData$Date[(input$windowLenGrSwGraph+1):nrow(RawData)]
    rhandsontable::rhandsontable(res[,c("Date", "Mean(R)", "Quantile.0.025(R)", "Quantile.0.975(R)")],
                                 colHeaders = c("Dátum", "R", "95% CrI alsó széle [fő]","95% CrI felső széle [fő]"),
                                 readOnly = TRUE)
  })
  
  output$report <- downloadHandler(
    filename <- paste0("JarvanyugyiJelentes_", Sys.Date(), ".pdf" ),
    content = function(file) {
      td <- tempdir()
      tempReport <- file.path(td, "report.Rmd")
      tempRawData <- file.path(td, "RawData.dat")
      file.copy("report.Rmd", tempReport, overwrite = TRUE)
      file.copy("RawData.dat", tempRawData, overwrite = TRUE)
      params <- list(ciconfReport = input$ciconfReport, SImuReport = input$SImuReport, SIsdReport = input$SIsdReport)
      rmarkdown::render(tempReport, output_file = file, params = params, envir = new.env(parent = globalenv()))
    }
  )
}

shinyApp( ui = ui, server = server )