library(shiny)
library(ggplot2)
library(data.table)

RawData <- readRDS("RawData.rds")
DefaultReprRtData <- readRDS("DefaultReprRtData.rds")
DefaultCfrData <- readRDS("DefaultCfrData.rds")
DefaultReprData <- readRDS("DefaultReprData.rds")

Sys.setlocale(locale = "hu_HU.utf8")
options(shiny.useragg = TRUE)
theme_set(theme_bw())
source("EpiHelpers.R", encoding = "UTF-8")
source("SeirModel.R", encoding = "UTF-8")
# options(mc.cores = parallel::detectCores())
# modCorrected <- readRDS("CFR_corrected_stan.rds")
# modRealtime <- readRDS("CFR_realtime_stan.rds")
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
              src = "https://connect.facebook.net/hu_HU/sdk.js#xfbml=1&version=v11.0"),
  
  tags$style(".shiny-file-input-progress {display: none}"),
  
  titlePanel("A magyarországi koronavírus járvány valós idejű epidemiológiája"),
  
  p("A weboldal és az elemzések teljes forráskódja ",
    a("itt", href = "https://github.com/tamas-ferenci/COVID19MagyarEpi", target = "_blank"),
    "érhető el. Írta: ", a("Ferenci Tamás", href = "http://www.medstat.hu/", target = "_blank",
                           .noWS = "outside"),
    ". Az adatok utolsó frissítésének időpontja:", paste0(format(max(RawData$Date),
                                                                 "%Y. %m. %d"), ".")),
  # div(class="fb-like", "data-href"="https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/",
  #     "data-width" = "600", "data-layout" = "standard", "data-action" = "like", "data-size" = "small",
  #     "data-share" = "true"), p(),
  
  div(class = "fb-share-button", "data-href" = "https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/",
      "data-layout" = "button_count", "data-size" = "small"),
  a(target = "_blank", href="https://www.facebook.com/sharer/sharer.php?u=https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/",
    class="fb-xfbml-parse-ignore"),
  
  a(href = "https://twitter.com/intent/tweet?url=https://research.physcon.uni-obuda.hu/COVID19MagyarEpi/",
    "Tweet", class="twitter-share-button"),
  includeScript("http://platform.twitter.com/widgets.js"),
  
  p(),
  
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
                                                    checkboxInput("epicurveIncLogy", "Függőleges tengely logaritmikus", TRUE),
                                                    checkboxInput("epicurveIncLoessfit", "Simítógörbe illesztése", TRUE),
                                                    checkboxInput("epicurveIncFunfit", "Függvény illesztése"),
                                                    conditionalPanel("input.epicurveIncFunfit==1|input.epicurveIncLoessfit==1",
                                                                     checkboxInput("epicurveIncCi",
                                                                                   "Konfidenciaintervallum megjelenítése",
                                                                                   TRUE)),
                                                    conditionalPanel(
                                                      "(input.epicurveIncFunfit==1|input.epicurveIncLoessfit==1)&input.epicurveIncCi==1",
                                                      numericInput("epicurveIncConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)),
                                                    dateInput("epicurveIncStartDate", "A megjelenítés kezdő dátuma",
                                                              min(RawData$Date), min(RawData$Date),
                                                              max(RawData$Date)-1))
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
                                                    checkboxInput("epicurveMortLogy", "Függőleges tengely logaritmikus", TRUE),
                                                    checkboxInput("epicurveMortLoessfit", "Simítógörbe illesztése", TRUE),
                                                    checkboxInput("epicurveMortFunfit", "Függvény illesztése"),
                                                    conditionalPanel("input.epicurveMortFunfit==1|input.epicurveMortLoessfit==1",
                                                                     checkboxInput("epicurveMortCi",
                                                                                   "Konfidenciaintervallum megjelenítése",
                                                                                   TRUE)),
                                                    conditionalPanel(
                                                      "(input.epicurveMortFunfit==1|input.epicurveMortLoessfit==1)&input.epicurveMortCi==1",
                                                      numericInput("epicurveMortConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)),
                                                    dateInput("epicurveMortStartDate", "A megjelenítés kezdő dátuma",
                                                              min(RawData$Date), min(RawData$Date),
                                                              max(RawData$Date)-1))
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
                          conditionalPanel("input.excessmortType=='Grafikon'", plotOutput("excessmortGraph")),
                          conditionalPanel("input.excessmortType=='Táblázat'", rhandsontable::rHandsontableOutput("excessmortTab")),
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
                                                    checkboxInput("testpositivityLogy", "Függőleges tengely logaritmikus", FALSE),
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
                                   radioButtons("projempDistr", "Eloszlás", c( "Lognormális", "Poisson", "NB/QP"),
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
                 # tabPanel("Kompartment-modell (hosszú távú)",
                 #          fluidRow(
                 #            column(8,                          
                 #                   conditionalPanel("input.projcompType=='Grafikon'", plotOutput("projcompGraph")),
                 #                   conditionalPanel("input.projcompType=='Táblázat'",
                 #                                    rhandsontable::rHandsontableOutput("projcompTab"))
                 #            ),
                 #            column(4,
                 #                   rhandsontable::rHandsontableOutput("projcompInput"),
                 #                   fluidRow(hr(), actionButton("projcompAddrow", "Új sor hozzáadása"),
                 #                            actionButton("projcompDeleterow", "Utolsó sor törlése")))
                 #          ),
                 #          #textOutput("projcompText"),
                 #          hr(),
                 #          fluidRow(
                 #            column(3,
                 #                   radioButtons("projcompType", "Megjelenítés", c("Grafikon", "Táblázat")),
                 #                   dateInput("projcompEnd", "Előrevetítés vége", max(RawData$Date)+100, max(RawData$Date)+1,
                 #                             max(RawData$Date)+200),
                 #                   conditionalPanel("input.projcompType=='Grafikon'",
                 #                                    checkboxInput("projcompLogy", "Függőleges tengely logaritmikus"))
                 #            ),
                 #            column(3,
                 #                   numericInput("projcompIncub", "Inkubációs idő [nap]", 5, 0, 20, 0.1),
                 #                   numericInput("projcompInfect", "Fertőzőképesség hossza [nap]", 3, 0, 20, 0.1)
                 #            )
                 #          )
                 # ),
                 tabPanel("Magyarázat", withMathJax(includeMarkdown("projExplanation.md")))
               )
             )
    ),
    tabPanel("Reprodukciós szám becslése",
             fluidPage(
               tabsetPanel(
                 tabPanel("Valós idejű",
                          conditionalPanel("input.reprRtType=='Grafikon'", plotly::plotlyOutput("reprRtGraph")),
                          conditionalPanel("input.reprRtType=='Táblázat'", rhandsontable::rHandsontableOutput("reprRtTab")),
                          hr(),
                          fluidRow(
                            column(3,
                                   radioButtons("reprRtType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.reprRtType=='Grafikon'",
                                                    downloadButton("reprRtGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("reprRtGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.reprRtType=='Táblázat'",
                                                    downloadButton("reprRtTabDlCSV", "A táblázat letöltése (CSV)")
                                   )),
                            column(3,
                                   checkboxInput("reprRtCi", "Konfidenciaintervallum megjelenítése"),
                                   checkboxGroupInput("reprRtMethods", "Módszerek",
                                                      c("Cori", "Wallinga-Lipsitch Exp/Poi", "Wallinga-Teunis"),
                                                      c("Cori", "Wallinga-Teunis")),
                                   dateInput("reprRtStartDate", "A megjelenítés kezdő dátuma",
                                             min(RawData$Date), min(RawData$Date),
                                             max(RawData$Date)-1)),
                            column(3,
                                   sliderInput("reprRtWindowlen", "Csúszóablak szélessége [nap]:", 1, 60, 7, 1),
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
                                   dateInput("cfrStartDate", "A számítás indításának dátuma",
                                             min(RawData$Date), min(RawData$Date),
                                             max(RawData$Date)-10),
                                   radioButtons("cfrType", "Megjelenítés", c("Grafikon", "Táblázat")),
                                   conditionalPanel("input.cfrType=='Grafikon'",
                                                    downloadButton("cfrGraphDlPDF", "Az ábra letöltése (PDF)"),
                                                    downloadButton("cfrGraphDlPNG", "Az ábra letöltése (PNG)")
                                   ),
                                   conditionalPanel("input.cfrType=='Táblázat'",
                                                    downloadButton("cfrTabDlCSV", "A táblázat letöltése (CSV)")
                                   )
                            ),
                            column(3,
                                   checkboxInput("cfrCi", "Konfidenciaintervallum megjelenítése"),
                                   conditionalPanel("input.cfrCi==1",
                                                    numericInput("cfrConf", "Megbízhatósági szint [%]:", 95, 0, 100, 1)),
                                   conditionalPanel("input.cfrType=='Grafikon'",
                                                    checkboxGroupInput("cfrToplot", "Megjelenítendő halálozási arányok",
                                                                       c("Nyers", "Korrigált", "Valós idejű"),
                                                                       selected = c("Nyers", "Korrigált")),
                                                    dateRangeInput("cfrDateRange", "A megjelenítés intervalluma",
                                                                   as.Date("2020-10-10"), max(RawData$Date),
                                                                   min(RawData$Date), max(RawData$Date)))
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
  h4("Írta: Ferenci Tamás (Óbudai Egyetem, Élettani Szabályozások Kutatóközpont), v0.60"),
  
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
                 input$epicurveIncLoessfit, input$epicurveIncCi, input$epicurveIncConf,
                 startdate = input$epicurveIncStartDate)
  })
  
  dataInputEpicurveMort <- reactive({
    predData(RawData, "DeathNumber", input$epicurveMortFform, input$epicurveMortDistr, input$epicurveMortConf,
             if(input$epicurveMortFunfit) input$epicurveMortWindow else NA)
  })
  
  output$epicurveMortGraph <- renderPlot({
    epicurvePlot(dataInputEpicurveMort(), "DeathNumber", input$epicurveMortLogy, input$epicurveMortFunfit,
                 input$epicurveMortLoessfit, input$epicurveMortCi, input$epicurveMortConf,
                 startdate = input$epicurveMortStartDate)
  })
  
  output$epicurveIncText <- renderText(grText(dataInputEpicurveInc()$m, input$epicurveIncFform, startDate = min(RawData$Date)))
  
  output$epicurveMortText <- renderText(grText(dataInputEpicurveMort()$m, input$epicurveMortFform, startDate = min(RawData$Date)))
  
  output$epicurveIncTab <- rhandsontable::renderRHandsontable({
    rhandsontable::hot_cols(rhandsontable::rhandsontable(RawData[,c("Date", "CaseNumber"), with = FALSE],
                                                         colHeaders = c("Dátum", "Napi esetszám [fő/nap]"), readOnly = TRUE, height = 500),
                            colWidths = c(100, 170))
  })
  
  output$epicurveMortTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(RawData[,c("Date", "DeathNumber"), with = FALSE],
                                 colHeaders = c("Dátum", "Napi halálozás-szám [fő/nap]"), readOnly = TRUE, height = 500)
  })
  
  output$epicurveIncGraphDlPDF <- downloadHandler(
    filename = paste0("JarvanygorbeEsetszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveInc(), "CaseNumber", input$epicurveIncLogy, input$epicurveIncFunfit,
                                                    input$epicurveIncLoessfit, input$epicurveIncCi, input$epicurveIncConf,
                                                    startdate = input$epicurveIncStartDate))
  )
  
  output$epicurveIncGraphDlPNG <- downloadHandler(
    filename = paste0("JarvanygorbeEsetszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveInc(), "CaseNumber", input$epicurveIncLogy, input$epicurveIncFunfit,
                                                    input$epicurveIncLoessfit, input$epicurveIncCi, input$epicurveIncConf,
                                                    startdate = input$epicurveIncStartDate))
  )
  
  output$epicurveIncTabDlCSV <- downloadHandler(
    filename = paste0("JarvanygorbeEsetszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(RawData[,.(`Dátum` = Date, `Napi esetszám [fő/nap]` = CaseNumber)], file)
  )
  
  output$epicurveMortGraphDlPDF <- downloadHandler(
    filename = paste0("JarvanygorbeHalalozasszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveMort(), "DeathNumber", input$epicurveMortLogy, input$epicurveMortFunfit,
                                                    input$epicurveMortLoessfit, input$epicurveMortCi, input$epicurveMortConf,
                                                    startdate = input$epicurveMortStartDate))
  )
  
  output$epicurveMortGraphDlPNG <- downloadHandler(
    filename = paste0("JarvanygorbeHalalozasszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file,
                                       epicurvePlot(dataInputEpicurveMort(), "DeathNumber", input$epicurveMortLogy, input$epicurveMortFunfit,
                                                    input$epicurveMortLoessfit, input$epicurveMortCi, input$epicurveMortConf,
                                                    startdate = input$epicurveMortStartDate))
  )
  
  output$epicurveMortTabDlCSV <- downloadHandler(
    filename = paste0("JarvanygorbeHalalozasszam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(RawData[,.(`Dátum` = Date, `Napi halálozás-szám [fő/nap]` = DeathNumber)],file)
  )
  
  dataInputexcessmortGraph <- reactive({
    stratlist <- c("date", switch(input$excessmortStratify,
                                  "Nem" = "sex", "Életkor" = "age",
                                  "Nem és életkor" = c("age", "sex")))
    ggplot(ExcessMort[,.(outcome = sum(outcome), population = sum(population), year = year,
                         week = week), stratlist],
           aes(x = week, y = outcome/population*1e5, group = year,
               color = cut(year, c(0, 2019:2022), labels = c("2015-2019", 2020:max(ExcessMort$year))), alpha = year>=2020)) + geom_line() +
      scale_alpha_manual(values = c(0.3, 1)) + guides(alpha = "none") +
      {if(input$excessmortStratify=="Nem") facet_wrap(vars(sex))} +
      {if(input$excessmortStratify=="Életkor") facet_wrap(vars(age), scales = "free")} +
      {if(input$excessmortStratify=="Nem és életkor") facet_grid(age ~ sex, scales = "free")} +
      labs(x = "Hét sorszáma", y = "Mortalitás [/100 ezer fő/hét]") +
      theme(plot.caption = element_text(face = "bold", hjust = 0), legend.position = "bottom", legend.title=element_blank()) +
      labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: KSH")
  })
  
  output$excessmortGraph <- renderPlot(dataInputexcessmortGraph())
  
  output$excessmortTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(ExcessMort[,.(`Év` = year, `Hét sorszáma` = week,
                                               `Nem` = sex, `Korcsoport` = age, `Halálozások száma [fő]` = outcome,
                                               `Háttérpopuláció [fő]` = population,
                                               `Incidencia [fő/100e fő]` = outcome/population*1e5)],
                                 readOnly = TRUE, height = 500, renderAllRows = TRUE)
  })
  
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
    content = function(file) fwritecsv(ExcessMort[,.(`Év` = year, `Hét sorszáma` = week,
                                                     `Nem` = sex, `Korcsoport` = age, `Halálozások száma [fő]` = outcome,
                                                     `Háttérpopuláció [fő]` = population,
                                                     `Incidencia [fő/100e fő]` = outcome/population*1e5)], file)
  )
  
  dataInputExcessmortModel <- reactive({
    stratlist <- c("date", switch(input$excessmortModelStratify,
                                  "Nem" = "sex", "Életkor" = "age",
                                  "Nem és életkor" = c("age", "sex")))
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
      {if(input$excessmortModelStratify=="Nem") facet_wrap(vars(sex))} +
      {if(input$excessmortModelStratify=="Életkor") facet_wrap(vars(age), scales = "free")} +
      {if(input$excessmortModelStratify=="Nem és életkor") facet_grid(age ~ sex, scales = "free")} +
      theme(plot.caption = element_text(face = "bold", hjust = 0)) +
      labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: Eurostat")
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
    temp$observed <- as.integer(temp$observed)
    setnames(temp, c(switch(input$excessmortModelStratify,
                            "Nem" = c("sex" = "Nem"), "Életkor" = c("age" = "Korcsoport"),
                            "Nem és életkor" = c("age" = "Korcsoport", "sex" = "Nem")),
                     "date" = "Kezdődátum", "observed" = "Halálozás [fő/hét]", "expected" = "Várt halálozás [fő/hét]",
                     "y" = "Többlethalálozás [%]", "increase" = "Modellezett többlethalálozás [%]",
                     "se" = "Standard hiba"))
  })
  
  output$excessmortModelTab <- rhandsontable::renderRHandsontable({
    rhandsontable::rhandsontable(dataInputExcessmortModelNamed(), readOnly = TRUE, height = 500, renderAllRows = TRUE)
  })
  
  output$excessmortModelTabDlCSV <- downloadHandler(
    filename = paste0("ModellezettTobblethalalozas_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(dataInputExcessmortModelNamed(), file)
  )
  
  dataInputexcessandobsmort <- reactive({
    z <- qnorm(1 - (1-input$excessandobsmortConf/100)/2)
    res <- merge(
      RawData[,.(year = lubridate::isoyear(Date), week = lubridate::isoweek(Date), DeathNumber)][
        ,.(DeathNumber = as.numeric(sum(DeathNumber))), .(year, week)],
      with(excessmort::excess_model(ExcessMort[, .(outcome = sum(outcome), population = sum(population)), .(year, week, date)],
                                    min(ExcessMort$date), max(ExcessMort$date),
                                    exclude = exclude_dates),
           data.table(date = date, year = lubridate::isoyear(date), week = lubridate::isoweek(date),
                      excess = expected*fitted,
                      se = sapply(1:length(date), function(i) {
                        mu <- matrix(expected[i], nr = 1)
                        x <- matrix(x[i,], nr = 1)
                        sqrt(mu %*% x %*% betacov %*% t(x) %*% t(mu))
                      }))), by = c("year", "week"), all.x = TRUE)
    res$date <- ISOweek::ISOweek2date(paste0(res$year, "-W", sprintf("%02d", res$week), "-1"))
    res$lwr <- res$excess - z*res$se
    res$upr <- res$excess + z*res$se
    res$NoDays <- sapply(1:nrow(res), function(i) nrow(RawData[lubridate::isoweek(Date)==res$week[i]&lubridate::year(Date)==res$year[i]]))
    res[NoDays==7]
  })
  
  dataInputexcessandobsmortGraph <- reactive({
    res <- melt(dataInputexcessandobsmort(), id.vars = c("year", "week", "date"), measure.vars = list(value = c(5, 3), lwr = 7, upr = 8))
    res$variable <- ifelse(res$variable==1, "Többlethalálozás", "Regisztrált koronavírus-halálozás")
    res$variable <- relevel(as.factor(res$variable), ref = "Többlethalálozás")
    ggplot(res, aes(x = date, y = value, ymin = lwr, ymax = upr, group = variable, fill = variable)) + geom_line(aes(color = variable)) +
      geom_ribbon(alpha = 0.1, show.legend = FALSE) + geom_hline(yintercept = 0) + #guides(fill = "none") +
      labs(x = "Dátum", y = "Heti halálozás [fő/hét]", color = "") +
      scale_x_date(date_breaks = "months", labels = scales::label_date_short()) +
      theme(legend.position = "bottom", plot.caption = element_text(face = "bold", hjust = 0)) +
      labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: Eurostat és JHU CSSE")
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
    temp$year <- as.integer(temp$year)
    temp$week <- as.integer(temp$week)
    temp$DeathNumber <- as.integer(temp$DeathNumber)
    temp$ci <- ifelse(!is.na(temp$lwr), paste0(round(temp$lwr, 1), " - ", round(temp$upr, 1)), "")
    temp <- temp[ , .(year, week, date, DeathNumber, excess, ci)]
    setnames(temp, c("Év", "Hét sorszáma", "Kezdődátum", "Regisztrált halálozások száma [fő/hét]",
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
    ggplot(RawData, aes(x = Date, y = CaseNumber/TestNumber, CaseNumber = CaseNumber, TestNumber = TestNumber)) + geom_point() +
      {if(input$testpositivitySmoothfit)
        geom_smooth(method = "gam", formula = cbind(CaseNumber, TestNumber-CaseNumber) ~ s(x, k = 20),
                    method.args = list(family = binomial(link = "logit")),
                    se = input$testpositivityCi, level = input$testpositivityConf/100, n = 500,
                    aes(y = stage(CaseNumber/TestNumber, y),
                        ymin = after_stat(ymin), ymax = after_stat(ymax)))} +
      scale_x_date(date_breaks = "months", labels = scales::label_date_short()) +
      scale_y_continuous(labels = function(x) x*100, trans = if(input$testpositivityLogy) "log10" else "identity") +
      {if(input$testpositivityLogy) annotation_logticks()} +
      labs(x = "Dátum", y = "Tesztpozitivitási arány [%]") +
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
    pred <- dataInputProjemp()$pred
    pred2 <- pred[, c("Date", input$projempOutcome), with = FALSE]
    pred2$Pred <- if(input$projempCi) paste0(round(pred$fit, 2), " (", round(pred$lwr, 2), "-", round(pred$upr, 2), ")") else pred$fit
    pred2 <- pred2[!duplicated(Date)]
    rhandsontable::rhandsontable(
      pred2, colHeaders = c("Dátum",
                            paste0("Napi ", if(input$projempOutcome=="CaseNumber") "eset" else "halálozás-", "szám [fő/nap]"),
                            if(input$projempCi) paste0("Becsült napi ", if(input$projempOutcome=="CaseNumber") "eset" else
                              "halálozás-", "szám [fő/nap] (", input$projempConf, "%-os CI) [fő/nap]") else
                                paste0("Becsült napi ", if(input$projempOutcome=="CaseNumber") "eset" else
                                  "halálozás-", "szám [fő/nap]")), readOnly = TRUE, height = 500)
  })
  
  dataInputRepr <- reactive(if(input$reprSImu==SImuDefault&input$reprSIsd==SIsdDefault) DefaultReprData else
    reprData(RawData$CaseNumber, input$reprSImu, input$reprSIsd, match(input$reprWindow, RawData$Date)))
  
  output$reprGraph <- renderPlot({
    p1 <- ggplot(dataInputRepr(), aes(y = `Módszer`, x = R, xmin = lwr, xmax = upr)) + geom_point() + geom_errorbar() +
      geom_vline(xintercept = 1, color = "red") + expand_limits(x = 1) + labs(y = "")
    p2 <- epicurvePlot(predData(RawData, wind = input$reprWindow))
    egg::ggarrange(p1, p2, ncol = 1, heights = c(2, 1))
  })
  
  output$reprTab <- rhandsontable::renderRHandsontable({
    res <- dataInputRepr()[,c(4, 1:3)]
    res$R <- paste0(round(res$R, 2), " (", round(res$lwr, 2), "-", round(res$upr, 2), ")")
    rhandsontable::rhandsontable(res[, c("Módszer", "R")], readOnly = TRUE, height = 500)
  })
  
  dataInputReprRt <- reactive(if(input$reprRtSImu==SImuDefault&input$reprRtSIsd==SIsdDefault&input$reprRtWindowlen==WindowLenDefault)
    DefaultReprRtData else reprRtData(RawData$CaseNumber, input$reprRtSImu, input$reprRtSIsd, input$reprRtWindowlen))
  
  dataInputReprRtGraph <- reactive({
    pal <- scales::hue_pal()(3)
    scalval <- c("Cori" = pal[1], "Wallinga-Lipsitch Exp/Poi" = pal[2], "Wallinga-Teunis" = pal[3])
    res <- merge(dataInputReprRt(), RawData)[`Módszer`%in%input$reprRtMethods]
    plotly::ggplotly(
      ggplot(res, aes(x = Date, y = R, ymin = lwr, ymax = upr, color = `Módszer`, fill = `Módszer`,
                      text = paste0(Date, " dátumon az R értéke ", round(R, 2), " (95% CI: ",
                                    round(lwr, 2), " - ", round(upr, 2), "), ", `Módszer`, " módszerrel"),
                      group = `Módszer`)) +
        geom_line() + geom_hline(yintercept = 1, color = "red") + expand_limits(y = 1) +
        labs(y = "Reprodukciós szám", x = "Dátum", color = "", fill = "") + theme(legend.position = "bottom") +
        scale_color_manual(values = scalval) + scale_fill_manual(values = scalval) +
        {if(input$reprRtCi) geom_ribbon(alpha = 0.2, linetype = 0)} +
        coord_cartesian(xlim = c(input$reprRtStartDate, NA),
                        ylim = c(NA, if(input$reprRtCi) max(res[Date>=input$reprRtStartDate]$upr)
                                 else max(res[Date>=input$reprRtStartDate]$R))) +
        scale_x_date(date_breaks = "months", labels = scales::label_date_short()) +
        theme(plot.caption = element_text(face = "bold", hjust = 0)) +
        labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: JHU CSSE"),
      tooltip = "text")
  })
  
  output$reprRtGraph <- plotly::renderPlotly(dataInputReprRtGraph())
  
  dataInputReprRtTab <- reactive({
    res <- merge(dataInputReprRt(), RawData)[`Módszer`%in%input$reprRtMethods]
    res <- res[, c("Módszer", "Date", "R", "lwr", "upr")]
    res <- res[order(`Módszer`, Date)]
    if(input$reprRtCi) res$R <- paste0(round(res$R, 2), " (", round(res$lwr, 2), "-", round(res$upr, 2), ")")
    setnames(res, c("Módszer", "Dátum", "R", "lwr", "upr"))
    res
  })
  
  output$reprRtTab <- rhandsontable::renderRHandsontable(rhandsontable::rhandsontable(dataInputReprRtTab()[, c("Módszer", "Dátum", "R")],
                                                                                      readOnly = TRUE, height = 500))
  
  output$reprRtGraphDlPDF <- downloadHandler(
    filename = paste0("ReprodukciosSzam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file, dataInputReprRtGraph())
  )
  
  output$reprRtGraphDlPNG <- downloadHandler(
    filename = paste0("ReprodukciosSzam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file, dataInputReprRtGraph())
  )
  
  output$reprRtTabDlCSV <- downloadHandler(
    filename = paste0("ReprodukciosSzam_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(dataInputReprRtTab()[, c("Módszer", "Dátum", "R")], file)
  )
  
  values <- reactiveValues(Rs = data.table(Date = as.Date(c("2020-03-04", "2020-03-13")), R = c(2.7, 1.2)))
  
  # output$projcompInput <- rhandsontable::renderRHandsontable({
  #   rhandsontable::hot_cell(rhandsontable::hot_validate_numeric(
  #     rhandsontable::rhandsontable(values$Rs, colHeaders = c("Dátum", "R")), 2, min = 0.001), 1, 1, readOnly = TRUE)
  # })
  # 
  # dataInputProjcomp <- reactive({
  #   if(!is.null(input$projcompInput)) {
  #     withProgress(message = "Szimulálás", value = 0, max = 12, {
  #       incProgress(1, detail = "Modell összeállítása")
  #       measSIR <- pomp::pomp(as.data.frame(RawData),
  #                             times = "NumDate", t0 = 0,
  #                             rprocess = pomp::euler(seir_step, delta.t = 1/7),
  #                             rinit = seir_init,
  #                             rmeasure = rmeas,
  #                             dmeasure = dmeas,
  #                             accumvars = "H",
  #                             partrans = pomp::parameter_trans(logit=c("rho")),
  #                             statenames = c("S", "E1", "E2", "I1", "I2", "I3", "R", "H"),
  #                             paramnames = c("N", "rho"),
  #                             covar = pomp::covariate_table(
  #                               Beta = tidyr::fill(merge(data.table(Date = seq.Date(as.Date("2020-03-04"),
  #                                                                                   as.Date("2020-03-04")+200, by = "days")),
  #                                                        rhandsontable::hot_to_r(input$projcompInput), all.x = TRUE),
  #                                                  "R")$R/input$projcompInfect,
  #                               alpha = rep(1/input$projcompIncub, 201), gamma = rep(1/input$projcompInfect, 201), times=0:200
  #                             ))
  #       sims <- rbindlist(lapply(1:10, function(i) {
  #         incProgress(1, detail = paste("Szimuláció futtatása ", i*10, "%"))
  #         data.table(pomp::simulate(measSIR, params = c(N = 9772756, rho = 1), nsim = 50,
  #                                   format = "data.frame", times = 0:200))[,.id:=as.numeric(.id)+(i-1)*50]
  #       }))
  #       
  #       incProgress(1, detail = "Eredmények összeállítása")
  #       sims$Date <- min(RawData$Date) + sims$NumDate
  #       rbind(RawData, sims, sims[, .(.id = 0, med = median(CaseNumber), lwr = quantile(CaseNumber, 0.025),
  #                                     upr = quantile(CaseNumber, 0.975)), .(Date)], fill = TRUE)
  #     })
  #   } else NULL
  # })
  # 
  # output$projcompGraph <- renderPlot({
  #   sims <- dataInputProjcomp()
  #   if(!is.null(sims)) {
  #     ggplot(sims, aes(x = Date,y = CaseNumber, group=.id, color = "#8c8cd9", fill = "#8c8cd9")) +
  #       scale_y_continuous(labels = function(x) format(x, big.mark = " ", scientific = FALSE)) +
  #       geom_line(data = subset(sims, .id<=100), alpha = 0.2) + theme_bw() +
  #       geom_ribbon(data = subset(sims, .id==0), aes(y = med, ymin = lwr, ymax = upr), alpha = 0.2) +
  #       geom_line(data = subset(sims, .id==0), aes(y = med), size = 1.5) +
  #       geom_point(data = subset(sims, is.na(.id)), size = 3, color = "black")  +
  #       labs(x = "Dátum", y = "Napi esetszám [fő/nap]") + guides(color = "none", fill = "none") +
  #       coord_trans(y = if(input$projcompLogy) scales::pseudo_log_trans() else scales::identity_trans(),
  #                   xlim = c.Date(NA, input$projcompEnd),
  #                   ylim = c(NA, max(sims[Date<=input$projcompEnd]$CaseNumber, na.rm = TRUE))) +
  #       geom_vline(xintercept = as.numeric(rhandsontable::hot_to_r(input$projcompInput)$Date))
  #   }
  # })
  # 
  # output$projcompTab <- rhandsontable::renderRHandsontable({
  #   sims <- dataInputProjcomp()[.id=="CI",c("Date", "med", "lwr", "upr")]
  #   sims$Pred <- paste0(sims$med, " (", sims$lwr, "-", sims$upr, ")")
  #   rhandsontable::rhandsontable(sims[, c("Date", "Pred")],
  #                                colHeaders = c("Dátum", "Becsült napi esetszám (95%-os CI) [fő/nap]"), readOnly = TRUE)
  # })
  # 
  # observeEvent(input$projcompAddrow, {
  #   values$Rs <- rhandsontable::hot_to_r(input$projcompInput)
  #   values$Rs <- rbind(values$Rs, data.table(Date = max(values$Rs$Date)+7, R = 2))
  # })
  # 
  # observeEvent(input$projcompDeleterow, {
  #   values$Rs <- rhandsontable::hot_to_r(input$projcompInput)
  #   if(nrow(values$Rs)>1) values$Rs <- values$Rs[-nrow(values$Rs)]  
  # })
  
  dataInputCfr <- reactive({
    progress <- shiny::Progress$new()
    progress$set(message = "Számolás", value = 0)
    on.exit(progress$close())
    updateProgress <- function(detail = NULL) {
      progress$inc(amount = 1/(2*(nrow(RawData)-9)+2), detail = detail)
    }
    if(input$cfrDDTmu==cfrDDTmuDefault&input$cfrDDTsd==cfrDDTsdDefault&input$cfrStartDate==cfrStartDateDefault&input$cfrConf==cfrConfDefault)
      DefaultCfrData else cfrData(RawData, input$cfrDDTmu, input$cfrDDTsd, input$cfrStartDate, input$cfrConf,
                                  updateProgress = updateProgress)
  })
  
  dataInputcfrGraph <- reactive({
    res <- dataInputCfr()
    pal <- scales::hue_pal()(3)
    scalval <- c("Nyers" = pal[1], "Korrigált" = pal[2], "Valós idejű" = pal[3])
    ressubset <- res[Date>=input$cfrDateRange[1]&Date<=input$cfrDateRange[2]&`Típus`%in%input$cfrToplot]
    ggplot(res[`Típus`%in%input$cfrToplot],
           aes(x = Date, y = value*100, ymin = lwr*100, ymax = upr*100, color = `Típus`, fill = `Típus`)) +
      geom_line() + {if(input$cfrCi) geom_ribbon(alpha = 0.2, linetype = 0)} +
      coord_cartesian(xlim = input$cfrDateRange,
                      ylim = if(input$cfrCi) extendrange(range(c(ressubset$lwr, ressubset$upr),
                                                               na.rm = TRUE)*100) else extendrange(range(ressubset$value*100, na.rm = TRUE))) +
      labs(x = "Dátum", y = "Halálozási arány [%]") +
      scale_color_manual(values = scalval) + scale_fill_manual(values = scalval) +
      scale_x_date(date_breaks = "months", labels = scales::label_date_short())
  })
  
  output$cfrGraph <- renderPlot(dataInputcfrGraph())
  
  dataInputCfrTab <- reactive({
    res <- dataInputCfr()
    res$lwr <- res$lwr*100
    res$value <- res$value*100
    res$upr <- res$upr*100
    res <- dcast(res, Date ~ `Típus`, value.var = c("lwr", "value", "upr"))
    res$Crude <- if(input$cfrCi) ifelse(!is.na(res$value_Nyers),
                                        paste0(round(res$value_Nyers, 2), " (", round(res$lwr_Nyers, 2), "-", round(res$upr_Nyers, 2), ")"), NA) else
                                          res$value_Nyers
    res$Corrected <- if(input$cfrCi) ifelse(!is.na(res$`value_Korrigált`), paste0(round(res$`value_Korrigált`, 2), " (",
                                                                                  round(res$`lwr_Korrigált`, 2), "-", round(res$`upr_Korrigált`, 2),
                                                                                  ")"), NA) else res$`value_Korrigált`
    res$Realtime <- if(input$cfrCi) ifelse(!is.na(res$`value_Valós idejű`), paste0(round(res$`value_Valós idejű`, 2), " (",
                                                                                   round(res$`lwr_Valós idejű`, 2), "-",
                                                                                   round(res$`upr_Valós idejű`, 2), ")"), NA) else
                                                                                     res$`value_Valós idejű`
    res
  })
  
  output$cfrTab <- rhandsontable::renderRHandsontable(rhandsontable::rhandsontable(
    dataInputCfrTab()[, .(Date, Crude, Corrected, Realtime)],
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
    readOnly = TRUE, height = 500))
  
  output$cfrGraphDlPDF <- downloadHandler(
    filename = paste0("HalalozasiArany_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".pdf"),
    content = function(file) ggsave169(file, dataInputcfrGraph())
  )
  
  output$cfrGraphDlPNG <- downloadHandler(
    filename = paste0("HalalozasiArany_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".png"),
    content = function(file) ggsave169(file, dataInputcfrGraph())
  )
  
  output$cfrTabDlCSV <- downloadHandler(
    filename = paste0("HalalozasiArany_", format(Sys.time(), "%Y_%m_%d__%H_%M"), ".csv"),
    content = function(file) fwritecsv(dataInputCfrTab()[, .(Date, Crude, Corrected, Realtime)], file)
  )
  
  dataInputCfrUnderdet <- reactive({
    cfrData(RawData, input$cfrUnderdetDDTmu, input$cfrUnderdetDDTsd, last = TRUE)
  })
  
  output$cfrUnderdetTab <- rhandsontable::renderRHandsontable({
    res <- dataInputCfrUnderdet()
    rhandsontable::rhandsontable(RawData[, .(Date, CumCaseNumber, CumCaseNumber*res/input$cfrUnderdetBench*100)],
                                 colHeaders = c("Dátum", "Jelentett kumulált esetszám [fő]", "Korrigált kumulált esetszám [fő]"),
                                 readOnly = TRUE, height = 500)
  })
  
  output$cfrUnderdetText <- renderText({
    res <- dataInputCfrUnderdet()
    paste0("Az utolsó korrigált halálozás a hospitalizáció-halál idő megadott paramétereivel ",
           round(res*100, 1), "%. Ez a megadott ", input$cfrUnderdetBench, "%-os benchmark halálozási arányt figyelembe véve ",
           round(res/input$cfrUnderdetBench*100, 1), "-szoros valódi esetszámot feltételez a jelentetthez képest.")
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
      rmarkdown::render(tempReport, params = params, envir = new.env(parent = globalenv()))
      file.copy(file.path(td, "report.pdf"), file)
    })
}

shinyApp(ui = ui, server = server)