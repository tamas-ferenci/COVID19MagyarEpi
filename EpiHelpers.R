SImuDefault <- 4.7
SIsdDefault <- 2.9
WindowLenDefault <- 7
cfrDDTmuDefault <- 13
cfrDDTsdDefault <- 12.7
cfrStartDateDefault <- as.Date("2020-03-04")
cfrConfDefault <- 95

LogisticDeriv <- function(Time){
  list(predictors = list(Asym = 1, xmid = 1, scal = 1),
       variables = list(substitute(Time)),
       term = function(predLabels, varLabels) {
         paste(predLabels[1], "/(2*", predLabels[3], "*(1+cosh((", varLabels[1], "-", predLabels[2], ")/", predLabels[3], ")))")
       })
}
class(LogisticDeriv) <- "nonlin"

predData <- function(rd, what = "CaseNumber", fform = "Exponenciális", distr = "Poisson", level = 95, wind = NA,
                     projper = 0, deltar = NA, deltardate = NA) {
  if(any(is.na(wind))) wind <- range(rd$Date)
  if(projper>0) rd <- rbind(rd, data.table(Date = seq(tail(rd$Date,1), tail(rd$Date,1)+projper, by = "days"),
                                           CaseNumber = NA, DeathNumber = NA, TestNumber = NA, fracpos = NA,
                                           CumCaseNumber = NA, CumDeathNumber = NA, CumTestNumber = NA,
                                           NumDate = tail(rd$NumDate,1):(tail(rd$NumDate,1)+projper)))
  rd$Deviated <- (rd$Date>=deltardate)&is.na(rd[[what]])
  crit.value <- qt(1-(1-level/100)/2, df = sum(!is.na(rd[[what]]))-2)
  if(fform=="Exponenciális") {
    fitformula <- paste(if(distr=="Lognormális") "log", "(", what, ")~Date")
  } else if(fform=="Hatvány") {
    fitformula <- paste(if(distr=="Lognormális") "log", "(", what, ")~log(NumDate)")
  } else if(fform=="Logisztikus") {
    fitformula <- paste(what, "~LogisticDeriv(NumDate)-1")
  }
  if(fform%in%c("Exponenciális", "Hatvány")&!is.na(deltar)) fitformula <- paste(fitformula, "+offset(", deltar,
                                                                                "*Deviated*(NumDate-", sum(!rd$Deviated), "))")
  fitformula <- as.formula(fitformula)
  family <- NULL
  startval <- NULL
  if(distr=="Lognormális") {
    fitfun <- if(fform!="Logisztikus") lm else gnm::gnm
    rdata <- if(fform!="Logisztikus") rd[rd[[what]]!=0] else rd
    if(fform=="Logisztikus") family <- gaussian(link = "log")
  } else if(distr=="Poisson") {
    fitfun <- if(fform!="Logisztikus") glm else gnm::gnm
    rdata <- rd
    #family <- if(fform!="Logisztikus") poisson(link = "log") else poisson(link = "identity")
    family <- poisson(link = "log")
  } else if(distr=="NB/QP") {
    fitfun <- if(fform!="Logisztikus") MASS::glm.nb else gnm::gnm
    if(fform=="Logisztikus") family <- quasipoisson(link = "log")
    rdata <- rd
  }
  parlist <- list(formula = fitformula, data = rdata[Date>=wind[1]&Date<=wind[2]&!is.na(rdata[[what]])])
  startval <- if(fform=="Logisztikus") {
    z <- parlist$data[[what]]
    rng <- range(z)
    dz <- diff(rng)
    z <- (z - rng[1L] + 0.05 * dz)/(1.1 * dz)
    parlist$data[["z"]] <- log(z/(1 - z))
    aux <- coef(lm(as.formula(paste(what, "~ z")), parlist$data))
    fit <- tryCatch(nls(as.formula(paste(what, "~ 1/(1 + exp((xmid - NumDate)/scal))")), data = parlist$data,
                        start = list(xmid = aux[[1L]], scal = aux[[2L]]), algorithm = "plinear"),
                    error = function(e) NULL)
    if(!is.null(fit)) coef(fit)[c(".lin", "xmid", "scal")] else c(1000, 100, 2)
  } else NULL
  if(!is.null(family)) parlist <- c(parlist, list(family = family))
  if(!is.null(startval)) parlist <- c(parlist, list(start = startval))
  m <- do.call(fitfun, parlist)
  
  #trafo <- if(fform!="Logisztikus") exp else identity
  trafo <- exp
  pred <- data.table(rd, with(predict(m, newdata = rd, se.fit = TRUE),
                              data.table(fit = trafo(fit), lwr = trafo(fit - (crit.value * se.fit)),
                                         upr = trafo(fit + (crit.value * se.fit)))))
  list(pred = pred, m = m, wind = wind)
}

