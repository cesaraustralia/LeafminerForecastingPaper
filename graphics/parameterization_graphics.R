library(readr)
library(ggplot2)
library(dplyr)

################################################################################
#
# Intrinsic Growth Rate Curves
#
################################################################################

dfp <- read_delim("../data/growthRate_parameters.csv", delim = ";", escape_double = FALSE, trim_ws = TRUE)
GRmodel <- function(x,m){
  R = 8.31446261815324 # J K^-1 mol^-1
  R = 1.987 # cal K^-1 mol^-1
  P = m$p
  HA = m$HA
  HL = m$HL
  HH = m$HH
  TL = m$T0.5L
  TH = m$T0.5H
  TR = m$Tref + 273.15
  r = P * x/TR * exp(HA/R * (1/TR - 1/x)) /
    (1 + exp(HL/R * (1/TL - 1/x)) + exp(HH/R * (1/TH - 1/x)))
  return(r)
}
x_C = seq(10,30, length.out = 20)
x_K = x_C + 273.15
GRmodel(x_K, dfp[1,])

df_model = data.frame(x_C = seq(0,45, length.out = 100)) %>%
  dplyr::mutate(x_K = x_C + 273.15) %>%
  dplyr::mutate(
    `Liriomyza sativae` = GRmodel(x_K, dfp[1,]),
    `Liriomyza huidobrensis` = GRmodel(x_K, dfp[2,]),
    `Liriomyza trifolii` = GRmodel(x_K, dfp[3,]),
    `Diglyphus isaea` = GRmodel(x_K, dfp[4,]),
    `Hemiptarsenus varicornis` = GRmodel(x_K, dfp[5,])
  ) %>%
  tidyr::pivot_longer(-c("x_C", "x_K"), names_to = "species")

df <- read_csv("../data/data_intrinsic_growth_rate.csv")

plt = ggplot() + 
  theme_minimal() +
  labs(x = "Temperature, °C",
       y = "Intrinsic growth rate, 1/d",
       color = "Species") +
  scale_color_manual(
    values = c("#2AC0C0", "#3D68CB","#FA8B32", "#F73136", "#FAB632")) +
  geom_point(data = df,
            aes(x = x_value, y = y_value, color = species)) +
  geom_line(data = df_model,
             aes(x = x_C, y = value, color = species))

ggsave(filename = "../img/GRcurves.png",  plot = plt, width = 7, height = 4)  

plt_intrinsicGR <- plt
save(plt_intrinsicGR, file = "data/plt_intrinsicGR.rda")


################################################################################
#
# Stressor mortality rate
#
################################################################################

dfp <- read_delim("../data/data_parameterization//growthRate_parameters.csv", delim = ";", escape_double = FALSE, trim_ws = TRUE)

lower <- function(x, t, r){ log(2) / abs(ifelse(x < t, (t - x)*r,0))}
upper <- function(x, t, r){ log(2) / abs(ifelse(x > t, (x - t)*r,0))}

df_lower = data.frame(x = seq(-30,5,length.out = 100)) %>%
  dplyr::mutate(
    `Liriomyza sativae` = lower(x,dfp[1,]$CTmin,dfp[1,]$mTmin),
    `Liriomyza huidobrensis` = lower(x,dfp[2,]$CTmin,dfp[2,]$mTmin),
    `Liriomyza trifolii` = lower(x,dfp[3,]$CTmin,dfp[3,]$mTmin),
    `Diglyphus isaea` = lower(x,dfp[4,]$CTmin,dfp[4,]$mTmin),
    `Hemiptarsenus varicornis` = lower(x,dfp[5,]$CTmin,dfp[5,]$mTmin)) %>%
  tidyr::pivot_longer(-"x", names_to = "Species") %>%
  dplyr::filter(!is.infinite(value))  %>%
  dplyr::mutate(stressor = "cold")

