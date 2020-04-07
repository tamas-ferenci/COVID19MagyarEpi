library(data.table)

RawData <- data.table(Date=seq.Date(as.Date("2020-03-04"),as.Date("2020-04-06"),by="days"),
                      CaseNumber=c(3,0,2,2,2,3,1,3,3,6,7,7,11,8,15,12,17,28,35,21,38,37,39,42,66,38,45,34,60,38,55,55,11,73),
                      DeathNumber=c(rep(0, 9), 1, 1, 1, 1, 1, 0, 1, 2, 0, 1, 2, 2, 1, 1, 1, 1, 3, 2, 3, 2, 3, 2,2,4,9))

# tmp <- tempfile(fileext = ".xlsx")
# download.file(url = paste0("https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-",
#                            "disbtribution-worldwide-", Sys.Date(), ".xlsx"), destfile = tmp, mode = "wb")
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
saveRDS(RawData, file = "RawData.dat")