r2R0gamma <- function(r, si_mean, si_sd) {
  (1+r*si_sd^2/si_mean)^(si_mean^2/si_sd^2)
}

epicurvePlot <- function(pred, what = "CaseNumber", logy = FALSE, funfit = FALSE,
                         loessfit = TRUE, ci = TRUE, conf = 95, delta = FALSE, deltadate = NA,
                         forecast = FALSE, startdate = NA) {
  pred$pred$col <- is.na(pred$pred[[what]])
  ggplot(pred$pred, aes_string(x = "Date", y = what)) +
    {if(any(pred$wind!=range(pred$pred$Date[!is.na(pred$pred[[what]])])))
      annotate("rect", ymin = 0, ymax = +Inf, xmin = pred$wind[1],
               xmax = pred$wind[2], alpha = 0.1, fill = "orange")} +
    geom_point(size = 1) +
    labs(x = "Dátum", y = paste0("Napi ", if(what=="CaseNumber") "eset" else "halálozás-", "szám [fő/nap]")) +
    {if(funfit) geom_line(data = ~ .x[.x$Date>pred$wind[1]], aes(y = fit, color = col), show.legend = FALSE)} +
    {if(ci&(funfit|forecast)) geom_ribbon(data = ~ .x[.x$Date>pred$wind[1]],
                                          aes(y = fit, ymin = lwr, ymax = upr, fill = col), alpha = 0.2, show.legend = FALSE)} +
    {if(loessfit) geom_smooth(method = "gam", formula = y ~ s(x, bs = "ad"), method.args = list(family = quasipoisson()),
                              se = ci, level = conf/100, n = 500)} +
    {if(delta) geom_vline(xintercept = deltadate)} +
    {if(logy) scale_y_continuous(trans = "log10")} +
    {if(logy) annotation_logticks()} +
    coord_cartesian(ylim = c(NA, max(c(pred$pred[[what]][!is.na(pred$pred[[what]])],
                                       pred$pred$upr[is.na(pred$pred[[what]])]))),
                    xlim = as.Date(c(startdate, NA))) +
    scale_x_date(date_breaks = "months", labels = scales::label_date_short()) +
    theme(plot.caption = element_text(face = "bold", hjust = 0)) +
    labs(caption = "Ferenci Tamás, https://research.physcon.uni-obuda.hu/\nAdatok forrása: JHU CSSE")
}

grText <- function(m, fun, deltar = 0, future = FALSE, deltarDate = NA, startDate = NA) {
  if(fun=="Exponenciális") {
    paste0(if(future) paste0( "A jövőbeli növekedési ráta ", deltarDate, " dátumtól ")  else 
      "A fenti exponenciális illesztéssel a növekedési ráta ", round(coef(m)["Date"]+deltar, 2), " (95%-os CI: ",
      paste0(round(confint(m)["Date",]+deltar, 2), collapse = " - "),
      "). Ez azt jelenti, hogy a duplázódási idő (az ahhoz szükséges idő, hogy a napi esetszám kétszeresére nőjön) ",
      round(log(2)/(coef(m)["Date"]+deltar), 2), " nap (95%-os CI: ",
      paste0(rev(round(log(2)/(confint(m)["Date",]+deltar), 2)), collapse = " - "), ").")
  } else if(fun=="Hatvány") {
    paste0(if(future) paste0( "A jövőbeli hatványkitevő ", deltarDate, " dátumtól ")  else 
      "A fenti hatványfüggvényes illesztéssel a hatványkitevő ", round(coef(m)["log(NumDate)"]+deltar, 2),
      " (95%-os CI: ", paste0(round(confint(m)["log(NumDate)",]+deltar, 2), collapse = " - "), ").")
  } else if(fun=="Logisztikus") {
    paste0("A fenti logisztikus illesztéssel a fordulópont ", round(coef(m)["xmid"], 2), " nap, azaz ",
           as.Date(startDate+as.numeric(round(coef(m)["xmid"], 2))-1), " (95%-os CI: ",
           paste0(round(confint(m)["xmid",], 2), collapse = " - "), "), a skála ",
           round(coef(m)["scal"], 2), " (95%-os CI: ",
           paste0(round(confint(m)["scal",], 2), collapse = " - "), "), az aszimptotikus szint ",
           round(coef(m)["Asym"], 2), " (95%-os CI: ",
           paste0(round(confint(m)["Asym",], 2), collapse = " - "), ").")
  }
}

