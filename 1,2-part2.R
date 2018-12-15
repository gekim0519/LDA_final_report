library(tidyverse)
library(janitor)
library(lme4)
library(RLRsim)

#import data
frmgham = 
  read.csv2("frmgham2.csv", sep = ",", na.strings=c("","NA")) %>% 
  clean_names() %>% select(cursmoke, everything()) %>% 
  mutate(sex = as.factor(sex),
         bpmeds = as.factor(bpmeds),
         educ = as.factor(educ),
         diabetes = as.factor(diabetes),
         prevap = as.factor(prevap),
         prevchd = as.factor(prevchd),
         prevmi = as.factor(prevmi),
         prevstrk = as.factor(prevstrk),
         prevhyp = as.factor(prevhyp),
         sysbp = as.numeric(levels(sysbp))[sysbp],
         diabp = as.numeric(as.character(diabp)),
         bmi = as.numeric(as.character(bmi))) %>% 
  as.tibble()



##########################################################################################
#(1)The relationship between current smoking status and systolic blood pressure.

#jitter plot of cursmoke and sysbp
frmgham %>% 
  ggplot(., aes(x=cursmoke, y=sysbp)) +
  geom_jitter() + 
  geom_smooth(method = "loess") + 
  ggtitle("Unadjusted relationship between current smoking status and systolic blood pressure")

frmgham = frmgham %>% mutate(cursmoke = as.factor(cursmoke),
                             period = as.factor(period))

##check random effects
ggplot(data = frmgham, aes(x = period, y = sysbp, group = randid)) +
  geom_point() +
  geom_line() +
  facet_wrap( ~ cursmoke, ncol=2) +
  ggtitle("sysbp versus period for smoker and nonsmoker")

syslm = lm(sysbp~cursmoke, data = frmgham)
sysbp <- lmer(sysbp ~ cursmoke + (1|randid), data = frmgham)
exactLRT(sysbp, syslm)
##p-value < 2.2e-16, random effect is significant.

#find the confounder
sysbp_sex <- lmer(sysbp ~ cursmoke + sex + (1|randid), data = frmgham)
sysbp_totchol <- lmer(sysbp ~ cursmoke + totchol + (1|randid), data = frmgham)
sysbp_age <- lmer(sysbp ~ cursmoke + age + (1|randid), data = frmgham)
sysbp_diabp <- lmer(sysbp ~ cursmoke + diabp + (1|randid), data = frmgham)
sysbp_bmi <- lmer(sysbp ~ cursmoke + bmi + (1|randid), data = frmgham)
sysbp_diab <- lmer(sysbp ~ cursmoke + diabetes + (1|randid), data = frmgham)
sysbp_bpmeds <- lmer(sysbp ~ cursmoke + bpmeds + (1|randid), data = frmgham)
sysbp_heart <- lmer(sysbp ~ cursmoke + heartrte + (1|randid), data = frmgham)
sysbp_glu <- lmer(sysbp ~ cursmoke + glucose + (1|randid), data = frmgham)
sysbp_educ <- lmer(sysbp ~ cursmoke + educ + (1|randid), data = frmgham)
sysbp_prevchd <- lmer(sysbp ~ cursmoke + prevchd + (1|randid), data = frmgham)
sysbp_prevap <- lmer(sysbp ~ cursmoke + prevap + (1|randid), data = frmgham)
sysbp_prevmi <- lmer(sysbp ~ cursmoke + prevmi + (1|randid), data = frmgham)
sysbp_strk<- lmer(sysbp ~ cursmoke + prevstrk + (1|randid), data = frmgham)
sysbp_hyp <- lmer(sysbp ~ cursmoke + prevhyp + (1|randid), data = frmgham)
sysbp_per <- lmer(sysbp ~ cursmoke + period + (1|randid), data = frmgham)
tibble(
  variable = c("sex", "totchol", "age", "diabp", "bmi", "diab", "bpmeds",
               "heart", "glu", "educ", "prevchd", "prevap", "prevmi", "prevstrk", "prevhyp",
               "period"),
  OR = 
    exp(coef(summary(sysbp))[2,1]),
  lower_CI  = 
    exp(coef(summary(sysbp))[2,1] - 1.96*(coef(summary(sysbp))[2,2])),
  upper_CI = 
    exp(coef(summary(sysbp))[2,1] + 1.96*(coef(summary(sysbp))[2,2])),
  conf_OR =
    c(exp(coef(summary(sysbp_sex))[2,1]),
      exp(coef(summary(sysbp_totchol))[2,1]),
      exp(coef(summary(sysbp_age))[2,1]),
      exp(coef(summary(sysbp_diabp))[2,1]),
      exp(coef(summary(sysbp_bmi))[2,1]),
      exp(coef(summary(sysbp_diab))[2,1]),
      exp(coef(summary(sysbp_bpmeds))[2,1]),
      exp(coef(summary(sysbp_heart))[2,1]),
      exp(coef(summary(sysbp_glu))[2,1]),
      exp(coef(summary(sysbp_educ))[2,1]),
      exp(coef(summary(sysbp_prevchd))[2,1]),
      exp(coef(summary(sysbp_prevap))[2,1]),
      exp(coef(summary(sysbp_prevmi))[2,1]),
      exp(coef(summary(sysbp_strk))[2,1]),
      exp(coef(summary(sysbp_hyp))[2,1]),
      exp(coef(summary(sysbp_per))[2,1])),
  confounder =
    if_else((conf_OR >= lower_CI & conf_OR <= upper_CI), FALSE, TRUE)
)

