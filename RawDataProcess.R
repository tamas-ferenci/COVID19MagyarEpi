library(data.table)

tmp <- tempfile(fileext = ".xlsx")
download.file(url = paste0("https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-",
                           "disbtribution-worldwide-", Sys.Date(), ".xlsx"), destfile = tmp, mode = "wb")
CaseData <- data.table(XLConnect::readWorksheetFromFile(tmp, sheet = 1), check.names = TRUE)
names(CaseData)[c(1, 5)] <- c("Date", "CaseNumber")
CaseData$Date <- as.Date(CaseData$Date, tz = "CET")

RawData <- data.table(Date = seq.Date(as.Date("2020-03-04"), Sys.Date(), by = "days"))

RawData <- merge(RawData, CaseData[Countries.and.territories=="Hungary", c("Date", "CaseNumber")], all.x = TRUE)
RawData[is.na(CaseNumber)]$CaseNumber <- 0
RawData$CaseNumber <- as.integer(RawData$CaseNumber)
RawData$NumDate <- as.numeric(RawData$Date)-min(as.numeric(RawData$Date))
# RawData$Population <- 9772756 # http://www.ksh.hu/docs/hun/xstadat/xstadat_eves/i_wnt001b.html
# RawData$Inc <- RawData$CaseNumber/Population*1e6
saveRDS(RawData, file = "RawData.dat")