reprData <- function(CaseNumber, SImu, SIsd, wind = NA) {
  if(any(is.na(wind))) wind <- c(1, length(CaseNumber))
  discrGT <- R0::generation.time("gamma", c(SImu, SIsd))
  res <- rbind(t(sapply(R0::estimate.R(CaseNumber, discrGT, methods = c("ML", "EG"), begin = wind[1],
                                       end = wind[2])$estimates, function(x) c(x$R, x$conf.int))),
               r2R0gamma(with(R0::est.R0.EG(CaseNumber, discrGT, begin = wind[1], end = wind[2]),
                              c(r, unlist(conf.int.r))), SImu, SIsd),
               unlist(EpiEstim::estimate_R(CaseNumber, method = "parametric_si",
                                           config = EpiEstim::make_config(list(mean_si = SImu, std_si = SIsd,
                                                                               t_start = max(c(2, wind[1])),
                                                                               t_end = wind[2])))$R[c("Median(R)",
                                                                                                      "Quantile.0.025(R)",
                                                                                                      "Quantile.0.975(R)")]),
               unlist(EpiEstim::wallinga_teunis(CaseNumber, method = "parametric_si",
                                                config = list(method = "parametric_si", mean_si = SImu, std_si = SIsd,
                                                              n_sim = 10, t_start = max(c(2, wind[1])),t_end = wind[2]))$R[
                                                                c("Mean(R)", "Quantile.0.025(R)", "Quantile.0.975(R)")]))
  # with(R0::smooth.Rt(R0::est.R0.TD(CaseNumber, discrGT, begin = wind[1], end = wind[2]),
  #                    wind[2]-wind[1]+1), c(R, unlist(conf.int))))
  # unlist(EpiEstim::wallinga_teunis(CaseNumber, "parametric_si",
  #                                  list(method = "parametric_si",mean_si = SImu, std_si = SIsd,
  #                                       t_start = max(c(2, wind[1])), t_end = wind[2], n_sim=100))$R[
  #                                         c("Mean(R)","Quantile.0.025(R)", "Quantile.0.975(R)")]),
  # with(R0::smooth.Rt(R0::est.R0.SB(CaseNumber, discrGT, begin = max(c(3L, wind[1])), end = wind[2]),
  #                    wind[2]-max(c(3, wind[1]))+1), c(R, unlist(conf.int))))
  res <- data.table(res)
  colnames(res) <- c("R", "lwr", "upr")
  res$`Módszer` <- c("White", "Wallinga-Lipsitch (diszkretizált)", "Wallinga-Lipsitch (egzakt)", "Cori", "Wallinga-Teunis")
  res
}

reprRtData <- function(CaseNumber, SImu, SIsd, windowlen = 7L, offset = 0L) {
  discrGT <- R0::generation.time("gamma", c(SImu, SIsd))
  res <- rbind(data.table(EpiEstim::estimate_R(CaseNumber, "parametric_si",
                                               config = EpiEstim::make_config(method = "parametric_si", mean_si = SImu,
                                                                              std_si = SIsd,
                                                                              t_start = 2:(length(CaseNumber)-windowlen+1),
                                                                              t_end = (windowlen+1):(length(CaseNumber))))$R[
                                                                                c("Mean(R)", "Quantile.0.025(R)",
                                                                                  "Quantile.0.975(R)")],
                          NumDate = (windowlen+1):(length(CaseNumber)), `Módszer` = "Cori"),
               data.table(t(sapply(1:(length(CaseNumber)-windowlen+1),
                                   function(beg) with(R0::est.R0.EG(CaseNumber, discrGT, begin = beg,
                                                                    end = as.integer(beg+windowlen-1L)),
                                                      c(R, conf.int)))), NumDate = (windowlen):(length(CaseNumber)),
                          `Módszer` = "Wallinga-Lipsitch Exp/Poi"),
               data.table(EpiEstim::wallinga_teunis(CaseNumber, method = "parametric_si",
                                                    config = list(method = "parametric_si",mean_si = SImu, std_si = SIsd, n_sim = 10,
                                                                  t_start = 2:(length(CaseNumber)-windowlen+1-10),
                                                                  t_end = (windowlen+1):(length(CaseNumber)-10)))$R[
                                                                    c("Mean(R)", "Quantile.0.025(R)", "Quantile.0.975(R)")],
                          NumDate = (windowlen+1):(length(CaseNumber)-10), `Módszer` = "Wallinga-Teunis"),
               # with(R0::est.R0.TD(CaseNumber, discrGT, begin = 1L, end = length(CaseNumber)-1L),
               #      cbind(R, conf.int, NumDate = as.numeric(rownames(conf.int)), `Módszer` = "Wallinga-Teunis")),
               # with(R0::est.R0.SB(CaseNumber, discrGT, begin = 3L, end = length(CaseNumber)),
               #      cbind(R, conf.int, NumDate = as.numeric(rownames(conf.int)), `Módszer` = "Bettencourt-Ribeiro")),
               use.names = FALSE)
  res$NumDate <- res$NumDate + offset
  colnames(res)[1:3] <- c("R", "lwr", "upr")
  res
}