#model adding the confounders
sysbp_smoke = lmer(sysbp ~ cursmoke+ age + diabp + bmi + prevhyp+ period + (1|randid), 
                    data = frmgham)

#check interaction
sysbp1 = lmer(sysbp ~ cursmoke*age + diabp + bmi + prevhyp+ period + (1|randid), 
              data = frmgham)
sysbp2 = lmer(sysbp ~ cursmoke*diabp + age + bmi + prevhyp +period+ (1|randid), 
              data = frmgham)
sysbp3 = lmer(sysbp ~ cursmoke*bmi + age + diabp + prevhyp+period + (1|randid), 
              data = frmgham)
sysbp4 = lmer(sysbp ~ cursmoke*prevhyp + age + bmi + diabp +period+ (1|randid), 
              data = frmgham)
sysbp5 = lmer(sysbp ~ cursmoke*period + age + bmi + diabp +prevhyp+ (1|randid), 
              data = frmgham)
summary(sysbp1)
summary(sysbp2)
summary(sysbp3)
summary(sysbp4)
summary(sysbp5)
AIC(sysbp1)
#interaction term reference: Ulrich John, Monika Hanke,Christian Meyer,Anja Schumann. 
#Gender and age differences among current smokers in a general population survey. BMC Public Health. 2005; 5: 57.
#Published online 2005 Jun 3. doi:  [10.1186/1471-2458-5-57]
AIC(sysbp2)
AIC(sysbp3)
AIC(sysbp4)
AIC(sysbp5)

#95% CI for beta of cursmoke and interaction term
b_par<-bootMer(x=sysbp1,FUN=fixef,nsim=200)
boot::boot.ci(b_par,type="basic",index=2)
b_par<-bootMer(x=sysbp1,FUN=fixef,nsim=200)
boot::boot.ci(b_par,type="basic",index=9)





##########################################################################################
#(2)The relationship between current smoking status and diastolic blood pressure.

#jitter plot of cursmoke and diabp
frmgham %>% 
  ggplot(., aes(x=cursmoke, y=diabp)) +
  geom_jitter() + 
  geom_smooth(method = "loess") + 
  ggtitle("Unadjusted relationship between current smoking status and diastolic blood pressure")

#check random effects
ggplot(data = frmgham, aes(x = period, y = diabp, group = randid)) +
  geom_point() +
  geom_line() +
  facet_wrap( ~ cursmoke, ncol=2) +
  ggtitle("diabp versus period for smoker and nonsmoker")

dialm = lm(diabp~cursmoke, data = frmgham)
diabp <- lmer(diabp ~ cursmoke + (1|randid), data = frmgham)
exactLRT(diabp, dialm)
#p-value < 2.2e-16, random effect is significant.