plt_lower = ggplot() +
  theme_minimal() +
  labs(x = "Temperature, °C",
       y = "LT50, d",
       color = "Species") +
  # scale_y_log10() +
  lims(y = c(0,5)) +
  scale_color_manual(
    values = c("#2AC0C0", "#3D68CB","#FA8B32", "#F73136", "#FAB632")) +
  geom_line(data = df_lower,
            aes(x = x, y = value, color = Species))


ggsave(filename = "../img/GR_LT50_lower.png",  plot = plt_lower, width = 4, height = 2.5)  

df_upper = data.frame(x = seq(30,45,length.out = 100)) %>%
  dplyr::mutate(
    `Liriomyza sativae` = upper(x,dfp[1,]$CTmax,dfp[1,]$mTmax),
    `Liriomyza huidobrensis` = upper(x,dfp[2,]$CTmax,dfp[2,]$mTmax),
    `Liriomyza trifolii` = upper(x,dfp[3,]$CTmax,dfp[3,]$mTmax),
    `Diglyphus isaea` = upper(x,dfp[4,]$CTmax,dfp[4,]$mTmax),
    `Hemiptarsenus varicornis` = upper(x,dfp[5,]$CTmax,dfp[5,]$mTmax)) %>%
  tidyr::pivot_longer(-"x", names_to = "Species") %>%
  dplyr::filter(!is.infinite(value))  %>%
  dplyr::mutate(stressor = "heat")

plt_upper = ggplot() +
  theme_minimal() +
  labs(x = "Temperature, °C",
       y = "LT50, d",
       color = "Species") +
  # scale_y_log10() +
  lims(y = c(0,5)) +
  scale_color_manual(
    values = c("#2AC0C0", "#3D68CB","#FA8B32", "#F73136", "#FAB632")) +
  geom_line(data = df_upper,
            aes(x = x, y = value, color = Species))

ggsave(filename = "../img/GR_LT50_upper.png",  plot = plt_upper, width = 4, height = 2.5)


df_total = dplyr::bind_rows(df_lower, df_upper)

plt_stressorTemp <- ggplot(data = df_total) +
  theme_minimal() +
  labs(x = "Temperature, °C",
       y = "LT50, d",
       color = "Species") +
  # scale_y_log10() +
  lims(y = c(0,5)) +
  scale_color_manual(
    values = c("#2AC0C0", "#3D68CB","#FA8B32", "#F73136", "#FAB632")) +
  geom_line(aes(x = x, y = value, color = Species)) +
  facet_wrap( .~ stressor, scale = "free")
plt_stressorTemp

save(plt_stressorTemp, file = "../data/plt_stressorTemp.rda")



df_wilting = data.frame(x = seq(0.75,1,length.out = 100)) %>%
  dplyr::mutate(
    `Liriomyza sativae` = upper(x,dfp[1,]$Cwilt,dfp[1,]$mwilt),
    `Liriomyza huidobrensis` = upper(x,dfp[2,]$Cwilt,dfp[2,]$mwilt),
    `Liriomyza trifolii` = upper(x,dfp[3,]$Cwilt,dfp[3,]$mwilt),
    `Diglyphus isaea` = upper(x,dfp[4,]$Cwilt,dfp[4,]$mwilt),
    `Hemiptarsenus varicornis` = upper(x,dfp[5,]$Cwilt,dfp[5,]$mwilt)) %>%
  tidyr::pivot_longer(-"x", names_to = "Species") %>%
  dplyr::filter(!is.infinite(value)) %>%
  dplyr::mutate(stressor = "wilting")

plt_stressorWilting = ggplot() +
  theme_minimal() +
  labs(x = "Proportion wilting",
       y = "LT50, d",
       color = "Species") +
  # scale_y_log10() +
  lims(y = c(0,5)) +
  scale_color_manual(
    values = c("#2AC0C0", "#3D68CB","#FA8B32", "#F73136", "#FAB632")) +
  geom_line(data = df_wilting,
            aes(x = x, y = value, color = Species, linetype = Species), size = 1)

ggsave(filename = "../img/GR_LT50_wilting.png",  plot = plt_stressorWilting, width = 4, height = 2.5)  

save(plt_stressorWilting, file = "data/plt_stressorWilting.rda")

  
  


