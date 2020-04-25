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
  if(any(is.na(wind))) wind <- c(rd$NumDate[1], tail(rd$NumDate,1))
  if(projper>0) rd <- rbind(rd, data.table(Date = seq.Date(tail(rd$Date,1), tail(rd$Date,1)+projper, by = "days"),
                                           CaseNumber = NA, DeathNumber = NA, CumCaseNumber = NA, CumDeathNumber = NA,
                                           NumDate = tail(rd$NumDate,1):(tail(rd$NumDate,1)+projper)))
  rd$Deviated <- (rd$Date >= deltardate)&is.na(rd[[what]])
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
    data <- if(fform!="Logisztikus") rd[rd[[what]]!=0] else rd
    if(fform=="Logisztikus") family <- gaussian(link = "log")
  } else if(distr=="Poisson") {
    fitfun <- if(fform!="Logisztikus") glm else gnm::gnm
    data <- rd
    #family <- if(fform!="Logisztikus") poisson(link = "log") else poisson(link = "identity")
    family <- poisson(link = "log")
  } else if(distr=="NB/QP") {
    fitfun <- if(fform!="Logisztikus") MASS::glm.nb else gnm::gnm
    if(fform=="Logisztikus") family <- quasipoisson(link = "log")
    data <- rd
  }
  parlist <- list(formula = fitformula, data = data[NumDate>=wind[1]&NumDate<=wind[2]&!is.na(data[[what]])])
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

sepform <- function(x) format(x, big.mark = " ", scientific = FALSE)

epicurvePlot <- function(pred, what = "CaseNumber", logy = FALSE, funfit = FALSE,
                         loessfit = TRUE, ci = TRUE, conf = 95, delta = FALSE, deltadate = NA, wind = NA) {
  pred$col <- is.na(pred[[what]])
  ggplot(pred, aes_string(x = "Date", y = what)) +
    {if(any(!is.na(wind))) annotate("rect", ymin = -Inf, ymax = +Inf, xmin = wind[1], xmax = wind[2], alpha = 0.1,
                                    fill = "red")} +
    geom_point(size = 3) +
    labs(x = "Dátum", y = paste0("Napi ", if(what=="CaseNumber") "eset" else "halálozás-", "szám [fő/nap]")) +
    {if(logy) scale_y_log10()} + {if(funfit) geom_line(aes(y = fit, color = col), show.legend = FALSE)} +
    {if(funfit&ci) geom_ribbon(aes(y = fit, ymin = lwr, ymax = upr, fill = col), alpha = 0.2, show.legend = FALSE)} +
    {if(loessfit) geom_smooth(formula = y ~ x, method = "loess", col = "blue", se = ci,
                              fill = "blue", alpha = 0.2, level = conf/100, size = 0.5)} +
    {if(delta) geom_vline(xintercept = deltadate)} +
    coord_cartesian(ylim = c(NA, max(c(pred[[what]][!is.na(pred[[what]])], pred$upr[is.na(pred[[what]])]))))
}

grText <- function(m, fun, deltar = 0, future = FALSE, deltarDate = NA, startDate = NA) {
  if(fun=="Exponenciális") {
    paste0(if(future) paste0( "A jövőbeli növekedési ráta ", deltarDate, " dátumtól ")  else 
      "A fenti exponenciális illesztéssel a növekedési ráta ", round_dt(coef(m)+deltar)[rn=="Date", -"rn"], " (95%-os CI: ",
      paste0(round_dt(confint(m)+deltar)[rn=="Date", -"rn"], collapse = " - "),
      "). Ez azt jelenti, hogy a duplázódási idő (az ahhoz szükséges idő, hogy a napi esetszám kétszeresére nőjön) ",
      round_dt(log(2)/(coef(m)+deltar))[rn=="Date", -"rn"], " nap (95%-os CI: ",
      paste0(rev(round_dt(log(2)/(confint(m)+deltar))[rn=="Date", -"rn"]), collapse = " - "), ").")
  } else if(fun=="Hatvány") {
    paste0(if(future) paste0( "A jövőbeli hatványkitevő ", deltarDate, " dátumtól ")  else 
      "A fenti hatványfüggvényes illesztéssel a hatványkitevő ", round_dt(coef(m)+deltar)[rn=="log(NumDate)", -"rn"],
      " (95%-os CI: ", paste0(round_dt(confint(m)+deltar)[rn=="log(NumDate)", -"rn"], collapse = " - "), ").")
  } else if(fun=="Logisztikus") {
    paste0("A fenti logisztikus illesztéssel a fordulópont ", round_dt(coef(m))[rn=="xmid",-"rn"], " nap, azaz ",
           as.Date(startDate+as.numeric(round_dt(coef(m))[rn=="xmid",-"rn"])-1), " (95%-os CI: ",
           paste0(round_dt(confint(m))[rn=="xmid", -"rn"], collapse = " - "), "), a skála ",
           round_dt(coef(m))[rn=="scal", -"rn"], " (95%-os CI: ",
           paste0(round_dt(confint(m))[rn=="scal", -"rn"], collapse = " - "), "), az aszimptotikus szint ",
           round_dt(coef(m))[rn=="Asym", -"rn"], " (95%-os CI: ",
           paste0(round_dt(confint(m))[rn=="Asym", -"rn"], collapse = " - "), ").")
  }
}

