PopPyramid <- as.data.table(KSHStatinfoScraper::GetPopulationPyramidKSH(Years = 2014:2019, AgeGroup = "FiveYear",
                                                                        GeographicArea = "Total"))[,-5]
PopPyramid$AGE <- ifelse(PopPyramid$AGE<35, 0, PopPyramid$AGE)
PopPyramid <- PopPyramid[,.(POPULATION = sum(POPULATION)) ,.(YEAR, SEX, AGE)]

PopPyramid2020 <- structure(list(YEAR = c(2020, 2020, 2020, 2020, 2020, 2020, 2020, 
                                          2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 
                                          2020, 2020, 2020, 2020, 2020, 2020),
                                 SEX = c("Male", "Male", 
                                         "Male", "Male", "Male", "Male", "Male", "Male", "Male", "Male", 
                                         "Male", "Male", "Female", "Female", "Female", "Female", "Female", 
                                         "Female", "Female", "Female", "Female", "Female", "Female", "Female"
                                 ),
                                 AGE = c(0, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 0, 
                                         35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85),
                                 POPULATION = c(1912170, 
                                                351094, 447755, 396940, 344444, 283091, 302578, 280856, 195977, 
                                                139076, 74750, 52118, 1811303, 335987, 429188, 382232, 340206, 
                                                300024, 354929, 364477, 284494, 236208, 160833, 136614)),
                            row.names = c(NA, 
                                          -24L), class = c("data.table", "data.frame"))

PopPyramid <- rbind(PopPyramid, PopPyramid2020)
PopPyramid2021 <- PopPyramid[ , .(YEAR = 2021, POPULATION = predict(lm(POPULATION ~ YEAR), data.frame(YEAR = 2021))), .(SEX, AGE)]
PopPyramid2021 <- PopPyramid2021[, c(3, 1, 2, 4)]

PopPyramid <- rbind(PopPyramid, PopPyramid2021)

saveRDS(PopPyramid, "PopPyramid2020.rds")
