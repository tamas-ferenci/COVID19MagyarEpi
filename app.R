library(shiny)
library(ggplot2)
library(data.table)

RawData <- readRDS("RawData.dat")

predData <- function(rd, dist, level, wind, projper = 0, deltar = NA) {
  if(projper>0) rd <- rbind(rd, data.table(Date = seq.Date(tail(rd$Date,1), tail(rd$Date,1)+projper, by = "days"),
                                           CaseNumber = NA,
                                           NumDate = tail(rd$NumDate,1):(tail(rd$NumDate,1)+projper)))
  rd$Predicted <- is.na(rd$CaseNumber)
  crit.value <- qt(1-(1-level/100)/2, df = sum(!rd$Predicted)-2)
  if(dist=="Lognormális") {
    m <- lm(log(CaseNumber) ~ Date, data = rd[CaseNumber!=0], subset = NumDate>=(wind[1]-1)&NumDate<=(wind[2]-1))
  } else if(dist=="Poisson") {
    m <- glm(CaseNumber ~ Date, data = rd, subset = NumDate>=(wind[1]-1)&NumDate<=(wind[2]-1), family = poisson(link = "log"))
  } else if(dist=="Negatív binomiális") {
    m <- MASS::glm.nb(CaseNumber ~ Date, data = rd, subset = NumDate>=(wind[1]-1)&NumDate<=(wind[2]-1))
  }
  if(!is.na(deltar)) m <- update(m, formula = as.formula(paste0(".~.+offset(", deltar, "*Predicted*(NumDate-",
                                                                sum(!rd$Predicted)-1,"))")))
  pred <- data.table(rd, with(predict(m, newdata = rd, se.fit = TRUE),
                              data.table(fit = exp(fit), lwr = exp(fit - (crit.value * se.fit)),
                                         upr = exp(fit + (crit.value * se.fit)))))
  list(pred = pred, m = m)
}

r2R0gamma <- function(r, si_mean, si_sd) {
  (1+r*si_sd^2/si_mean)^(si_mean^2/si_sd^2)
}
lm2R0gamma_sample <- function(x, si_mean, si_sd, n = 1000) {
  df <- nrow(x$model) - 2
  r <- x$coefficients[2]
  std_r <- stats::coef(summary(x))[, "Std. Error"][2]
  r_sample <- r + std_r * stats::rt(n, df)
  r2R0gamma(r_sample, si_mean, si_sd)
}