grData <- function(m, SImu, SIsd) {
  data.frame(R = lm2R0gamma_sample(m, SImu, SIsd))
}

grSwData <- function(rd, ms, SImu, SIsd, windowlen) {
  res <- lapply(ms, function(m) lm2R0gamma_sample(m, SImu, SIsd))
  res <- data.table(do.call(rbind, lapply(res, function(x)
    c(mean(x, na.rm = TRUE), quantile(x, c(0.025, 0.975), na.rm = TRUE)))), check.names = TRUE)
  res$Date <- rd$Date[windowlen:nrow(rd)]
  res
}

branchData <- function(rd, what = "CaseNumber", SImu, SIsd, wind = NA) {
  if(any(is.na(wind))) wind <- c(max(c(2, rd$NumDate[1])), tail(rd$NumDate,1))
  data.table(R = EpiEstim::sample_posterior_R(EpiEstim::estimate_R(
    rd[[what]], method = "parametric_si",
    config = EpiEstim::make_config(list(mean_si = SImu, std_si = SIsd, t_start = wind[1], t_end = wind[2])))))
}

branchSwData <- function(rd, what = "CaseNumber", SImu, SIsd, windowlen) {
  res <- EpiEstim::estimate_R(rd[[what]], method = "parametric_si",
                              config = EpiEstim::make_config(list(
                                t_start = seq(2, nrow(rd)-windowlen+1), t_end = (2+windowlen-1):nrow(rd),
                                mean_si = SImu, std_si = SIsd)))$R
  res$Date <- rd$Date[(windowlen+1):nrow(rd)]
  res
}

cfrMCMC <- function(rd, modCorrected, modRealtime, DDTmu, DDTsd) {
  discrdist <- distcrete::distcrete("lnorm", 1, meanlog = log(DDTmu)-log(DDTsd^2/DDTmu^2+1)/2,
                                    sdlog = sqrt(log(DDTsd^2/DDTmu^2+1)))
  u <- round(sapply(1:nrow(rd), function(t) sum(sapply(1:t, function(i)
    sum(sapply(0:(i-1), function(j) rd$CaseNumber[i-j]*discrdist$d(j)))))))
  u2 <- round(sapply(1:nrow(rd), function(t) sum(sapply(0:(t-1), function(j) rd$CaseNumber[t-j]*discrdist$d(j)))))
  fitCorrected <- rstan::sampling(modCorrected, data = list(N = nrow(rd), CumDeathNumber = rd$CumDeathNumber, u = u))
  fitRealtime <- rstan::sampling(modRealtime, data = list(N = nrow(rd), DeathNumber = rd$DeathNumber, u2 = u2))
  list(fitCorrected = fitCorrected, fitRealtime = fitRealtime)
}

cfrData <- function(rd, DDTmu, DDTsd, MCMCres, conf = 95) {
  conf <- conf/100
  rbind(data.table(t(mapply(function(...) with(binom.test(...),
                                               c(value = as.numeric(estimate), lwr = conf.int[1], upr = conf.int[2])),
                            rd$CumDeathNumber, rd$CumCaseNumber, MoreArgs = list(conf.level = conf))),
                   `Típus` = "Nyers", Date = rd$Date),
        cbind(setNames(data.table(rstan::summary(MCMCres$fitCorrected, "p", c(0.5, (1-conf)/2, 1-(1-conf)/2))$summary[,4:6]),
                       c("value", "lwr", "upr")), `Típus` = "Korrigált", Date = rd$Date),
        cbind(setNames(data.table(rstan::summary(MCMCres$fitRealtime, "p", c(0.5, (1-conf)/2, 1-(1-conf)/2))$summary[,4:6]),
                       c("value", "lwr", "upr")), `Típus` = "Valós idejű", Date = rd$Date))
}
