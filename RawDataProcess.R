library(data.table)

# RawData <- data.table(Date=seq.Date(as.Date("2020-03-04"),as.Date("2020-07-24"),by="days"),
#                       CaseNumber=c(3,0,2,2,2,3,1,3,3,6,7,7,11,8,15,12,17,28,35,21,38,37,39,42,66,38,45,34,60,38,55,55,11,73,78,
#                                    85,210,120,100,48,54,67,73,111,71,82,68,114,70,116,99,60,57,83,66,78,48,88,79,56,37,30,46,
#                                    39,28,35,50,21,29,28,39,37,56,36,26,21,42,43,37,35,28,15,15,22,23,25,26,9,16,29,10,23,
#                                    16,20,18,6,3,10,12,14,11,5,7,1,1,1,2,5,8,8,5,7,9,4,11,4,3,10,2,9,6,2,9,6,16,5,10,3,6,5,13,
#                                    11,5,16,14,22,18,6,8,19,14,18,26),
#                       DeathNumber=c(rep(0, 9), 1, 1, 1, 1, 1, 0, 1, 2, 0, 1, 2, 2, 1, 1, 1, 1, 3, 2, 3, 2, 3, 2,2,4,9,11,8,11,
#                                     8,14,10,13,12,9,13,16,17,10,14,12,14,11,12,10,8,11,9,12,11,12,5,11,12,10,10,9,13,8,8,4,
#                                     5,6,6,6,3,11,5,3,3,3,6,4,5,8,6,4,8,7,2,1,5,2,5,3,3,1,2,2,1,2,2,4,3,1,2,2,1,0,2,0,2,
#                                     1,3,1,1,0,3,4,0,1,1,1,1,0,0,0,0,2,2,2,0,0,0,0,0,0,1,0,0,0,0,0,0,0))

RawData <- read.csv(paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/",
                           "csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"))
RawData2 <- read.csv(paste0("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/",
                            "csse_covid_19_time_series/time_series_covid19_deaths_global.csv"))

RawData <- rbind(
  data.table(Date = seq.Date(as.Date("2020-03-04") ,as.Date("2020-04-30"), by = "days"),
             CaseNumber = c(3,0,2,2,2,3,1,3,3,6,7,7,11,8,15,12,17,28,35,21,38,37,39,42,66,38,45,34,60,38,55,55,11,73,78,
                            85,210,120,100,48,54,67,73,111,71,82,68,114,70,116,99,60,57,83,66,78,48,88),
             DeathNumber = c(rep(0, 9), 1, 1, 1, 1, 1, 0, 1, 2, 0, 1, 2, 2, 1, 1, 1, 1, 3, 2, 3, 2, 3, 2,2,4,9,11,8,11,
                             8,14,10,13,12,9,13,16,17,10,14,12,14,11,12,10,8,11,9,12,11)),
  data.table(Date = seq.Date(as.Date("2020-05-01"), as.Date("2020-05-01")+
                               length(RawData[RawData$Country.Region=="Hungary", -(1:104)])-2, by = "days"),
             CaseNumber = diff(as.numeric(RawData[RawData$Country.Region=="Hungary", -(1:104)])),
             DeathNumber = diff(as.numeric(RawData2[RawData2$Country.Region=="Hungary", -(1:104)]))))

# tmp <- tempfile(fileext = ".xlsx")
# download.file(url = paste0("https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-",
#                            "disbtribution-worldwide-", Sys.Date()-1, ".xlsx"), destfile = tmp, mode = "wb")
# CaseData <- data.table(XLConnect::readWorksheetFromFile(tmp, sheet = 1), check.names = TRUE)
# names(CaseData)[c(1, 5)] <- c("Date", "CaseNumber")
# CaseData$Date <- as.Date(CaseData$Date, tz = "CET")
# 
# RawData <- data.table(Date = seq.Date(as.Date("2020-03-04"), Sys.Date(), by = "days"))
# 
# RawData <- merge(RawData, CaseData[Countries.and.territories=="Hungary", c("Date", "CaseNumber")], all.x = TRUE)
# RawData[is.na(CaseNumber)]$CaseNumber <- 0

RawData$CaseNumber <- as.integer(RawData$CaseNumber)
RawData$DeathNumber <- as.integer(RawData$DeathNumber)
RawData$CumCaseNumber <- cumsum(RawData$CaseNumber)
RawData$CumDeathNumber <- cumsum(RawData$DeathNumber)
RawData$NumDate <- as.numeric(RawData$Date)-min(as.numeric(RawData$Date))+1
# RawData$Population <- 9772756 # http://www.ksh.hu/docs/hun/xstadat/xstadat_eves/i_wnt001b.html
# RawData$Inc <- RawData$CaseNumber/Population*1e6
saveRDS(RawData, file = "RawData.rds")

cfrsensgrid <- expand.grid(DDTmu = seq(7, 21, 0.1), DDTsd = seq(9, 15, 0.1))
cfrsensgrid$meanlog <- log(cfrsensgrid$DDTmu)-log(cfrsensgrid$DDTsd^2/cfrsensgrid$DDTmu^2+1)/2
cfrsensgrid$sdlog <- sqrt(log(cfrsensgrid$DDTsd^2/cfrsensgrid$DDTmu^2+1))
LastCumDeathNumber <- tail(RawData$CumDeathNumber,1)
cfrsensgrid$`Korrigált halálozási arány [%]` <- apply(cfrsensgrid, 1, function(x) {
  discrdist <- distcrete::distcrete("lnorm", 1, meanlog = x["meanlog"], sdlog = x["sdlog"])
  LastCumDeathNumber/sum(sapply(1:nrow(RawData),
                                function(i) sum(sapply(0:(i-1), function(j) RawData$CaseNumber[i-j]*discrdist$d(j)))))*100
})
saveRDS(cfrsensgrid, "cfrsensgrid.rds")