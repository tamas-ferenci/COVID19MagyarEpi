library(data.table)
Sys.setlocale(locale = "hu_HU.utf8")
print(Sys.time())
source("/srv/shiny-server/COVID19MagyarEpi/EpiHelpers.R", encoding = "UTF-8")

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

# RawData <- rbind(RawData, data.table(Date = as.Date("2020-11-11"), CaseNumber = 3927, DeathNumber = 87))

RawData2 <- fread("https://covid.ourworldindata.org/data/owid-covid-data.csv")
RawData2 <- RawData2[location=="Hungary"&tests_units=="tests performed", .(Date = date-1, TestNumber = new_tests)]
# RawData2 <- rbind(RawData2, data.table(Date = as.IDate(c("2020-11-09", "2020-11-10")),
# TestNumber = c(13068, 20987)))
# RawData2 <- rbind(RawData2, data.table(Date = as.IDate(c("2020-09-30")),TestNumber = c(11972)))

RawData <- merge(RawData, RawData2, sort = FALSE, all.x = TRUE)

RawData$TestNumber[1:6] <- c(109, 109, 50, 43, 110, 110)
RawData$TestNumber[257:258] <- mean(RawData$TestNumber[257:258])

# RawData <- RawData[Date <= "2022-05-01"]

RawData[CaseNumber==0&DeathNumber==0&is.na(TestNumber), `:=`(CaseNumber = NA, DeathNumber = NA)]

RawData$rep <- with(rle(ifelse(is.na(RawData$CaseNumber), -1, 1:nrow(RawData))), rep(lengths, lengths))
RawData[rep>1]$rep <- RawData[rep>1]$rep + 1
RawData$replag <- c(NA, RawData$rep[-length(RawData$rep)])
RawData[rep==1&replag>1]$rep <- RawData[rep==1&replag>1]$replag
RawData <- tidyr::fill(RawData, 2:4, .direction = "up")
RawData$CaseNumber <- RawData$CaseNumber/RawData$rep
RawData$DeathNumber <- RawData$DeathNumber/RawData$rep
RawData$TestNumber <- RawData$TestNumber/RawData$rep
RawData$rep <- NULL
RawData$replag <- NULL

RawData <- RawData[!is.na(CaseNumber)&!is.na(DeathNumber)]

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

# weekendidxs <- which(RawData$Date>=as.Date("2021-06-11")&lubridate::wday(RawData$Date, week_start = 1)==7)
# RawData$CaseNumber[c(weekendidxs-2,weekendidxs-1, weekendidxs)] <-
#   c(round(0.4*RawData$CaseNumber[weekendidxs]),
#     round(0.35*RawData$CaseNumber[weekendidxs]),
#     RawData$CaseNumber[weekendidxs]-(round(0.4*RawData$CaseNumber[weekendidxs])+
#                                        round(0.35*RawData$CaseNumber[weekendidxs])))
# RawData$DeathNumber[c(weekendidxs-2,weekendidxs-1, weekendidxs)] <-
#   c(round(0.4*RawData$DeathNumber[weekendidxs]),
#     round(0.3*RawData$DeathNumber[weekendidxs]),
#     RawData$DeathNumber[weekendidxs]-(round(0.4*RawData$DeathNumber[weekendidxs])+
#                                         round(0.3*RawData$DeathNumber[weekendidxs])))
# RawData$TestNumber[c(weekendidxs-2,weekendidxs-1, weekendidxs)] <-
#   c(round(0.35*RawData$TestNumber[weekendidxs]),
#     round(0.35*RawData$TestNumber[weekendidxs]),
#     RawData$TestNumber[weekendidxs]-(round(0.35*RawData$TestNumber[weekendidxs])+
#                                        round(0.35*RawData$TestNumber[weekendidxs])))
# 
# RawData[Date=="2021-08-19", c("CaseNumber", "DeathNumber", "TestNumber")] <-
#   round(RawData[Date=="2021-08-20", .(CaseNumber, DeathNumber, TestNumber)]/2)
# RawData[Date=="2021-08-20", c("CaseNumber", "DeathNumber", "TestNumber")] <-
#   RawData[Date=="2021-08-20", .(CaseNumber, DeathNumber, TestNumber)]-RawData[Date=="2021-08-19", .(CaseNumber, DeathNumber, TestNumber)]

