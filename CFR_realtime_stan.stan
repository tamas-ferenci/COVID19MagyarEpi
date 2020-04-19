data {
  int<lower=0> N;
  int DeathNumber[N];
  int u2[N];
}

parameters {
  real<lower=0,upper=1> p[N];
}

model {
  p ~ beta(1, 1);
  DeathNumber ~ binomial(u2, p);
}
