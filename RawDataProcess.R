library(data.table)
RawData <- data.table(Date = seq.Date(as.Date("2020-03-04"), as.Date("2020-03-17"), by = "days"),
                      CaseNumber = c(2, 1, 1, 3, 2, 2, 1, 1, 3, 3, 11, 2, 7, 11))
RawData$CaseNumber <- as.integer(RawData$CaseNumber)
RawData$NumDate <- as.numeric(RawData$Date)-min(as.numeric(RawData$Date))
saveRDS(RawData, file = "RawData.dat")