RawData$CaseNumber <- as.integer(RawData$CaseNumber)
RawData$DeathNumber <- as.integer(RawData$DeathNumber)
RawData$TestNumber <- as.integer(RawData$TestNumber)
RawData$fracpos <- RawData$CaseNumber/RawData$TestNumber
RawData$CumCaseNumber <- cumsum(RawData$CaseNumber)
RawData$CumDeathNumber <- cumsum(RawData$DeathNumber)
RawData$CumTestNumber <- cumsum(RawData$TestNumber)
RawData$NumDate <- as.numeric(RawData$Date)-min(as.numeric(RawData$Date))+1
# RawData$Population <- 9772756 # http://www.ksh.hu/docs/hun/xstadat/xstadat_eves/i_wnt001b.html
# RawData$Inc <- RawData$CaseNumber/Population*1e6
saveRDS(RawData, file = "/srv/shiny-server/COVID19MagyarEpi/RawData.rds")

saveRDS(reprData(RawData$CaseNumber, SImuDefault, SIsdDefault),
        file = "/srv/shiny-server/COVID19MagyarEpi/DefaultReprData.rds")

saveRDS(reprRtData(RawData$CaseNumber, SImuDefault, SIsdDefault, WindowLenDefault),
        file = "/srv/shiny-server/COVID19MagyarEpi/DefaultReprRtData.rds")

saveRDS(cfrData(RawData, cfrDDTmuDefault, cfrDDTsdDefault, cfrStartDateDefault, cfrConfDefault),
        file = "/srv/shiny-server/COVID19MagyarEpi/DefaultCfrData.rds")

cfrsensgrid <- expand.grid(DDTmu = seq(7, 21, 0.5), DDTsd = seq(9, 15, 0.5))
cfrsensgrid$meanlog <- log(cfrsensgrid$DDTmu)-log(cfrsensgrid$DDTsd^2/cfrsensgrid$DDTmu^2+1)/2
cfrsensgrid$sdlog <- sqrt(log(cfrsensgrid$DDTsd^2/cfrsensgrid$DDTmu^2+1))
LastCumDeathNumber <- tail(RawData$CumDeathNumber,1)
cfrsensgrid$`Korrigált halálozási arány [%]` <- apply(cfrsensgrid, 1, function(x) {
  discrdist <- distcrete::distcrete("lnorm", 1, meanlog = x["meanlog"], sdlog = x["sdlog"])
  dj <- discrdist$d(0:(nrow(RawData)-1))
  LastCumDeathNumber/sum(sapply(1:nrow(RawData),
                                function(i) sum(sapply(0:(i-1), function(j)
                                  RawData$CaseNumber[i-j]*dj[j+1]))))*100
})
saveRDS(cfrsensgrid, "/srv/shiny-server/COVID19MagyarEpi/cfrsensgrid.rds")



RawData <- as.data.table(eurostat::get_eurostat("demo_r_mwk_05", time_format = "raw"))
RawData <- RawData[geo=="HU"&age!="TOTAL"&sex!="T"]
RawData$age <- ifelse(RawData$age=="Y_GE90", "Y85-89", RawData$age)
RawData <- RawData[, .(values = sum(values)) , .(age, sex, unit, geo, time)]
RawData[age=="Y85-89"]$age <- "Y_GE85"
RawData[ , values := round(values*sum(values)/sum(values[age!="UNK"])), .(time, sex)]
RawData <- RawData[age!="UNK"]
RawData <- RawData[!is.na(RawData$values)]
RawData$year <- as.numeric(substring(RawData$time, 1, 4))
RawData$week <- as.numeric(substring(RawData$time, 6, 7))
RawData$date <- ISOweek::ISOweek2date(paste0(RawData$year, "-W", sprintf("%.2i", RawData$week), "-1"))
PopData <- as.data.table(eurostat::get_eurostat("demo_pjangroup"))
PopData <- PopData[geo=="HU"&!age%in%c("UNK", "Y_GE75", "Y_GE80", "TOTAL")&sex!="T"]
PopData$numdate <- as.numeric(PopData$time-as.Date("1960-01-01"))
RawData <- merge(RawData, PopData[, .(date = unique(RawData$date),
                                      population = as.numeric(predict(mgcv::gam(values ~ s(numdate)),
                                                                      data.frame(numdate = as.numeric(unique(RawData$date)-as.Date("1960-01-01")))))),
                                  .(age)], by = c("age", "date"))
