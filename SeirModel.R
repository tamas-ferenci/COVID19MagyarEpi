seir_step <- pomp::Csnippet("
  double dN_SE1 = rbinom(S,1-exp(-Beta * (I1+I2+I3)/N*dt));
  double dN_E1E2 = rbinom(E1,1-exp(-2 * alpha *dt));
  double dN_E2I1 = rbinom(E2,1-exp(-2 * alpha *dt));
  double dN_I1I2 = rbinom(I1,1-exp(-3 * gamma*dt));
  double dN_I2I3 = rbinom(I2,1-exp(-3 * gamma*dt));
  double dN_I3R = rbinom(I3,1-exp(-3 * gamma*dt));
  S -= dN_SE1;
  E1 += dN_SE1 - dN_E1E2;
  E2 += dN_E1E2 - dN_E2I1;
  I1 += dN_E2I1 - dN_I1I2;
  I2 += dN_I1I2 - dN_I2I3;
  I3 += dN_I2I3 - dN_I3R;
  R += dN_I3R;
  H += dN_E2I1;
")

seir_init <- pomp::Csnippet("
  S = N-5;
  E1 = 0;
  E2 = 0;
  I1 = 5;
  I2 = 0;
  I3 = 0;
  R = 0;
  H = 5;
")

dmeas <- pomp::Csnippet("
  lik = dbinom(CaseNumber,H,rho,give_log);
")

rmeas <- pomp::Csnippet("
  CaseNumber = rbinom(H,rho);
")