round_dt <- function(dt, digits = 2) as.data.table(dt, keep.rownames = TRUE)[, lapply(.SD, function(x)
  if(is.numeric(x)&!is.integer(x)) format(round(x, digits), nsmall = digits, trim = TRUE) else x)]

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
                                                                     radioButtons("epicurveDist", "Eloszlás:",
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
                                   radioButtons("projempDist", "Eloszlás:", c( "Lognormális", "Poisson", "Negatív binomiális")),
                                   sliderInput("projempWindow", "Ablakozás a görbeillesztéshez [nap]:", 1,
                                               nrow(RawData), c(1, nrow(RawData)), 1)
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
  ),
  h4( "Írta: Ferenci Tamás (Óbudai Egyetem, Élettani Szabályozások Kutatóközpont), v0.09" ),
  
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
    predData(RawData, input$epicurveDist, input$epicurveConf, input$epicurveWindow)
  })
  
  output$epicurveGraph <- renderPlot({
    if(input$epicurveExpfit) pred <- dataInputEpicurve()$pred
    ggplot(RawData, aes(x = Date, y = CaseNumber)) + geom_point(size = 3) + labs(x = "Dátum", y = "Napi esetszám [fő/nap]") +
      {if(input$epicurveLogy) scale_y_log10()} +
      {if(input$epicurveExpfit) geom_line(data = pred, aes(y = fit), col = "red")} +
      {if(input$epicurveExpfit&input$epicurveCi)
        geom_ribbon(data = pred, aes(y = fit, ymin = lwr, ymax = upr), fill = "red", alpha = 0.2)} +
      {if(input$epicurveLoessfit) geom_smooth(data = subset(RawData, NumDate>=(input$epicurveWindow[1]-1)&
                                                              NumDate<=(input$epicurveWindow[2]-1)),
                                              formula = y ~ x, method = "loess", col = "blue", se = input$epicurveCi,
                                              fill = "blue", alpha = 0.2, level = input$epicurveConf/100, size = 0.5)}
  })
  
  output$epicurveText <- renderText({
    m <- dataInputEpicurve()$m
    paste0("A fenti exponenciális illesztéssel a növekedési ráta ", round_dt(coef(m))[rn=="Date", -"rn"], " (95%-os CI: ",
           paste0(round_dt(confint(m))[rn=="Date", -"rn"], collapse = " - "), "). Ez azt jelenti, hogy a duplázódási idő ",
           "(az ahhoz szükséges idő, hogy a napi esetszám kétszeresére nőjön) ", round_dt(log(2)/coef(m))[rn=="Date", -"rn"],
           " nap (95%-os CI: ", paste0(rev(round_dt(log(2)/confint(m))[rn=="Date", -"rn"]), collapse = " - "), ").")
  })
  
  output$epicurveTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[,c("Date", "CaseNumber")],
                                 colHeaders = c("Dátum", "Napi esetszám [fő/nap]"), readOnly = TRUE)
  })
  
  dataInputProjemp <- reactive({
    predData(RawData, input$projempDist, input$projempConf, input$projempWindow, input$projempPeriods,
             if(input$projempFuture=="Tényadat") 0 else input$projempDeltar)
  })
  
  output$projempGraph <- renderPlot({
    pred <- dataInputProjemp()$pred
    ggplot(RawData, aes(x = Date, y = CaseNumber)) + labs(x = "Dátum", y = "Napi esetszám [fő/nap]") +
      geom_point(size = 3) + geom_line(data = pred, aes(y = fit, color = is.na(CaseNumber)), show.legend = FALSE) +
      {if(input$projempCi) geom_ribbon(data = pred, aes(y = fit, ymin = lwr, ymax = upr, fill = is.na(CaseNumber)),
                                       alpha = 0.2, show.legend = FALSE)} +
      {if(input$projempLogy) scale_y_log10()}
  })
  
  output$projempGraphText <- renderText({
    m <- dataInputProjemp()$m
    delta <- if(input$projempFuture=="Tényadat") 0 else input$projempDeltar 
    paste0("A jövőbeli növekedési ráta ", round_dt(coef(m)+delta)[rn=="Date", -"rn"], " (95%-os CI: ",
           paste0(round_dt(confint(m)+delta)[rn=="Date", -"rn"], collapse = " - "),
           "). Ez azt jelenti, hogy a duplázódási idő (az ahhoz szükséges idő, hogy a napi esetszám kétszeresére nőjön) ",
           round_dt(log(2)/(coef(m)+delta))[rn=="Date", -"rn"], " nap (95%-os CI: ",
           paste0(rev(round_dt(log(2)/(confint(m)+delta))[rn=="Date", -"rn"]), collapse = " - "), ").")
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
  
  output$grGraph <- renderPlot({
    res <- data.frame(R = lm2R0gamma_sample(lm(log(CaseNumber) ~ NumDate, data = RawData[CaseNumber!=0],
                                               subset = NumDate>=(input$windowGrGraph[1]-1)&
                                                 NumDate<=(input$windowGrGraph[2]-1)), input$SImuGrGraph, input$SImuGrGraph))
    ggplot(res,aes(R)) + geom_density() + labs(y = "") + geom_vline(xintercept = 1, col = "red", size = 2) + expand_limits(x = 1)
  })
  
  output$grTab <- rhandsontable::renderRHandsontable({
    res <- summary(lm2R0gamma_sample(lm(log(CaseNumber) ~ NumDate, data = RawData[CaseNumber!=0],
                                        subset = NumDate>=(input$windowGrTab[1]-1)&NumDate<=(input$windowGrTab[2]-1)),
                                     input$SImuGrTab, input$SImuGrTab))
    rhandsontable::rhandsontable(data.table(`Változó` = c("Minimum", "Alsó kvartilis", "Medián", "Átlag",
                                                          "Felső kvartilis", "Maximum"),
                                            `Érték` = as.numeric(res)), readOnly = TRUE)
  })
  
  output$grSwGraph <- renderPlot({
    res <- zoo::rollapply(RawData$CaseNumber, input$windowLenGrSwGraph, function(cn)
      lm2R0gamma_sample(lm(log(cn[cn!=0]) ~ I(1:input$windowLenGrSwGraph)[cn!=0]), input$SImuGrSwGraph, input$SIsdGrSwGraph))
    res <- data.table(do.call(rbind, lapply(1:nrow(res), function(i)
      c( mean(res[i,], na.rm = TRUE), quantile(res[i,], c(0.025, 0.975), na.rm = TRUE)))), check.names = TRUE)
    res$Date <- RawData$Date[input$windowLenGrSwGraph:nrow(RawData)]
    ggplot(res,aes(x = Date)) + geom_line(aes(y = V1), col = "blue") +
      geom_ribbon(aes(ymin = X2.5., ymax = X97.5.), fill = "blue", alpha = 0.2) + geom_hline(yintercept = 1, color = "red") +
      labs(x = "Dátum", y = "R") + expand_limits(y = 1)
  })
  
  output$grSwTab <- rhandsontable::renderRHandsontable({
    res <- zoo::rollapply(RawData$CaseNumber, input$windowLenGrSwTab, function(cn)
      lm2R0gamma_sample(lm(log(cn[cn!=0]) ~ I(1:input$windowLenGrSwTab)[cn!=0]), input$SImuGrSwTab, input$SImuGrSwTab))
    res <- data.table(do.call(rbind, lapply(1:nrow(res), function(i)
      c( mean(res[i,], na.rm = TRUE), quantile(res[i,], c(0.025, 0.975), na.rm = TRUE)))), check.names = TRUE)
    res$Date <- RawData$Date[input$windowLenGrSwTab:nrow(RawData)]
    rhandsontable::rhandsontable(round_dt(res)[, .(`Dátum` = Date, `R (95%-os CI)` = paste0(V1, " (", X2.5., "-", X97.5., ")"))],
                                 readOnly = TRUE)
  })
  
  output$branchGraph <- renderPlot({
    res <- data.table(R = EpiEstim::sample_posterior_R(EpiEstim::estimate_R(
      RawData$CaseNumber, method = "parametric_si",
      config = EpiEstim::make_config(list(mean_si = input$SImuBranchGraph, std_si = input$SIsdBranchGraph,
                                          t_start = input$windowBranchGraph[1], t_end = input$windowBranchGraph[2])))))
    ggplot(res,aes(R)) + geom_density() + labs(y = "") + geom_vline(xintercept = 1, col = "red", size = 2) + expand_limits(x = 1)
  })
  
  output$branchTab <- rhandsontable::renderRHandsontable({
    res <- summary(EpiEstim::sample_posterior_R(EpiEstim::estimate_R(
      RawData$CaseNumber, method = "parametric_si",
      config = EpiEstim::make_config(list(mean_si = input$SImuBranchTab, std_si = input$SIsdBranchTab,
                                          t_start = input$windowBranchTab[1], t_end = input$windowBranchTab[2])))))
    rhandsontable::rhandsontable(data.table(`Változó` = c("Minimum", "Alsó kvartilis", "Medián", "Átlag",
                                                          "Felső kvartilis", "Maximum" ),
                                            `Érték` = as.numeric(res)), readOnly = TRUE)
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
    rhandsontable::rhandsontable(round_dt(res)[, .(`Dátum` = Date,
                                                   `R (95%-os CrI)` = paste0(`Mean(R)`, " (",`Quantile.0.025(R)`, "-",
                                                                             `Quantile.0.975(R)`, ")"))], readOnly = TRUE)
  })
  
  output$report <- downloadHandler(
    filename <- paste0("JarvanyugyiJelentes_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf" ),
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