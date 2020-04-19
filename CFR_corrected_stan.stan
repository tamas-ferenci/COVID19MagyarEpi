data {
  int<lower=0> N;
  int CumDeathNumber[N];
  int u[N];
}

parameters {
  real<lower=0,upper=1> p[N];
}

model {
  p ~ beta(1, 1);
  CumDeathNumber ~ binomial(u, p);
}
