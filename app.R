library(shiny)
library(ggplot2)
library(data.table)

RawData <- readRDS("RawData.dat")

source("EpiHelpers.R", encoding = "UTF-8")

ui <- fluidPage(
  theme = "owntheme.css",
  
  tags$head(
    tags$script(async = NA, src = "https://www.googletagmanager.com/gtag/js?id=UA-19799395-3"),
    tags$script(HTML("
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
                       
    gtag('config', 'UA-19799395-3');
    ")),
    tags$meta(name = "description", content = paste0("A magyarországi koronavírus járvány valós idejű epidemiológiáját ",
                                                     "bemutató, annak elemzését lehetővé tevő alkalmazás alkalmazás. ",
                                                     "Írta: Ferenci Tamás.")),
    tags$meta(property = "og:title", content = "A magyarországi koronavírus járvány valós idejű epidemiológiája" ),
    tags$meta(property = "og:type", content = "website"),
    tags$meta(property = "og:locale", content = "hu_HU"),
    tags$meta(property = "og:url", content = "https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/"),
    tags$meta(property = "og:image", content = "https://research.physcon.uni-obuda.hu/COVID19MagyarEpi_Pelda.png"),
    tags$meta(property = "og:description", content = paste0("A magyarországi koronavírus járvány valós idejű epidemiológiáját ",
                                                            "bemutató, annak elemzését lehetővé tevő alkalmazás alkalmazás. ",
                                                            "Írta: Ferenci Tamás.")),
    tags$meta(name = "DC.Title", content = "A magyarországi koronavírus járvány valós idejű epidemiológiája"),
    tags$meta(name = "DC.Creator", content = "Ferenci Tamás"),
    tags$meta(name = "DC.Subject", content = "epidemiológia"),
    tags$meta(name = "DC.Description", content = paste0("A magyarországi koronavírus járvány valós idejű epidemiológiáját ",
                                                        "bemutató, annak elemzését lehetővé tevő alkalmazás alkalmazás. ",
                                                        "Írta: Ferenci Tamás.")),
    tags$meta(name = "DC.Publisher", content = "https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/"),
    tags$meta(name = "DC.Contributor", content = "Ferenci Tamás"),
    tags$meta(name = "DC.Language", content = "hu_HU")
  ),
  
  tags$div(id = "fb-root"),
  tags$script(async = NA, defer = NA, crossorigin = "anonymous",
              src = "https://connect.facebook.net/hu_HU/sdk.js#xfbml=1&version=v6.0"),
  
  tags$style(".shiny-file-input-progress {display: none}"),
  
  titlePanel("A magyarországi koronavírus járvány valós idejű epidemiológiája"),
  
  p("A weboldal és az elemzések teljes forráskódja ",
    a("itt", href = "https://github.com/tamas-ferenci/COVID19MagyarEpi", target = "_blank"),
    " érhető el. Írta: Ferenci Tamás."),
  div(class="fb-like", "data-href"="https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/",
      "data-width" = "", "data-layout"="standard", "data-action"="like", "data-size"="small", "data-share"="true"), p(),
  
  navlistPanel(
    tabPanel("Magyarázat", withMathJax(includeMarkdown("generalExplanation.md"))),
    tabPanel("Járványgörbe",
             fluidPage(
               tabsetPanel(
                 tabPanel("Járványgörbe",
                          conditionalPanel("input.epicurveType=='Grafikon'", plotOutput("epicurveGraph")),
                          conditionalPanel("input.epicurveType=='Táblázat'", rhandsontable::rHandsontableOutput("epicurveTab")),
                          conditionalPanel("input.epicurveType=='Grafikon'&input.epicurveExpfit==1", textOutput("epicurveText")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("epicurveType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.epicurveType=='Grafikon'",
                                                    checkboxInput("epicurveLogy", "Függőleges tengely logaritmikus"),
                                                    checkboxInput("epicurveExpfit", "Exponenciális görbe illesztése"),
                                                    checkboxInput("epicurveLoessfit",
                                                                  "LOESS nem-paraméteres simítógörbe illesztése")
                                   )
                            ),
                            column(3,
                                   conditionalPanel("input.epicurveType=='Grafikon'",
                                                    conditionalPanel("input.epicurveExpfit==1",
                                                                     radioButtons("epicurveDistr", "Eloszlás:",
                                                                                  c( "Lognormális", "Poisson",
                                                                                     "Negatív binomiális"))),
                                                    conditionalPanel("input.epicurveExpfit==1|input.epicurveLoessfit==1",
                                                                     checkboxInput("epicurveCi",
                                                                                   "Konfidenciaintervallum megjelenítése")),
                                                    conditionalPanel(
                                                      "(input.epicurveExpfit==1|input.epicurveLoessfit==1)&input.epicurveCi==1",
                                                      numericInput("epicurveConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)))
                            ),
                            column(3,
                                   conditionalPanel(
                                     "(input.epicurveExpfit==1|input.epicurveLoessfit==1)&input.epicurveType=='Grafikon'",
                                     sliderInput("epicurveWindow", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                                 nrow(RawData), c(1, nrow(RawData)), 1))
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveExplanation.md")))
               )
             )
    ),
    tabPanel("Előrejelzések",
             fluidPage(
               tabsetPanel(
                 tabPanel("Empirikus",
                          conditionalPanel("input.projempType=='Grafikon'", plotOutput("projempGraph")),
                          conditionalPanel("input.projempType=='Táblázat'", rhandsontable::rHandsontableOutput("projempTab")),
                          textOutput("projempGraphText"),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("projempType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   numericInput("projempPeriods", "Előrejelzett napok száma", 3, 1, 14, 1),
                                   checkboxInput("projempCi", "Konfidenciaintervallum megjelenítése"),
                                   conditionalPanel("input.projempCi==1",
                                                    numericInput("projempConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)),
                                   conditionalPanel("input.projempType=='Grafikon'",
                                                    checkboxInput("projempLogy", "Függőleges tengely logaritmikus"))
                            ),
                            column(3,
                                   h4("Görbeillesztés paraméterei"),
                                   radioButtons("projempDistr", "Eloszlás", c( "Lognormális", "Poisson", "Negatív binomiális")),
                                   sliderInput("projempWindow", "Ablakozás", 1, nrow(RawData), c(1, nrow(RawData)), 1)
                            ),
                            column(3,
                                   radioButtons("projempFuture", "Jövőbeli növekedés:", c("Tényadat",
                                                                                          "Szcenárióelemzés (növekedési ráta)")),
                                   conditionalPanel("input.projempFuture=='Szcenárióelemzés (növekedési ráta)'",
                                                    numericInput("projempDeltar", "Növekedési ráta eltérítése", 0, -2, 2, 0.01))
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
                 tabPanel("Teljes (vagy ablakozott) görbe",
                          conditionalPanel("input.grType=='Grafikon'",
                                           h4("A teljes, vagy ablakozott görbe alapján számolt R, és a becslés ",
                                              "bizonytalanságát jellemző eloszlása"),
                                           plotOutput("grGraph")),
                          conditionalPanel("input.grType=='Táblázat'", rhandsontable::rHandsontableOutput("grTab")),
                          hr(),
                          fluidRow(
                            column(3, radioButtons("grType", "Megjelenítés", c("Grafikon", "Táblázat"))),
                            column(3,
                                   h4("Görbeillesztés paraméterei"),
                                   radioButtons("grDistr", "Eloszlás", c( "Lognormális", "Poisson", "Negatív binomiális")),
                                   sliderInput("grWindow", "Ablakozás:", 1, nrow(RawData), c(1, nrow(RawData)), 1)
                            ),
                            column(3,
                                   numericInput("grSImu", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("grSIsd", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            )
                          )
                 ),
                 tabPanel("Csúszóablak",
                          conditionalPanel("input.grSwType=='Grafikon'",
                                           h4("R alakulása az időben"),
                                           plotOutput("grSwGraph")),
                          conditionalPanel("input.grSwType=='Táblázat'", rhandsontable::rHandsontableOutput("grSwTab")),
                          hr(),
                          fluidRow(
                            column(3, radioButtons("grSwType", "Megjelenítés", c("Grafikon", "Táblázat"))),
                            column(3,
                                   h4("Görbeillesztés paraméterei"),
                                   radioButtons("grSwDistr", "Eloszlás", c( "Lognormális", "Poisson", "Negatív binomiális")),
                                   sliderInput("grSwWindow", "Ablakozás", 1, nrow(RawData), c(1, nrow(RawData)), 1)
                            ),
                            column(3,
                                   numericInput("grSwSImu", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("grSwSIsd", "A serial interval szórása:", 4.75, 0.01, 20, 0.01),
                                   sliderInput("grSwWindowlen", "Csúszóablak szélessége [nap]:", 1, nrow(RawData), 7, 1)
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
                 tabPanel("Teljes (vagy ablakozott) görbe)",
                          conditionalPanel("input.branchType=='Grafikon'",
                                           h4("A teljes, vagy ablakozott görbe alapján számolt R, és a becslés ",
                                              "bizonytalanságát jellemző eloszlása"),
                                           plotOutput("branchGraph")),
                          conditionalPanel("input.branchType=='Táblázat'", rhandsontable::rHandsontableOutput("branchTab")),
                          hr(),
                          fluidRow(
                            column(3, radioButtons("branchType", "Megjelenítés", c("Grafikon", "Táblázat"))),
                            column(3,
                                   numericInput("branchSImu", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("branchSIsd", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("branchWindow", "Ablakozás az R becsléshez [nap]:", 2,
                                               nrow(RawData), c(2, nrow(RawData)), 1)
                            )
                          )
                 ),
                 tabPanel("Csúszóablak",
                          conditionalPanel("input.branchSwType=='Grafikon'",
                                           h4("R alakulása az időben"),
                                           plotOutput("branchSwGraph")),
                          conditionalPanel("input.branchSwType=='Táblázat'", rhandsontable::rHandsontableOutput("branchSwTab")),
                          hr(),
                          fluidRow(
                            column(3, radioButtons("branchSwType", "Megjelenítés", c("Grafikon", "Táblázat"))),
                            column(3,
                                   numericInput("branchSwSImu", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
                                   numericInput("branchSwSIsd", "A serial interval szórása:", 4.75, 0.01, 20, 0.01)
                            ),
                            column(3,
                                   sliderInput("branchSwWindowlen", "Csúszóablak szélessége [nap]:", 1, nrow(RawData)-2, 7, 1)
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
             numericInput("reportConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1),
             numericInput("reportSImu", "A serial interval várható értéke:", 3.96, 0.01, 20, 0.01),
             numericInput("reportSIsd", "A serial interval szórása:", 4.75, 0.01, 20, 0.01),
             downloadButton("report", "Jelentés letöltése (PDF)")
    ),  widths = c(2, 8)
  ),
  h4( "Írta: Ferenci Tamás (Óbudai Egyetem, Élettani Szabályozások Kutatóközpont), v0.11" ),
  
  tags$script( HTML( "var sc_project=11601191; 
                      var sc_invisible=1; 
                      var sc_security=\"5a06c22d\";
                      var scJsHost = ((\"https:\" == document.location.protocol) ?
                      \"https://secure.\" : \"http://www.\");
                      document.write(\"<sc\"+\"ript type='text/javascript' src='\" +
                      scJsHost+
                      \"statcounter.com/counter/counter.js'></\"+\"script>\");" ),
               type = "text/javascript" )
)

server <- function(input, output, session) {
  
  dataInputEpicurve <- reactive({
    predData(RawData, input$epicurveDistr, input$epicurveConf, input$epicurveWindow)
  })
  
  output$epicurveGraph <- renderPlot({
    epicurvePlot(dataInputEpicurve()$pred, input$epicurveLogy, input$epicurveExpfit, input$epicurveLoessfit,
                 input$epicurveCi, input$epicurveConf)
  })
  
  output$epicurveText <- renderText({
    grText(dataInputEpicurve()$m, if(input$projempFuture=="Tényadat") 0 else input$projempDeltar)
  })
  
  output$epicurveTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[,c("Date", "CaseNumber")],
                                 colHeaders = c("Dátum", "Napi esetszám [fő/nap]"), readOnly = TRUE)
  })
  
  dataInputProjemp <- reactive({
    predData(RawData, input$projempDistr, input$projempConf, input$projempWindow, input$projempPeriods,
             if(input$projempFuture=="Tényadat") 0 else input$projempDeltar)
  })
  
  output$projempGraph <- renderPlot({
    epicurvePlot(dataInputProjemp()$pred, input$projempLogy, TRUE, FALSE, input$projempCi, NA)
  })
  
  output$projempGraphText <- renderText({
    grText(dataInputProjemp()$m, if(input$projempFuture=="Tényadat") 0 else input$projempDeltar, TRUE)
  })
  
  output$projempTab <- rhandsontable::renderRHandsontable({
    pred <- round_dt(dataInputProjemp()$pred)
    pred2 <- pred[, c("Date", "CaseNumber")]
    pred2$Pred <- if(input$projempCi) paste0(pred$fit, " (", pred$lwr, "-", pred$upr, ")") else pred$fit
    rhandsontable::rhandsontable(pred2, colHeaders = c( "Dátum", "Napi esetszám [fő/nap]",
                                                        if(input$projempCi) paste0("Becsült napi esetszám (", input$projempConf,
                                                                                   "%-os CI) [fő/nap]") else
                                                                                     "Becsült napi esetszám"), readOnly = TRUE)
  })
  
  dataInputGr <- reactive({
    predData(RawData, input$grDistr, 95, input$grWindow)
  })
  
  output$grGraph <- renderPlot({
    ggplot(grData(dataInputGr()$m, input$grSImu, input$grSIsd), aes(R)) + geom_density() + labs(y = "") +
      geom_vline(xintercept = 1, col = "red", size = 2) + expand_limits(x = 1)
  })
  
  output$grTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(data.table(
      `Változó` = c("Minimum", "Alsó kvartilis", "Medián", "Átlag", "Felső kvartilis", "Maximum"),
      `Érték` = as.numeric(summary(grData(dataInputGr()$m, input$grSImu, input$grSIsd)$R))), readOnly = TRUE)
  })
  
  dataInputGrSw <- reactive({
    lapply( 1:(nrow(RawData)-input$grSwWindowlen+1),
            function(i) predData(RawData[i:(i+input$grSwWindowlen-1)], input$grSwDistr, 95, input$grSwWindow)$m )
  })
  
  output$grSwGraph <- renderPlot({
    ggplot(grSwData(RawData, dataInputGrSw(), input$grSwSImu, input$grSwSIsd,input$grSwWindowlen), aes(x = Date)) +
      geom_line(aes(y = V1), col = "blue") + geom_ribbon(aes(ymin = X2.5., ymax = X97.5.), fill = "blue", alpha = 0.2) +
      geom_hline(yintercept = 1, color = "red") + labs(x = "Dátum", y = "R") + expand_limits(y = 1)
  })
  
  output$grSwTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(round_dt(grSwData(
      RawData, dataInputGrSw(), input$grSwSImu, input$grSwSIsd, input$grSwWindowlen))[
        , .(`Dátum` = Date, `R (95%-os CI)` = paste0(V1, " (", X2.5., "-", X97.5., ")"))], readOnly = TRUE)
  })
  
  output$branchGraph <- renderPlot({
    ggplot(branchData(RawData, input$branchSImu, input$branchSIsd, input$branchWindow), aes(R)) + geom_density() + labs(y = "") +
      geom_vline(xintercept = 1, col = "red", size = 2) + expand_limits(x = 1)
  })
  
  output$branchTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(data.table(
      `Változó` = c("Minimum", "Alsó kvartilis", "Medián", "Átlag", "Felső kvartilis", "Maximum" ),
      `Érték` = as.numeric(summary(branchData(RawData, input$branchSImu, input$branchSIsd, input$branchWindow)$R))),
      readOnly = TRUE)
  })
  
  output$branchSwGraph <- renderPlot({
    ggplot(branchSwData(RawData, input$branchSwSImu, input$branchSwSIsd, input$branchSwWindowlen), aes(x = Date)) +
      geom_line(aes(y = `Mean(R)`), col = "blue") +
      geom_ribbon(aes(ymin = `Quantile.0.025(R)`, ymax = `Quantile.0.975(R)`), fill = "blue", alpha = 0.2) +
      geom_hline(yintercept = 1, color = "red") + labs(x = "Dátum", y = "R") + expand_limits(y = 1)
  })
  
  output$branchSwTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(round_dt(branchSwData(
      RawData, input$branchSwSImu, input$branchSwSIsd, input$branchSwWindowlen))[
        , .(`Dátum` = Date, `R (95%-os CrI)` = paste0(`Mean(R)`, " (",`Quantile.0.025(R)`, "-", `Quantile.0.975(R)`, ")"))],
      readOnly = TRUE)
  })
  
  output$report <- downloadHandler(
    filename <- paste0("JarvanyugyiJelentes_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf" ),
    content = function(file) {
      td <- tempdir()
      tempReport <- file.path(td, "report.Rmd")
      tempRawData <- file.path(td, "RawData.dat")
      file.copy("report.Rmd", tempReport, overwrite = TRUE)
      file.copy("RawData.dat", tempRawData, overwrite = TRUE)
      params <- list(reportConf = input$reportConf, reportSImu = input$reportSImu, reportSIsd = input$reportSIsd)
      rmarkdown::render(tempReport, output_file = file, params = params, envir = new.env(parent = globalenv()))
    }
  )
}

shinyApp( ui = ui, server = server )