names(RawData)[names(RawData)=="values"] <- "outcome"
RawData$sex <- ifelse(RawData$sex=="F", "Nő", "Férfi")
RawData$age <- substring(RawData$age, 2)
RawData$age <- ifelse(RawData$age=="_GE85", ">85", ifelse(RawData$age=="_LT5", "<5", RawData$age))
RawData$age <- factor(RawData$age, levels = c("<5", paste0(seq(5, 80, 5), "-", seq(9, 84, 5)), ">85"))

# RawData <- fread("https://www.ksh.hu/stadat_files/nep/hu/nep0065.csv", dec = ",", skip = 3, encoding = "Latin-1")[,c(3, 5:17, 19:31)]
# names(RawData) <- c("date", paste0("Male_", c(0, seq(35, 90, 5))),
#                     paste0("Female_", c(0, seq(35, 90, 5))))
# RawData$date <- as.Date(RawData$date, format = "%Y. %B %d.")
# for(i in 2:ncol(RawData)) {
#   RawData[[i]][RawData[[i]]=="–"] <- 0
#   RawData[[i]] <- as.numeric(RawData[[i]])
# }
# RawData$Male_85 <- RawData$Male_85 + RawData$Male_90
# RawData$Female_85 <- RawData$Female_85 + RawData$Female_90
# RawData <- RawData[,!names(RawData)%in%c("Male_90", "Female_90"), with = FALSE]
# RawData <- melt(RawData, id.vars = "date", variable.factor = FALSE, value.name = "outcome")
# RawData$outcome <- as.integer(RawData$outcome)
# RawData$SEX <- sapply(strsplit(RawData$variable, "_"), `[`, 1)
# RawData$AGE <- as.integer(sapply(strsplit(RawData$variable, "_"), `[`, 2))
# PopPyramid <- readRDS("/srv/shiny-server/COVID19MagyarEpi/PopPyramid2020.rds")
# PopPyramid <- rbind(PopPyramid, cbind(YEAR = 2022, PopPyramid[YEAR==2021, .(SEX, AGE, POPULATION)]))
# PopPyramid <- rbind(PopPyramid, cbind(YEAR = 2023, PopPyramid[YEAR==2021, .(SEX, AGE, POPULATION)]))
# PopPyramid <- PopPyramid[, with(approx(as.Date(paste0(YEAR, "-01-01")), POPULATION,
#                                        unique(RawData$date)),
#                                 list(date = x, population = y)), .(AGE, SEX)]
# RawData <- merge(RawData, PopPyramid)
# RawData$isoweek <- as.integer(lubridate::isoweek(RawData$date))
# RawData$isoyear <- as.integer(lubridate::isoyear(RawData$date))
# RawData$incidence <- RawData$outcome/RawData$population*1e5
# RawData$SEXf <- as.factor(RawData$SEX)
# RawData$isoyearf <- as.factor(RawData$isoyear)
# RawData$datenum <- (as.numeric(RawData$date)-min(as.numeric(RawData$date)))/365.24
# RawData$AGEcenter <- RawData$AGE+2.5
# RawData$AGEcenter[RawData$AGEcenter==2.5] <- 17.5
# RawData$SEX <- ifelse(RawData$SEX=="Male", "Férfi", "Nő")
# RawData$AGEf <- factor(RawData$AGE, levels = c(0, seq(35, 85, 5)),
#                        labels = c("0-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64",
#                                   "65-69", "70-74", "75-79", "80-84", "85-"))

saveRDS(RawData, "/srv/shiny-server/COVID19MagyarEpi/ExcessMort.rds")

# cfg <- covidestim::covidestim(ndays = nrow(RawData)) +
#   covidestim::input_cases(RawData[,.(date = Date, observation = CaseNumber)]) +
#   covidestim::input_deaths(RawData[,.(date = Date, observation = DeathNumber)]) +
#   covidestim::input_fracpos(RawData[,.(date = Date, observation = fracpos)])
# result <- covidestim::run(cfg)
# saveRDS(result, file = "/srv/shiny-server/COVID19MagyarEpi/CovidestimResult.rds")