#find confounder
diabp_sex <- lmer(diabp ~ cursmoke + sex + (1|randid), data = frmgham)
diabp_totchol <- lmer(diabp ~ cursmoke + totchol + (1|randid), data = frmgham)
diabp_age <- lmer(diabp ~ cursmoke + age + (1|randid), data = frmgham)
diabp_sysbp <- lmer(diabp ~ cursmoke + sysbp + (1|randid), data = frmgham)
diabp_bmi <- lmer(diabp ~ cursmoke + bmi + (1|randid), data = frmgham)
diabp_diab <- lmer(diabp ~ cursmoke + diabetes + (1|randid), data = frmgham)
diabp_bpmeds <- lmer(diabp ~ cursmoke + bpmeds + (1|randid), data = frmgham)
diabp_heart <- lmer(diabp ~ cursmoke + heartrte + (1|randid), data = frmgham)
diabp_glu <- lmer(diabp ~ cursmoke + glucose + (1|randid), data = frmgham)
diabp_educ <- lmer(diabp ~ cursmoke + educ + (1|randid), data = frmgham)
diabp_prevchd <- lmer(diabp ~ cursmoke + prevchd + (1|randid), data = frmgham)
diabp_prevap <- lmer(diabp ~ cursmoke + prevap + (1|randid), data = frmgham)
diabp_prevmi <- lmer(diabp ~ cursmoke + prevmi + (1|randid), data = frmgham)
diabp_strk<- lmer(diabp ~ cursmoke + prevstrk + (1|randid), data = frmgham)
diabp_hyp <- lmer(diabp ~ cursmoke + prevhyp + (1|randid), data = frmgham)
diabp_per <- lmer(diabp ~ cursmoke + period + (1|randid), data = frmgham)
tibble(
  variable = c("sex", "totchol", "age", "sysbp", "bmi", "diab", "bpmeds",
               "heart", "glu", "educ", "prevchd", "prevap", "prevmi", "prevstrk", "prevhyp",
               "period"),
  OR = 
    exp(coef(summary(diabp))[2,1]),
  lower_CI  = 
    exp(coef(summary(diabp))[2,1] - 1.96*(coef(summary(diabp))[2,2])),
  upper_CI = 
    exp(coef(summary(diabp))[2,1] + 1.96*(coef(summary(diabp))[2,2])),
  conf_OR =
    c(exp(coef(summary(diabp_sex))[2,1]),
      exp(coef(summary(diabp_totchol))[2,1]),
      exp(coef(summary(diabp_age))[2,1]),
      exp(coef(summary(diabp_sysbp))[2,1]),
      exp(coef(summary(diabp_bmi))[2,1]),
      exp(coef(summary(diabp_diab))[2,1]),
      exp(coef(summary(diabp_bpmeds))[2,1]),
      exp(coef(summary(diabp_heart))[2,1]),
      exp(coef(summary(diabp_glu))[2,1]),
      exp(coef(summary(diabp_educ))[2,1]),
      exp(coef(summary(diabp_prevchd))[2,1]),
      exp(coef(summary(diabp_prevap))[2,1]),
      exp(coef(summary(diabp_prevmi))[2,1]),
      exp(coef(summary(diabp_strk))[2,1]),
      exp(coef(summary(diabp_hyp))[2,1]),
      exp(coef(summary(diabp_per))[2,1])),
  confounder =
    if_else((conf_OR >= lower_CI & conf_OR <= upper_CI), FALSE, TRUE)
)

#model adding the confounders
diabp_smoke = lmer(diabp ~ cursmoke + sysbp + bmi + prevhyp + (1|randid), 
                   data = frmgham)
summary(diabp_smoke)

#check interaction
diabp1 = lmer(diabp ~ cursmoke*sysbp + bmi + prevhyp + (1|randid), 
              data = frmgham)
diabp2 = lmer(diabp ~ cursmoke*bmi +sysbp+ prevhyp + (1|randid), 
              data = frmgham)
diabp3 = lmer(diabp ~ cursmoke*prevhyp + bmi + sysbp +(1|randid), 
              data = frmgham)
summary(diabp1)
summary(diabp2)
summary(diabp3)
AIC(diabp1)
AIC(diabp2)
AIC(diabp3)
AIC(diabp_smoke)

#95% CI of beta of cursmoke and interaction term
b_par<-bootMer(x=diabp1,FUN=fixef,nsim=200)
boot::boot.ci(b_par,type="basic",index=2)
b_par<-bootMer(x=diabp1,FUN=fixef,nsim=200)
boot::boot.ci(b_par,type="basic",index=6)
