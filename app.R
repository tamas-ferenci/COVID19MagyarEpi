library(shiny)
library(ggplot2)
library(data.table)

RawData <- readRDS("RawData.rds")

SImuDefault <- 4.7
SIsdDefault <- 2.9

source("EpiHelpers.R", encoding = "UTF-8")
source("SeirModel.R", encoding = "UTF-8")
Sys.setlocale(locale = "hu_HU.utf8")
options(mc.cores = parallel::detectCores())
modCorrected <- readRDS("CFR_corrected_stan.rds")
modRealtime <- readRDS("CFR_realtime_stan.rds")
cfrsensgrid <- readRDS("cfrsensgrid.rds")
ExcessMort <- readRDS("ExcessMort.rds")
exclude_dates <- seq(as.Date("2020-03-01"), max(ExcessMort$date), by = "day")

ggsave169 <- function(...) ggsave(..., width = 16, height = 9)
fwritecsv <- function(...) fwrite(..., sep = ";", dec = ",", row.names = FALSE, bom = TRUE)

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
    tags$meta(name = "DC.Language", content = "hu_HU"),
    tags$style(".btn {margin-bottom:10px}")
  ),
  
  tags$div(id = "fb-root"),
  tags$script(async = NA, defer = NA, crossorigin = "anonymous",
              src = "https://connect.facebook.net/hu_HU/sdk.js#xfbml=1&version=v6.0"),
  
  tags$style(".shiny-file-input-progress {display: none}"),
  
  titlePanel("A magyarországi koronavírus járvány valós idejű epidemiológiája"),
  
  p("A weboldal és az elemzések teljes forráskódja ",
    a("itt", href = "https://github.com/tamas-ferenci/COVID19MagyarEpi", target = "_blank"),
    "érhető el. Írta: Ferenci Tamás. Az adatok utolsó frissítésének időpontja:", paste0(format(max(RawData$Date),
                                                                                               "%Y. %m. %d"), ".")),
  div(class="fb-like", "data-href"="https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/",
      "data-width" = "600", "data-layout"="standard", "data-action"="like", "data-size"="small", "data-share"="true"), p(),
  
  navlistPanel(
    tabPanel("Magyarázat", withMathJax(includeMarkdown("generalExplanation.md"))),
    tabPanel("Járványgörbe (esetszám)",
             fluidPage(
               tabsetPanel(
                 tabPanel("Járványgörbe (esetszám)",
                          conditionalPanel("input.epicurveIncType=='Grafikon'", plotOutput("epicurveIncGraph")),
                          conditionalPanel("input.epicurveIncType=='Táblázat'", rhandsontable::rHandsontableOutput("epicurveIncTab")),
                          conditionalPanel("input.epicurveIncType=='Grafikon'&input.epicurveIncFunfit==1", textOutput("epicurveIncText")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("epicurveIncType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.epicurveIncType=='Grafikon'",
                                                    downloadButton("epicurveIncGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("epicurveIncGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.epicurveIncType=='Táblázat'",
                                                    downloadButton("epicurveIncTabDlCSV", "A táblázat letöltése (CSV)")
                                   )
                            ),
                            column(3,
                                   conditionalPanel("input.epicurveIncType=='Grafikon'",
                                                    checkboxInput("epicurveIncLogy", "Függőleges tengely logaritmikus"),
                                                    checkboxInput("epicurveIncLoessfit", "Simítógörbe illesztése", TRUE),
                                                    checkboxInput("epicurveIncFunfit", "Függvény illesztése"),
                                                    conditionalPanel("input.epicurveIncFunfit==1|input.epicurveIncLoessfit==1",
                                                                     checkboxInput("epicurveIncCi",
                                                                                   "Konfidenciaintervallum megjelenítése",
                                                                                   TRUE)),
                                                    conditionalPanel(
                                                      "(input.epicurveIncFunfit==1|input.epicurveIncLoessfit==1)&input.epicurveIncCi==1",
                                                      numericInput("epicurveIncConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)))
                            ),
                            column(3,
                                   conditionalPanel("input.epicurveIncType=='Grafikon'&input.epicurveIncFunfit==1",
                                                    radioButtons("epicurveIncFform", "Függvényforma",
                                                                 c("Exponenciális", "Hatvány", "Logisztikus")),
                                                    dateRangeInput("epicurveIncWindow", "Ablakozás a függvényillesztéshez",
                                                                   min(RawData$Date), max(RawData$Date),
                                                                   min(RawData$Date), max(RawData$Date),
                                                                   weekstart = 1, language = "hu", separator = "-")
                                   )
                            ),
                            column(3,
                                   conditionalPanel("input.epicurveIncType=='Grafikon'&input.epicurveIncFunfit==1",
                                                    radioButtons("epicurveIncDistr", "Eloszlás",
                                                                 c("Lognormális", "Poisson", "NB/QP"), selected = "Poisson"))
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveIncExplanation.md")))
               )
             )
    ),
    tabPanel("Járványgörbe (halálozások száma)",
             fluidPage(
               tabsetPanel(
                 tabPanel("Járványgörbe (halálozások száma)",
                          conditionalPanel("input.epicurveMortType=='Grafikon'", plotOutput("epicurveMortGraph")),
                          conditionalPanel("input.epicurveMortType=='Táblázat'", rhandsontable::rHandsontableOutput("epicurveMortTab")),
                          conditionalPanel("input.epicurveMortType=='Grafikon'&input.epicurveMortFunfit==1", textOutput("epicurveMortText")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("epicurveMortType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.epicurveMortType=='Grafikon'",
                                                    downloadButton("epicurveMortGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("epicurveMortGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.epicurveMortType=='Táblázat'",
                                                    downloadButton("epicurveMortTabDlCSV", "A táblázat letöltése (CSV)")
                                   )
                            ),
                            column(3,
                                   conditionalPanel("input.epicurveMortType=='Grafikon'",
                                                    checkboxInput("epicurveMortLogy", "Függőleges tengely logaritmikus"),
                                                    checkboxInput("epicurveMortLoessfit", "Simítógörbe illesztése", TRUE),
                                                    checkboxInput("epicurveMortFunfit", "Függvény illesztése"),
                                                    conditionalPanel("input.epicurveMortFunfit==1|input.epicurveMortLoessfit==1",
                                                                     checkboxInput("epicurveMortCi",
                                                                                   "Konfidenciaintervallum megjelenítése",
                                                                                   TRUE)),
                                                    conditionalPanel(
                                                      "(input.epicurveMortFunfit==1|input.epicurveMortLoessfit==1)&input.epicurveMortCi==1",
                                                      numericInput("epicurveMortConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)))
                            ),
                            column(3,
                                   conditionalPanel("input.epicurveMortType=='Grafikon'&input.epicurveMortFunfit==1",
                                                    radioButtons("epicurveMortFform", "Függvényforma",
                                                                 c("Exponenciális", "Hatvány", "Logisztikus")),
                                                    dateRangeInput("epicurveMortWindow", "Ablakozás a függvényillesztéshez",
                                                                   min(RawData$Date), max(RawData$Date),
                                                                   min(RawData$Date), max(RawData$Date),
                                                                   weekstart = 1, language = "hu", separator = "-")
                                   )
                            ),
                            column(3,
                                   conditionalPanel("input.epicurveMortType=='Grafikon'&input.epicurveMortFunfit==1",
                                                    radioButtons("epicurveMortDistr", "Eloszlás",
                                                                 c("Lognormális", "Poisson", "NB/QP"), selected = "Poisson"))
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("epicurveMortExplanation.md")))
               )
             )
    ),
    tabPanel("Többlethalálozás",
             fluidPage(
               tabsetPanel(
                 tabPanel("Mortalitás alakulása",
                          plotOutput("excessmortGraph"),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("excessmortType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.excessmortType=='Grafikon'",
                                                    downloadButton("excessmortGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("excessmortGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.excessmortType=='Táblázat'",
                                                    downloadButton("excessmortTabDlCSV", "A táblázat letöltése (CSV)")
                                   )
                            ),
                            column(3,
                                   selectInput("excessmortStratify",
                                               "Rétegzés", c("Nincs", "Nem", "Életkor", "Nem és életkor"))
                            )
                          )
                 ),
                 tabPanel("Modellezett többlethalálozás",
                          conditionalPanel("input.excessmortModelType=='Grafikon'", plotOutput("excessmortModelGraph")),
                          conditionalPanel("input.excessmortModelType=='Táblázat'", rhandsontable::rHandsontableOutput("excessmortModelTab")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("excessmortModelType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.excessmortModelType=='Grafikon'",
                                                    downloadButton("excessmortModelGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("excessmortModelGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.excessmortModelType=='Táblázat'",
                                                    downloadButton("excessmortModelTabDlCSV", "A táblázat letöltése (CSV)")
                                   )
                            ),
                            column(3,
                                   selectInput("excessmortModelStratify",
                                               "Rétegzés", c("Nincs", "Nem", "Életkor", "Nem és életkor"))
                            )
                          )
                 ),
                 tabPanel("Többlethalálozás és regisztrált halálozás",
                          conditionalPanel("input.excessandobsmortType=='Grafikon'", plotOutput("excessandobsmortGraph")),
                          conditionalPanel("input.excessandobsmortType=='Táblázat'", rhandsontable::rHandsontableOutput("excessandobsmortTab")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("excessandobsmortType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.excessandobsmortType=='Grafikon'",
                                                    downloadButton("excessandobsmortGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("excessandobsmortGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.excessandobsmortType=='Táblázat'",
                                                    downloadButton("excessandobsmortTabDlCSV", "A táblázat letöltése (CSV)")
                                   )
                            ),
                            column(3,
                                   numericInput("excessandobsmortConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("excessmortExplanation.md")))
               )
             )
    ),
    tabPanel("Tesztpozitivitás",
             fluidPage(
               tabsetPanel(
                 tabPanel("Tesztpozitivitás",
                          conditionalPanel("input.testpositivityType=='Grafikon'", plotOutput("testpositivityGraph")),
                          conditionalPanel("input.testpositivityType=='Táblázat'", rhandsontable::rHandsontableOutput("testpositivityTab")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("testpositivityType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.testpositivityType=='Grafikon'",
                                                    downloadButton("testpositivityGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("testpositivityGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.testpositivityType=='Táblázat'",
                                                    downloadButton("testpositivityTabDlCSV", "A táblázat letöltése (CSV)")
                                   )
                            ),
                            column(3,
                                   conditionalPanel("input.testpositivityType=='Grafikon'",
                                                    checkboxInput("testpositivitySmoothfit", "Simítógörbe illesztése", TRUE),
                                                    conditionalPanel("input.testpositivitySmoothfit==1",
                                                                     checkboxInput("testpositivityCi",
                                                                                   "Konfidenciaintervallum megjelenítése",
                                                                                   TRUE)),
                                                    conditionalPanel(
                                                      "input.testpositivitySmoothfit==1&input.testpositivityCi==1",
                                                      numericInput("testpositivityConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)))
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("testpositivityExplanation.md")))
               )
             )
    ),
    tabPanel("Előrejelzések",
             fluidPage(
               tabsetPanel(
                 tabPanel("Empirikus (rövid távú)",
                          conditionalPanel("input.projempType=='Grafikon'", plotOutput("projempGraph")),
                          conditionalPanel("input.projempType=='Táblázat'", rhandsontable::rHandsontableOutput("projempTab")),
                          textOutput("projempGraphText"),
                          hr(),
                          fluidRow(
                            column(3, radioButtons("projempOutcome", "Vizsgált végpont",
                                                   c("Esetszám" = "CaseNumber", "Halálozások száma" = "DeathNumber"))),
                            column(3,
                                   radioButtons("projempType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   numericInput("projempPeriods", "Előrejelzett napok száma", 3, 1, 14, 1),
                                   conditionalPanel("input.projempType=='Grafikon'",
                                                    checkboxInput("projempLogy", "Függőleges tengely logaritmikus")),
                                   checkboxInput("projempLoessfit", "Simítógörbe illesztése", TRUE),
                                   checkboxInput("projempCi", "Konfidenciaintervallum megjelenítése", TRUE),
                                   conditionalPanel("input.projempCi==1",
                                                    numericInput("projempConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            ),
                            column(3,
                                   h4("Görbeillesztés paraméterei"),
                                   radioButtons("projempFform", "Függvényforma",
                                                c("Exponenciális", "Hatvány", "Logisztikus")),
                                   radioButtons("projempDistr", "Eloszlás", c( "Lognormális", "Poisson", "Negatív binomiális"),
                                                selected = "Poisson"),
                                   dateRangeInput("projempWindow", "Ablakozás",
                                                  max(RawData$Date)-14, max(RawData$Date),
                                                  min(RawData$Date), max(RawData$Date),
                                                  weekstart = 1, language = "hu", separator = "-")
                            ),
                            column(3,
                                   radioButtons("projempFuture", "Jövőbeli növekedés:", c("Tényadat",
                                                                                          "Szcenárióelemzés")),
                                   conditionalPanel("input.projempFuture=='Szcenárióelemzés'",
                                                    numericInput("projempDeltar", "Eltérítés", 0, -2, 2, 0.01),
                                                    dateInput("projempDeltarDate", "Időpontja", max(RawData$Date),
                                                              max(RawData$Date), max(RawData$Date)+14)
                                   )
                            )
                          )
                 ),
                 tabPanel("Kompartment-modell (hosszú távú)",
                          fluidRow(
                            column(8,                          
                                   conditionalPanel("input.projcompType=='Grafikon'", plotOutput("projcompGraph")),
                                   conditionalPanel("input.projcompType=='Táblázat'",
                                                    rhandsontable::rHandsontableOutput("projcompTab"))
                            ),
                            column(4,
                                   rhandsontable::rHandsontableOutput("projcompInput"),
                                   fluidRow(hr(), actionButton("projcompAddrow", "Új sor hozzáadása"),
                                            actionButton("projcompDeleterow", "Utolsó sor törlése")))
                          ),
                          #textOutput("projcompText"),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("projcompType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   dateInput("projcompEnd", "Előrevetítés vége", max(RawData$Date)+100, max(RawData$Date)+1,
                                             max(RawData$Date)+200),
                                   conditionalPanel("input.projcompType=='Grafikon'",
                                                    checkboxInput("projcompLogy", "Függőleges tengely logaritmikus"))
                            ),
                            column(3,
                                   numericInput("projcompIncub", "Inkubációs idő [nap]", 5, 0, 20, 0.1),
                                   numericInput("projcompInfect", "Fertőzőképesség hossza [nap]", 3, 0, 20, 0.1)
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("projExplanation.md")))
               )
             )
    ),
    tabPanel("Reprodukciós szám becslése",
             fluidPage(
               tabsetPanel(
                 tabPanel("Valós idejű",
                          conditionalPanel("input.reprRtType=='Grafikon'", plotOutput("reprRtGraph")),
                          conditionalPanel("input.reprRtType=='Táblázat'", rhandsontable::rHandsontableOutput("reprRtTab")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("reprRtType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   checkboxInput("reprRtCi", "Konfidenciaintervallum megjelenítése")),
                            column(3,
                                   checkboxGroupInput("reprRtMethods", "Módszerek",
                                                      c("Cori", "Wallinga-Lipsitch Exp/Poi", "Wallinga-Teunis",
                                                        "Bettencourt-Ribeiro"),
                                                      c("Cori", "Wallinga-Teunis"))),
                            column(3,
                                   sliderInput("reprRtWindowlen", "Csúszóablak szélessége [nap]:", 1, nrow(RawData), 7, 1),
                                   numericInput("reprRtSImu", "A serial interval várható értéke:", SImuDefault, 0.01, 20, 0.01),
                                   numericInput("reprRtSIsd", "A serial interval szórása:", SIsdDefault, 0.01, 20, 0.01),
                                   
                            )
                          )
                 ),
                 tabPanel("Teljes (vagy ablakozott) görbe",
                          conditionalPanel("input.reprType=='Grafikon'", plotOutput("reprGraph")),
                          conditionalPanel("input.reprType=='Táblázat'", rhandsontable::rHandsontableOutput("reprTab")),
                          hr(),
                          fluidRow(
                            column(3, radioButtons("reprType", "Megjelenítés", c("Grafikon", "Táblázat"))),
                            column(3,
                                   dateRangeInput("reprWindow", "Ablakozás",
                                                  min(RawData$Date), max(RawData$Date),
                                                  min(RawData$Date), max(RawData$Date),
                                                  weekstart = 1, language = "hu", separator = "-")
                                   
                            ),
                            column(3,
                                   numericInput("reprSImu", "A serial interval várható értéke:", SImuDefault, 0.01, 20, 0.01),
                                   numericInput("reprSIsd", "A serial interval szórása:", SIsdDefault, 0.01, 20, 0.01)
                            )
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("reprExplanation.md")))
               )
             )
    ),
    tabPanel("Halálozási arány és aluldetektálás",
             fluidPage(
               tabsetPanel(
                 tabPanel("Halálozási arány",
                          conditionalPanel("input.cfrType=='Grafikon'", plotOutput("cfrGraph")),
                          conditionalPanel("input.cfrType=='Táblázat'", rhandsontable::rHandsontableOutput("cfrTab")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("cfrType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   checkboxInput("cfrCi", "Konfidenciaintervallum megjelenítése"),
                                   conditionalPanel("input.cfrCi==1",
                                                    numericInput("cfrConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1))
                            ),
                            column(3,
                                   conditionalPanel("input.cfrType=='Grafikon'",
                                                    checkboxGroupInput("cfrToplot", "Megjelenítendő halálozási arányok",
                                                                       c("Nyers", "Korrigált", "Valós idejű"),
                                                                       selected = c("Nyers", "Korrigált")))
                            ),
                            column(5,
                                   numericInput("cfrDDTmu", "A diagnózis-halál idő várható értéke:", 13, 0.1, 20, 0.1),
                                   numericInput("cfrDDTsd", "A diagnózis-halál idő szórása:", 12.7, 0.1, 20, 0.1)
                            )
                          )
                 ),
                 tabPanel("Aluldetektálás",
                          textOutput("cfrUnderdetText"),
                          rhandsontable::rHandsontableOutput("cfrUnderdetTab"),
                          hr(),
                          column(3,
                                 numericInput("cfrUnderdetBench", "Benchmark halálozási arány", 0.8, 0, 100, 0.01)
                          ),
                          column(5,
                                 numericInput("cfrUnderdetDDTmu", "A diagnózis-halál idő várható értéke:", 13, 0.1, 20, 0.1),
                                 numericInput("cfrUnderdetDDTsd", "A diagnózis-halál idő szórása:", 12.7, 0.1, 20, 0.1)
                          )
                 ),
                 tabPanel("Érzékenységvizsgálat",
                          plotOutput("cfrSensGraph"),
                          hr(),
                          column(3,
                                 numericInput("cfrSensBench", "Benchmark halálozási arány", 0.8, 0, 100, 0.01)
                          )
                 ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("cfrExplanation.md")))
               )
             )
    ),
    tabPanel("Automatikus jelentésgenerálás",
             numericInput("reportConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1),
             numericInput("reportSImu", "A serial interval várható értéke:", SImuDefault, 0.01, 20, 0.01),
             numericInput("reportSIsd", "A serial interval szórása:", SIsdDefault, 0.01, 20, 0.01),
             downloadButton("report", "Jelentés letöltése (PDF)")
    ), widths = c(2, 8)
  ), hr(),
  h4("Írta: Ferenci Tamás (Óbudai Egyetem, Élettani Szabályozások Kutatóközpont), v0.37"),
  
  tags$script(HTML("var sc_project=11601191; 
                      var sc_invisible=1; 
                      var sc_security=\"5a06c22d\";
                      var scJsHost = ((\"https:\" == document.location.protocol) ?
                      \"https://secure.\" : \"http://www.\");
                      document.write(\"<sc\"+\"ript type='text/javascript' src='\" +
                      scJsHost+
                      \"statcounter.com/counter/counter.js'></\"+\"script>\");" ),
              type = "text/javascript")
)

server <- function(input, output, session) {
  
  observe(updateDateInput(session, "projempDeltarDate", max = max(RawData$Date)+input$projempPeriods-1))
  observe(updateDateInput(session, "projcompDeltaDate", max = input$projcompEnd))
  
  dataInputEpicurveInc <- reactive({
    predData(RawData, "CaseNumber", input$epicurveIncFform, input$epicurveIncDistr, input$epicurveIncConf,
             if(input$epicurveIncFunfit) input$epicurveIncWindow else NA)
  })
  
  output$epicurveIncGraph <- renderPlot({
    epicurvePlot(dataInputEpicurveInc(), "CaseNumber", input$epicurveIncLogy, input$epicurveIncFunfit,
                 input$epicurveIncLoessfit, input$epicurveIncCi, input$epicurveIncConf)
  })
  
  dataInputEpicurveMort <- reactive({
    predData(RawData, "DeathNumber", input$epicurveMortFform, input$epicurveMortDistr, input$epicurveMortConf,
             if(input$epicurveMortFunfit) input$epicurveMortWindow else NA)
  })
  
  output$epicurveMortGraph <- renderPlot({
    epicurvePlot(dataInputEpicurveMort(), "DeathNumber", input$epicurveMortLogy, input$epicurveMortFunfit,
                 input$epicurveMortLoessfit, input$epicurveMortCi, input$epicurveMortConf)
  })
  
  output$epicurveIncText <- renderText(grText(dataInputEpicurveInc()$m, input$epicurveIncFform, startDate = min(RawData$Date)))
  
  output$epicurveMortText <- renderText(grText(dataInputEpicurveMort()$m, input$epicurveMortFform, startDate = min(RawData$Date)))
  
  output$epicurveIncTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[,c("Date", "CaseNumber"), with = FALSE],
                                 colHeaders = c("Dátum", "Napi esetszám [fő/nap]"), readOnly = TRUE, height = 500)
  })
  
  output$epicurveMortTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[,c("Date", "DeathNumber"), with = FALSE],
                                 colHeaders = c("Dátum", "Napi halálozás-szám [fő/nap]"), readOnly = TRUE, height = 500)
  })
  
  output$epicurveIncGraphDlPDF <- downloadHandler(
    filename = paste0("JarvanygorbeEsetszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveInc(), "CaseNumber", input$epicurveIncLogy, input$epicurveIncFunfit,
                                                    input$epicurveIncLoessfit, input$epicurveIncCi, input$epicurveIncConf))
  )
  
  output$epicurveIncGraphDlPNG <- downloadHandler(
    filename = paste0("JarvanygorbeEsetszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveInc(), "CaseNumber", input$epicurveIncLogy, input$epicurveIncFunfit,
                                                    input$epicurveIncLoessfit, input$epicurveIncCi, input$epicurveIncConf))
  )
  
  output$epicurveIncTabDlCSV <- downloadHandler(
    filename = paste0("JarvanygorbeEsetszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(RawData[,.(`Dátum` = Date, `Napi esetszám [fő/nap]` = CaseNumber)], file)
  )
  
  output$epicurveMortGraphDlPDF <- downloadHandler(
    filename = paste0("JarvanygorbeHalalozasszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveMort(), "DeathNumber", input$epicurveMortLogy, input$epicurveMortFunfit,
                                                    input$epicurveMortLoessfit, input$epicurveMortCi, input$epicurveMortConf))
  )
  
  output$epicurveMortGraphDlPNG <- downloadHandler(
    filename = paste0("JarvanygorbeHalalozasszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveMort(), "DeathNumber", input$epicurveMortLogy, input$epicurveMortFunfit,
                                                    input$epicurveMortLoessfit, input$epicurveMortCi, input$epicurveMortConf))
  )
  
  output$epicurveMortTabDlCSV <- downloadHandler(
    filename = paste0("JarvanygorbeHalalozasszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(RawData[,.(`Dátum` = Date, `Napi halálozás-szám [fő/nap]` = DeathNumber)],file)
  )
  
  dataInputexcessmortGraph <- reactive({
    stratlist <- c("date", switch(input$excessmortStratify,
                                  "Nem" = "SEX", "Életkor" = "AGEf",
                                  "Nem és életkor" = c("AGEf", "SEX")))
    ggplot(ExcessMort[,.(outcome = sum(outcome), population = sum(population), isoyear = isoyear,
                         isoweek = isoweek), stratlist],
           aes(x = isoweek, y = outcome/population*1e5, group = isoyear,
               color = isoyear==2020, alpha = isoyear==2020)) + geom_line() +
      scale_alpha_manual(values = c(0.3, 1)) + guides(color = FALSE, alpha = FALSE) +
      {if(input$excessmortStratify=="Nem") facet_wrap(vars(SEX))} +
      {if(input$excessmortStratify=="Életkor") facet_wrap(vars(AGEf), scales = "free")} +
      {if(input$excessmortStratify=="Nem és életkor") facet_grid(AGEf ~ SEX, scales = "free")} +
      labs(x = "Hét sorszáma", y = "Mortalitás [/100 ezer fő/hét]") +
      theme(plot.caption = element_text(face = "bold", hjust = 0)) +
      labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: KSH")
  })
  
  output$excessmortGraph <- renderPlot(dataInputexcessmortGraph())
  
  output$excessmortGraphDlPDF <- downloadHandler(
    filename = paste0("Tobblethalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file, dataInputexcessmortGraph())
  )
  
  output$excessmortGraphDlPNG <- downloadHandler(
    filename = paste0("Tobblethalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file, dataInputexcessmortGraph())
  )
  
  output$excessmortTabDlCSV <- downloadHandler(
    filename = paste0("Tobblethalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(ExcessMort[,.(`Év` = isoyear, `Hét sorszáma` = isoweek,
                                                     `Nem` = SEX, `Korcsoport` = AGE, `Halálozások száma [fő]` = outcome,
                                                     `Háttérpopuláció [fő]` = population,
                                                     `Incidencia [fő/100e fő]` = incidence)], file)
  )
  
  dataInputExcessmortModel <- reactive({
    stratlist <- c("date", switch(input$excessmortModelStratify,
                                  "Nem" = "SEX", "Életkor" = "AGEf",
                                  "Nem és életkor" = c("AGEf", "SEX")))
    ExcessMort[,.(outcome = sum(outcome), population = sum(population)), stratlist][
      ,with(excessmort::excess_model(.SD, min(ExcessMort$date), max(ExcessMort$date),
                                     exclude = exclude_dates),
            list(date = date, observed = observed, expected = expected,
                 y = 100 * (observed - expected)/expected,
                 increase = 100 * fitted, se = 100 * se)),
      c(stratlist[-1])]
  })
  
  dataInputexcessmortModelGraph <- reactive({
    z <- qnorm(1 - 0.05/2)
    ggplot(dataInputExcessmortModel(), aes(x = date, y = y)) + geom_point(alpha = 0.5) +
      geom_line(aes(y = increase), col = "#3366FF") +
      geom_ribbon(aes(ymin = increase - z * se, ymax = increase + z * se), alpha = 0.5) +
      geom_hline(yintercept = 0) + 
      labs(x = "Dátum", y = "Százalékos eltérés a várt értéktől") +
      {if(input$excessmortModelStratify=="Nem") facet_wrap(vars(SEX))} +
      {if(input$excessmortModelStratify=="Életkor") facet_wrap(vars(AGEf), scales = "free")} +
      {if(input$excessmortModelStratify=="Nem és életkor") facet_grid(AGEf ~ SEX, scales = "free")} +
      theme(plot.caption = element_text(face = "bold", hjust = 0)) +
      labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: KSH")
  })
  
  output$excessmortModelGraph <- renderPlot(dataInputexcessmortModelGraph())
  
  output$excessmortModelGraphDlPDF <- downloadHandler(
    filename = paste0("ModellezettTobblethalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file, dataInputexcessmortModelGraph())
  )
  
  output$excessmortModelGraphDlPNG <- downloadHandler(
    filename = paste0("ModellezettTobblethalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file, dataInputexcessmortModelGraph())
  )
  
  dataInputExcessmortModelNamed <- reactive({
    temp <- copy(dataInputExcessmortModel())
    setnames(temp, c(switch(input$excessmortModelStratify,
                            "Nem" = c("SEX" = "Nem"), "Életkor" = c("AGEf" = "Korcsoport"),
                            "Nem és életkor" = c("AGEf" = "Korcsoport", "SEX" = "Nem")),
                     "date" = "Dátum", "observed" = "Halálozás [fő/hét]", "expected" = "Várt halálozás [fő/hét]",
                     "y" = "Többlethalálozás [%]", "increase" = "Modellezett többlethalálozás [%]",
                     "se" = "Standard hiba"))
  })
  
  output$excessmortModelTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(dataInputExcessmortModelNamed(), readOnly = TRUE, height = 500)
  })
  
  output$excessmortModelTabDlCSV <- downloadHandler(
    filename = paste0("ModellezettTobblethalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(dataInputExcessmortModelNamed(), file)
  )
  
  dataInputexcessandobsmort <- reactive({
    z <- qnorm(1 - (1-input$excessandobsmortConf/100)/2)
    res <- merge(
      RawData[,.(isoyear = lubridate::isoyear(Date), isoweek = lubridate::isoweek(Date), DeathNumber)][
        ,.(DeathNumber = as.numeric(sum(DeathNumber))), .(isoyear, isoweek)],
      with(excessmort::excess_model(ExcessMort[, .(outcome = sum(outcome), population = sum(population)), .(isoyear, isoweek, date)],
                                    min(ExcessMort$date), max(ExcessMort$date),
                                    exclude = exclude_dates),
           data.table(date = date, isoyear = lubridate::isoyear(date), isoweek = lubridate::isoweek(date),
                      excess = expected*fitted,
                      se = sapply(1:length(date), function(i) {
                        mu <- matrix(expected[i], nr = 1)
                        x <- matrix(x[i,], nr = 1)
                        sqrt(mu %*% x %*% betacov %*% t(x) %*% t(mu))
                      }))), by = c("isoyear", "isoweek"), all.x = TRUE)
    res$date <- ISOweek::ISOweek2date(paste0(res$isoyear, "-W", res$isoweek, "-1"))
    res$lwr <- res$excess - z*res$se
    res$upr <- res$excess + z*res$se
    res[isoweek%in%names(table(lubridate::isoweek(RawData$Date)))[table(lubridate::isoweek(RawData$Date))==7]]
  })
  
  dataInputexcessandobsmortGraph <- reactive({
    cols <- c("excess" = "red", "observed" = "blue")
    ggplot(dataInputexcessandobsmort(), aes(x = date, y = excess, ymin = lwr, ymax = upr, color = "excess")) + geom_line() +
      geom_ribbon(alpha = 0.1, linetype = 0, fill = "red") + geom_hline(yintercept = 0) +
      geom_line(aes(x = date, y = DeathNumber, color = "observed")) + guides(fill = FALSE) +
      scale_color_manual(name = "", values = cols, labels = c("Többlethalálozás", "Regisztrált koronavírus-halálozás"),
                         guide = guide_legend(override.aes = aes(fill = NA))) +
      labs(x = "Dátum", y = "Heti halálozás [fő/hét]") + scale_x_date(date_breaks = "month", date_labels = "%b") +
      theme(legend.position = "bottom", plot.caption = element_text(face = "bold", hjust = 0)) +
      labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: KSH és JHU CSSE")
  })
  
  output$excessandobsmortGraph <- renderPlot(dataInputexcessandobsmortGraph())
  
  output$excessandobsmortGraphDlPDF <- downloadHandler(
    filename = paste0("TobblethalalozasEsRegisztraltHalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file, dataInputexcessandobsmortGraph())
  )
  
  output$excessandobsmortGraphDlPNG <- downloadHandler(
    filename = paste0("TobblethalalozasEsRegisztraltHalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file, dataInputexcessandobsmortGraph())
  )
  
  dataInputexcessandobsmortNamed <- reactive({
    temp <- copy(dataInputexcessandobsmort())
    temp$isoyear <- as.integer(temp$isoyear)
    temp$isoweek <- as.integer(temp$isoweek)
    temp$DeathNumber <- as.integer(temp$DeathNumber)
    temp$ci <- ifelse(!is.na(temp$lwr), paste0(round(temp$lwr, 1), " - ", round(temp$upr, 1)), "")
    temp <- temp[ , .(isoyear, isoweek, date, DeathNumber, excess, ci)]
    setnames(temp, c("Év", "Hét sorszáma", "Dátum", "Regisztrált halálozások száma [fő/hét]",
                     "Többlethalálozás [fő/hét]", paste0(input$excessandobsmortConf, "% CI")))
    temp
  })
  
  output$excessandobsmortTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(dataInputexcessandobsmortNamed(), readOnly = TRUE, height = 500)
  })
  
  output$excessandobsmortTabDlCSV <- downloadHandler(
    filename = paste0("TobblethalalozasEsRegisztraltHalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(dataInputexcessandobsmortNamed(), file)
  )
  
  dataInputtestpositivityGraph <- reactive({
    ggplot(RawData, aes(x = Date, y = fracpos, CaseNumber = CaseNumber, TestNumber = TestNumber)) + geom_point() +
      {if(input$testpositivitySmoothfit) geom_smooth(method = "gam", formula = cbind(CaseNumber, TestNumber-CaseNumber) ~ s(x),
                                                     method.args = list(family = binomial(link = "logit")),
                                                     se = input$testpositivityCi, level = input$testpositivityConf/100)} +
      scale_x_date(date_breaks = "month", date_labels = "%b") +
      scale_y_continuous(labels = function(x) x*100) + labs(x = "Dátum", y = "Tesztpozitivitási arány [%]") +
      geom_hline(yintercept = 0.05, color = "red") +
      theme(plot.caption = element_text(face = "bold", hjust = 0)) +
      labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: JHU CSSE és OWID")
  })
  
  output$testpositivityGraph <- renderPlot(dataInputtestpositivityGraph())
  
  output$testpositivityGraphDlPDF <- downloadHandler(
    filename = paste0("Tesztpozitivitas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file, dataInputtestpositivityGraph())
  )
  
  output$testpositivityGraphDlPNG <- downloadHandler(
    filename = paste0("Tesztpozitivitas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file, dataInputtestpositivityGraph())
  )
  
  output$testpositivityTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[,.(Date, CaseNumber, TestNumber, fracpos*100)],
                                 colHeaders = c("Dátum", "Napi esetszám [fő/nap]", "Napi tesztszám [db/nap]",
                                                "Tesztpozitivitás [%]"), readOnly = TRUE, height = 500)
  })
  
  output$testpositivityTabDlCSV <- downloadHandler(
    filename = paste0("Tesztpozitivitas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(RawData[, .(`Dátum` = Date, `Napi esetszám [fő/nap]` = CaseNumber,
                                                   `Napi tesztszám [db/nap]` = TestNumber,
                                                   `Tesztpozitivitás [%]` = fracpos*100)],
                                       file)
  )
  
  dataInputProjemp <- reactive({
    predData(RawData, input$projempOutcome, input$projempFform, input$projempDistr, input$projempConf, input$projempWindow,
             input$projempPeriods, if(input$projempFuture=="Tényadat") NA else input$projempDeltar, input$projempDeltarDate)
  })
  
  output$projempGraph <- renderPlot({
    epicurvePlot(dataInputProjemp(), input$projempOutcome, input$projempLogy, TRUE, input$projempLoessfit, input$projempCi, NA,
                 input$projempFuture!="Tényadat", input$projempDeltarDate, TRUE)
  })
  
  output$projempGraphText <- renderText({
    grText(dataInputProjemp()$m, input$projempFform, if(input$projempFuture=="Tényadat") 0 else input$projempDeltar, TRUE,
           input$projempDeltarDate, min(RawData$Date))
  })
  
  output$projempTab <- rhandsontable::renderRHandsontable({
    pred <- round_dt(dataInputProjemp()$pred)
    pred2 <- pred[, c("Date", input$projempOutcome), with = FALSE]
    pred2$Pred <- if(input$projempCi) paste0(pred$fit, " (", pred$lwr, "-", pred$upr, ")") else pred$fit
    pred2 <- pred2[!duplicated(Date)]
    rhandsontable::rhandsontable(
      pred2, colHeaders = c("Dátum",
                            paste0("Napi ", if(input$projempOutcome=="CaseNumber") "eset" else "halálozás-", "szám [fő/nap]"),
                            if(input$projempCi) paste0("Becsült napi ", if(input$projempOutcome=="CaseNumber") "eset" else
                              "halálozás-", "szám [fő/nap] (", input$projempConf, "%-os CI) [fő/nap]") else
                                paste0("Becsült napi ", if(input$projempOutcome=="CaseNumber") "eset" else
                                  "halálozás-", "szám [fő/nap]")), readOnly = TRUE, height = 500)
  })
  
  dataInputRepr <- reactive(reprData(RawData$CaseNumber, input$reprSImu, input$reprSIsd,
                                     match(input$reprWindow, RawData$Date)))
  
  output$reprGraph <- renderPlot({
    p1 <- ggplot(dataInputRepr(), aes(y = `Módszer`, x = R, xmin = lwr, xmax = upr)) + geom_point() + geom_errorbar() +
      geom_vline(xintercept = 1, color = "red") + expand_limits(x = 1) + labs(y = "")
    p2 <- epicurvePlot(predData(RawData, wind = input$reprWindow))
    egg::ggarrange(p1, p2, ncol = 1, heights = c(2, 1))
  })
  
  output$reprTab <- rhandsontable::renderRHandsontable({
    res <- dataInputRepr()[,c(4, 1:3)]
    res <- round_dt(res)
    res$R <- paste0(res$R, " (", res$lwr, "-", res$upr, ")")
    rhandsontable::rhandsontable(res[, c("Módszer", "R")], readOnly = TRUE, height = 500)
  })
  
  dataInputReprRt <- reactive(reprRtData(RawData$CaseNumber, input$reprRtSImu, input$reprRtSIsd, input$reprRtWindowlen))
  
  output$reprRtGraph <- renderPlot({
    pal <- scales::hue_pal()(4)
    scalval <- c("Cori" = pal[1], "Wallinga-Lipsitch Exp/Poi" = pal[2], "Wallinga-Teunis" = pal[3],
                 "Bettencourt-Ribeiro" = pal[4])
    res <- merge(dataInputReprRt(), RawData)[`Módszer`%in%input$reprRtMethods]
    ggplot(res, aes(x = Date, y = R, ymin = lwr, ymax = upr, color = `Módszer`, fill = `Módszer`)) + geom_line() +
      geom_hline(yintercept = 1, color = "red") + expand_limits(y = 1) +
      labs(y = "Reprodukciós szám", x = "Dátum", color = "", fill = "") + theme(legend.position = "bottom") +
      scale_color_manual(values = scalval) + scale_fill_manual(values = scalval) +
      {if(input$reprRtCi) geom_ribbon(alpha = 0.2)} +
      {if(!input$reprRtCi) coord_cartesian(ylim = c(NA, max(res$R)))} +
      scale_x_date(date_breaks = "month", date_labels = "%b")
  })
  
  output$reprRtTab <- rhandsontable::renderRHandsontable({
    res <- merge(dataInputReprRt(), RawData)[`Módszer`%in%input$reprRtMethods]
    res <- res[, c("Módszer", "Date", "R", "lwr", "upr")]
    res <- res[order(`Módszer`, Date)]
    res <- round_dt(res)
    if(input$reprRtCi) res$R <- paste0(res$R, " (", res$lwr, "-", res$upr, ")")
    rhandsontable::rhandsontable(res[, c("Módszer", "Date", "R")], colHeaders = c("Módszer", "Dátum", "R"),
                                 readOnly = TRUE, height = 500)
  })
  
  values <- reactiveValues(Rs = data.table(Date = as.Date(c("2020-03-04", "2020-03-13")), R = c(2.7, 1.2)))
  
  output$projcompInput <- rhandsontable::renderRHandsontable({
    rhandsontable::hot_cell(rhandsontable::hot_validate_numeric(
      rhandsontable::rhandsontable(values$Rs, colHeaders = c("Dátum", "R")), 2, min = 0.001), 1, 1, readOnly = TRUE)
  })
  
  dataInputProjcomp <- reactive({
    if(!is.null(input$projcompInput)) {
      withProgress(message = "Szimulálás", value = 0, max = 12, {
        incProgress(1, detail = "Modell összeállítása")
        measSIR <- pomp::pomp(as.data.frame(RawData),
                              times = "NumDate", t0 = 0,
                              rprocess = pomp::euler(seir_step, delta.t = 1/7),
                              rinit = seir_init,
                              rmeasure = rmeas,
                              dmeasure = dmeas,
                              accumvars = "H",
                              partrans = pomp::parameter_trans(logit=c("rho")),
                              statenames = c("S", "E1", "E2", "I1", "I2", "I3", "R", "H"),
                              paramnames = c("N", "rho"),
                              covar = pomp::covariate_table(
                                Beta = tidyr::fill(merge(data.table(Date = seq.Date(as.Date("2020-03-04"),
                                                                                    as.Date("2020-03-04")+200, by = "days")),
                                                         rhandsontable::hot_to_r(input$projcompInput), all.x = TRUE),
                                                   "R")$R/input$projcompInfect,
                                alpha = rep(1/input$projcompIncub, 201), gamma = rep(1/input$projcompInfect, 201), times=0:200
                              ))
        sims <- rbindlist(lapply(1:10, function(i) {
          incProgress(1, detail = paste("Szimuláció futtatása ", i*10, "%"))
          data.table(pomp::simulate(measSIR, params = c(N = 9772756, rho = 1), nsim = 50,
                                    format = "data.frame", times = 0:200))[,.id:=as.numeric(.id)+(i-1)*50]
        }))
        
        incProgress(1, detail = "Eredmények összeállítása")
        sims$Date <- min(RawData$Date) + sims$NumDate
        rbind(RawData, sims, sims[, .(.id = 0, med = median(CaseNumber), lwr = quantile(CaseNumber, 0.025),
                                      upr = quantile(CaseNumber, 0.975)), .(Date)], fill = TRUE)
      })
    } else NULL
  })
  
  output$projcompGraph <- renderPlot({
    sims <- dataInputProjcomp()
    if(!is.null(sims)) {
      ggplot(sims, aes(x = Date,y = CaseNumber, group=.id, color = "#8c8cd9", fill = "#8c8cd9")) +
        scale_y_continuous(labels = sepform) +
        geom_line(data = subset(sims, .id<=100), alpha = 0.2) + theme_bw() +
        geom_ribbon(data = subset(sims, .id==0), aes(y = med, ymin = lwr, ymax = upr), alpha = 0.2) +
        geom_line(data = subset(sims, .id==0), aes(y = med), size = 1.5) +
        geom_point(data = subset(sims, is.na(.id)), size = 3, color = "black")  +
        labs(x = "Dátum", y = "Napi esetszám [fő/nap]") + guides(color = FALSE, fill = FALSE) +
        coord_trans(y = if(input$projcompLogy) scales::pseudo_log_trans() else scales::identity_trans(),
                    xlim = c.Date(NA, input$projcompEnd),
                    ylim = c(NA, max(sims[Date<=input$projcompEnd]$CaseNumber, na.rm = TRUE))) +
        geom_vline(xintercept = as.numeric(rhandsontable::hot_to_r(input$projcompInput)$Date))
    }
  })
  
  output$projcompTab <- rhandsontable::renderRHandsontable({
    sims <- round_dt(dataInputProjcomp()[.id=="CI",c("Date", "med", "lwr", "upr")], 0)
    sims$Pred <- paste0(sims$med, " (", sims$lwr, "-", sims$upr, ")")
    rhandsontable::rhandsontable(sims[, c("Date", "Pred")],
                                 colHeaders = c("Dátum", "Becsült napi esetszám (95%-os CI) [fő/nap]"), readOnly = TRUE)
  })
  
  observeEvent(input$projcompAddrow, {
    values$Rs <- rhandsontable::hot_to_r(input$projcompInput)
    values$Rs <- rbind(values$Rs, data.table(Date = max(values$Rs$Date)+7, R = 2))
  })
  
  observeEvent(input$projcompDeleterow, {
    values$Rs <- rhandsontable::hot_to_r(input$projcompInput)
    if(nrow(values$Rs)>1) values$Rs <- values$Rs[-nrow(values$Rs)]  
  })
  
  dataInputCfrMCMC <- reactive(cfrMCMC(RawData, modCorrected, modRealtime, input$cfrDDTmu, input$cfrDDTsd))
  
  dataInputCfr <- reactive({
    MCMCres <- dataInputCfrMCMC()
    cfrData(RawData, input$cfrDDTmu, input$cfrDDTsd, MCMCres, input$cfrConf)
  })
  
  output$cfrGraph <- renderPlot({
    res <- dataInputCfr()
    pal <- scales::hue_pal()(3)
    scalval <- c("Nyers" = pal[1], "Korrigált" = pal[2], "Valós idejű" = pal[3])
    ggplot(subset(res, `Típus`%in%input$cfrToplot), aes(x = Date, y = value*100, color = `Típus`, fill = `Típus`)) +
      geom_line() + {if(input$cfrCi) geom_ribbon(aes(ymin = lwr*100, ymax = upr*100), alpha = 0.2)} +
      coord_cartesian(ylim = c(0, 40)) + labs(x = "Dátum", y = "Halálozási arány [%]") +
      scale_color_manual(values = scalval) + scale_fill_manual(values = scalval)
  })
  
  output$cfrTab <- rhandsontable::renderRHandsontable({
    res <- dataInputCfr()
    res$lwr <- res$lwr*100
    res$value <- res$value*100
    res$upr <- res$upr*100
    res <- dcast(round_dt(res), Date ~ `Típus`, value.var = c("lwr", "value", "upr"))
    res$Crude <- if(input$cfrCi) ifelse(!is.na(res$value_Nyers),
                                        paste0(res$value_Nyers, " (", res$lwr_Nyers, "-", res$upr_Nyers, ")"), NA) else
                                          res$value_Nyers
    res$Corrected <- if(input$cfrCi) ifelse(!is.na(res$`value_Korrigált`), paste0(res$`value_Korrigált`, " (",
                                                                                  res$`lwr_Korrigált`, "-", res$`upr_Korrigált`,
                                                                                  ")"), NA) else res$`value_Korrigált`
    res$Realtime <- if(input$cfrCi) ifelse(!is.na(res$`value_Valós idejű`), paste0(res$`value_Valós idejű`, " (",
                                                                                   res$`lwr_Valós idejű`, "-",
                                                                                   res$`upr_Valós idejű`, ")"), NA) else
                                                                                     res$`value_Valós idejű`
    rhandsontable::rhandsontable(res[, .(Date, Crude, Corrected, Realtime)],
                                 colHeaders = c("Dátum",
                                                if(input$cfrCi) paste0("Nyers halálozási arány (", input$cfrConf,
                                                                       "%-os CI) [%]") else
                                                                         "Nyers halálozási arány [%]",
                                                if(input$cfrCi) paste0("Korrigált halálozási arány (", input$cfrConf,
                                                                       "%-os CI) [fő]") else
                                                                         "Korrigált halálozási arány [%]",
                                                if(input$cfrCi) paste0("Valós idejű halálozási arány (", input$cfrConf,
                                                                       "%-os CI) [fő]") else
                                                                         "Valós idejű halálozási arány [%]"),
                                 readOnly = TRUE)
  })
  
  dataInputCfrUnderdetMCMC <- reactive(cfrMCMC(RawData, modCorrected, modRealtime,
                                               input$cfrUnderdetDDTmu, input$cfrUnderdetDDTsd))
  
  dataInputCfrUnderdet <- reactive({
    MCMCres <- dataInputCfrUnderdetMCMC()
    cfrData(RawData, input$cfrUnderdetDDTmu, input$cfrUnderdetDDTsd, MCMCres)
  })
  
  output$cfrUnderdetTab <- rhandsontable::renderRHandsontable({
    res <- dataInputCfrUnderdet()
    rhandsontable::rhandsontable(RawData[,.(Date,CumCaseNumber,
                                            CumCaseNumber*tail(res[`Típus`=="Korrigált"]$value,1)/input$cfrUnderdetBench*100)],
                                 colHeaders = c("Dátum", "Jelentett kumulált esetszám [fő]", "Korrigált kumulált esetszám [fő]"),
                                 readOnly = TRUE, height = 500)
  })
  
  output$cfrUnderdetText <- renderText({
    res <- dataInputCfrUnderdet()
    paste0("Az utolsó korrigált halálozás a hospitalizáció-halál idő megadott paramétereivel ",
           round(tail(res[`Típus`=="Korrigált"]$value,1)*100,1), "%. Ez a megadott ", input$cfrUnderdetBench, "%-os ",
           "benchmark halálozási arányt figyelembe véve ",
           round(tail(res[`Típus`=="Korrigált"]$value,1)/input$cfrUnderdetBench*100,1),
           "-szoros valódi esetszámot feltételez a jelentetthez képest.")
  })
  
  output$cfrSensGraph <- renderPlot({
    cfrsensgrid$`Korrigált kumulált esetszám [fő]` <- cfrsensgrid$`Korrigált halálozási arány [%]`/input$cfrSensBench*
      tail(RawData$CumCaseNumber,1)
    ggplot(cfrsensgrid, aes(x = DDTmu, y = DDTsd)) + geom_raster(aes(fill = `Korrigált halálozási arány [%]`)) +
      scale_fill_continuous(guide = guide_colorbar(order = 1)) +
      ggnewscale::new_scale_fill() + geom_tile(aes(fill = `Korrigált kumulált esetszám [fő]`)) +
      scale_fill_continuous(guide = guide_colorbar(order = 2)) + theme(legend.position = "right", legend.box = "horizontal") +
      labs(x = "A diagnózis-halál idő várható értéke", y = "A diagnózis-halál idő szórása")
    
  })
  
  output$report <- downloadHandler(
    filename <- paste0("JarvanyugyiJelentes_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf" ),
    content = function(file) {
      td <- tempdir()
      tempReport <- file.path(td, "report.Rmd")
      tempRawData <- file.path(td, "RawData.rds")
      tempEpiHelpers <- file.path(td, "EpiHelpers.R")
      file.copy("report.Rmd", tempReport, overwrite = TRUE)
      file.copy("RawData.rds", tempRawData, overwrite = TRUE)
      file.copy("EpiHelpers.R", tempEpiHelpers, overwrite = TRUE)
      params <- list(reportConf = input$reportConf, reportSImu = input$reportSImu, reportSIsd = input$reportSIsd)
      rmarkdown::render(tempReport, output_file = file, params = params, envir = new.env(parent = globalenv()))
    }
  )
}

shinyApp( ui = ui, server = server )