binom.test2 <- function(x, n, conf.level) if(n==0) list(estimate = NA, conf.int = c(NA, NA)) else
  binom.test(x, n, conf.level = conf.level)

cfrData <- function(rd, DDTmu, DDTsd, startDate = NULL, conf = 95, last = FALSE, updateProgress = NULL) {
  if (!is.null(startDate)) {
    rd <- rd[Date>=startDate]
    rd$CumDeathNumber <- cumsum(rd$DeathNumber)
    rd$CumCaseNumber <- cumsum(rd$CaseNumber)
  }
  conf <- conf/100
  discrdist <- distcrete::distcrete("lnorm", 1, meanlog = log(DDTmu)-log(DDTsd^2/DDTmu^2+1)/2,
                                    sdlog = sqrt(log(DDTsd^2/DDTmu^2+1)))
  dj <- discrdist$d(0:(nrow(rd)-1))
  rd$u <- round(sapply(1:nrow(rd), function(t) sum(convolve(rd$CaseNumber[1:t], rev(dj[1:t]), type = "open")[1:t])))
  rd$u2 <- round(sapply(1:nrow(rd), function(t) sum(sapply(0:(t-1), function(j) rd$CaseNumber[t-j]*dj[j+1]))))
  if (last) return(plogis(bbmle::coef(bbmle::mle2(CumDeathNumber ~ dbinom(size = u, prob = plogis(p)),
                                                  data = tail(rd, 1), start = list(p = -2)))))
  if(!is.null(updateProgress)) updateProgress(detail = "Előkészítés")
  CfrCorrected <- lapply(10:nrow(rd), function(end) {
    if(!is.null(updateProgress)) updateProgress(detail = paste0("Korrigált (", end-9, "/", nrow(rd)-9, ")"))
    bbmle::mle2(CumDeathNumber ~ dbinom(size = u, prob = plogis(p)), data = rd[end], start = list(p = -2))
  })
  CfrRealtime <- lapply(10:nrow(rd), function(end) {
    if(!is.null(updateProgress))  updateProgress(detail = paste0("Valós idejű (", end-9, "/", nrow(rd)-9, ")"))
    bbmle::mle2(DeathNumber ~ dbinom(size = u2, prob = plogis(p)), data = rd[end], start = list(p = -2))
  })
  if(!is.null(updateProgress)) updateProgress(detail = "Összeállítás")
  rbind(setNames(data.table(t(mapply(function(...) with(binom.test2(...), c(estimate, conf.int)),
                                     rd$CumDeathNumber, rd$CumCaseNumber, MoreArgs = list(conf.level = conf))),
                            "Nyers", rd$Date), c("value", "lwr", "upr", "Típus", "Date")),
        setNames(data.table(sapply(CfrCorrected, function(x) plogis(bbmle::coef(x))),
                   t(sapply(CfrCorrected, function(x) plogis(bbmle::confint(x)))),
                   "Korrigált", rd$Date[-(1:9)]), c("value", "lwr", "upr", "Típus", "Date")),
        setNames(data.table(sapply(CfrRealtime, function(x) plogis(bbmle::coef(x))),
                            t(sapply(CfrRealtime, function(x)
                              plogis(tryCatch(bbmle::confint(x), error = function(e) c(NA, NA))))),
                            "Valós idejű", rd$Date[-(1:9)]), c("value", "lwr", "upr", "Típus", "Date")))
}
