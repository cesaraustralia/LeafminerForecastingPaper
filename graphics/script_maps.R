library(readr)
library(tidyr)
library(dplyr)
library(zoo)

library(ggplot2)
library(ggthemes)
library(ggridges)
library(RColorBrewer)

library(ncdf4)
library(raster)
library(stars)
library(sf)

library(ozmaps)
library(rnaturalearth)
library(rnaturalearthdata)

scecies_ls <- c("Liriomyza sativae",
                 "Liriomyza huidobrensis",
                 "Liriomyza trifolii",
                 "Diglyphus isaea",
                 "Hemiptarsenus varicornis")

world <- ne_countries(scale = "medium", returnclass = "sf")

################################################################################
##         LOAD DATA POINTS
################################################################################
SLM_Occurrence <- read_delim(
  "../img/SLM_OccurrenceList_clean.csv",
  delim = ";", escape_double = FALSE, trim_ws = TRUE) %>%
  dplyr::filter(!is.na(Lat), !is.na(Lon))

sf_data_ <- st_as_sf(SLM_Occurrence, coords = c("Lon","Lat"), crs = 4326)

################################################################################
##      RESAHPE DATA AND PLOT GRAPHICS
################################################################################
crs_tiff = c("+proj=cea +lat_ts=30 +lon_0=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs")

ls_raster_world_DDbyYY = lapply(1:length(scecies_ls), function(i_file){
     r = raster(paste0("D:/SMAP/nsidc/GROWTHRATE/sumBinaryYear/", scecies_ls[i_file], "_daily.nc"),
                crs = crs_tiff)
     r[is.infinite(r[,])] <- NA
     r = st_as_stars(r)
     r = st_transform(r, crs = 4326)
     return(r)
})
names(ls_raster_world_DDbyYY) = scecies_ls
save(ls_raster_world_DDbyYY, file = "data/ls_raster_world_DDbyYY.rda")

for(i_file in 1:length(scecies_ls)){
  r = ls_raster_world_DDbyYY[[i_file]]

  sf_data = sf_data_ %>%
    dplyr::filter(sf_data_$Pest.scientific.name == scecies_ls[i_file])

  plt <- ggplot() +
    geom_stars(data = r) +
    geom_sf(data = world, fill = NA) +
    geom_sf(data = sf_data, size = 1.5, color = "blue") +
    scale_fill_gradientn(
      colours = brewer.pal(11,"RdYlGn"),
      name = "Number predicted \n positive days",
      limits = c(0,365)) +
    labs(title = paste("Species:", scecies_ls[i_file]), x ="", y = "") +
    theme_minimal()

  ggsave(filename = paste0(
    "../img/World_GR_DDbyYY_", scecies_ls[i_file], ".png"),
    plot = plt,
    width = 3900, height = 1800, units= "px")
}

################################################################################
## COMPUTE THE BOYCE INDEX
################################################################################
r = ls_raster_world_DDbyYY[[1]]
sf = sf_data_

range_ = function(val,ref,p){
  max(val-p,min(ref)):min(val+p,max(ref))
}

extract_ = function(r,sf){
  x_lon = unique(as.numeric(st_dimensions(r)$x$values))
  y_lat = unique(as.numeric(st_dimensions(r)$y$values))

  pts = st_coordinates(sf)
  x_val = findInterval(pts[,1], x_lon)
  y_val = length(y_lat) - findInterval(pts[,2], rev(y_lat))

  out = sapply(1:nrow(pts), function(i){
    mean(r$unnamed[range_(x_val[i],1:length(x_lon),2),range_(y_val[i],1:length(y_lat),2)], na.rm=TRUE)
  })

  return(out)
}


ls_extract_DDbyYY = lapply(1:length(scecies_ls), function(i_file){
  r = ls_raster_world_DDbyYY[[i_file]]
  val = extract_(r,sf_data_)
  return(val)
})
names(ls_extract_DDbyYY) = scecies_ls
save(ls_extract_DDbyYY, file = "data/ls_extract_DDbyYY.rda")

DDbyMM = c(0,31,28,31,30,31,30,31,31,30,31,30,31)
cum_DDbyMM = cumsum(DDbyMM)

for(i_file in 1:3){
  r = ls_raster_world_DDbyYY[[i_file]]
  obs_nVal = sapply(1:12, function(i){ sum(r$unnamed %in% cum_DDbyMM[i]:cum_DDbyMM[i+1], na.rm=TRUE)})
  freq_obs = obs_nVal / sum(obs_nVal)

  val = ls_extract_DDbyYY[[i_file]]
  sim_nVal = sapply(1:12, function(i){ sum(round(val) %in% cum_DDbyMM[i]:cum_DDbyMM[i+1], na.rm=TRUE)})
  freq_sim = sim_nVal / sum(sim_nVal)

  ratio_sim_obs =  freq_sim / freq_obs
  ratio_obs_sim =  freq_obs / freq_sim

  p_spearman = cor.test(ratio_sim_obs,1:12)

  data = data.frame(
    month = 1:12,
    freq_obs = freq_obs,
    freq_sim = freq_sim,
    ratio_sim_obs = ratio_sim_obs,
    ratio_obs_sim = ratio_obs_sim
  ) %>%
    dplyr::filter(!(is.na(ratio_sim_obs)))

  plt2 <- ggplot(data) +
    theme_minimal() +
    theme(legend.position = "none") +
    labs(
      x = "Number of positive month",
      y = "Predicted-to-expected ratio") +
    scale_x_continuous(breaks =1:12) +
    annotate(
      "text", x =4, y = 2,
      label = paste("Boyce index:", round(p_spearman$estimate,digits=3))) +
    geom_bar(
      aes(x=month, y = ratio_sim_obs, fill = month),
      width=1, stat = "identity") +
    geom_hline(yintercept = 1) +
    # geom_abline(slope=1,intercept = 0) +
    scale_fill_gradientn(
      colours = brewer.pal(11,"RdYlGn"),
      name = "# days/month  with \n positive growth rate")
  # plt2

  ggsave(filename = paste0(
    "../img/BoyceIndex_hist_",scecies_ls[i_file], ".png"),
    plot = plt2,
    width = 1200, height = 700, units= "px")
}

################################################################################
## PRODUCE MAP WITH ZOOM ON AUSTRALIA
################################################################################

DT = data.frame(
  name = c("Lakeland", "Bundaberg", "Kununurra", "Werribee", "Mildura"),
  lat=c(-15.835572, -24.951024, -15.726019,-37.943556,-34.245636),
  lon=c(144.836652, 152.331365, 128.713446,144.656463,142.198147)
)
sf_DT = st_as_sf(DT, coords = c("lon","lat"), crs = 4326)

# st_transform(sf_DT, crs = crs_tiff)

sf_oz <- st_transform(ozmap("states"),crs = 4326)
r_oz = st_crop(r, sf_oz, crop = TRUE)

for(i_file in 1:length(scecies_ls)){
  r = ls_raster_world_DDbyYY[[i_file]]
  r_oz = st_crop(r, sf_oz, crop = TRUE)

  plt <- ggplot() +
    geom_stars(data = r_oz) +
    geom_sf(data = sf_oz, fill = NA) +
    geom_sf(data = sf_DT, size = 2, color = "#009bf4") +
    geom_sf_text(data = sf_DT, aes(label = name),
                 nudge_x = c(6,6,-6,-6.5,-8),
                 nudge_y = c(2,2,3,-2,-3),
                 color = "#009bf4") +
    labs(title = paste("Species:", scecies_ls[i_file])) +
    scale_fill_gradientn(
      colours = brewer.pal(11,"RdYlGn"),
      name = "#Days positive\n Growth rate") +
    labs(x ="", y = "") +
    theme_minimal() +
    theme(
      # legend.position = "none", # remove legend
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.x = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks.y = element_blank(),
      axis.text.y = element_blank())

  ggsave(filename = paste0(
    "../img/AUS_GR_DDbyYY_cities", scecies_ls[i_file],".png"),
    plot = plt)
}

################################################################################
## RETRIEVE VALUES OF 5 SITES
################################################################################

path_files = "D:/SMAP/nsidc/GROWTHRATE/lower_res_10/series_AUS"
list_files = list.files(path_files)

ls = lapply(list_files, function(i_file){ read_csv(paste0(path_files, "/", i_file))})

df = do.call("rbind", ls) %>%
  pivot_longer(-c("Days","DaysNum", "MonthName","MonthNum", "Species"), names_to = "Site", values_to = "GrowthRate")

plt <- ggplot(data = df) +
  theme_minimal() +
  labs(
    x = "Month of the year",
    y = "Population growth rate (1/d)") +
  scale_color_manual(
    values = c("#2AC0C0", "#3D68CB","#FA8B32", "#F73136", "#FAB632"),
    name = "Species") +
  scale_x_continuous(
    breaks = seq(15,350,30),
    labels = month.name[seq(1,12,1)]) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  scale_y_continuous(limits = c(-0.5,NA)) +
  geom_line(aes(x = DaysNum, y = GrowthRate, color = Species)) +
  geom_hline(yintercept = 0) +
  facet_grid(~Site)
plt

ggsave(filename = "../img/PopGrowthRate.png",
       width = 12, height=4,  plot = plt)


df2 <- df %>%
  group_by(Species, Site) %>%
  arrange(Days) %>%
  # mutate(GrowthRate_trend = slider::slide_dbl(GrowthRate, mean, .before = 1, .after = 0)) %>%
  mutate(GrowthRate_trend = rollapply(GrowthRate,30,mean,fill=NA)) %>%
  ungroup()

plt2 <- ggplot(data = df2) +
  theme_minimal() +
  labs(
    x = "Month of the year",
    y = "Population growth rate (1/d) \n 30 days rolling mean") +
  scale_color_manual(
    values = c("#2AC0C0", "#3D68CB","#FA8B32", "#F73136", "#FAB632"),
    name = "Species") +
  scale_x_continuous(
    breaks = seq(15,350,30),
    labels = month.name[seq(1,12,1)]) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  scale_y_continuous(limits = c(-0.5,NA)) +
  geom_line(aes(x = DaysNum, y = GrowthRate_trend, color = Species)) +
  geom_hline(yintercept = 0) +
  facet_grid(~Site)
plt2

ggsave(filename = "data-raw/PopGrowthRate_trend.png",
       width = 12, height=4,  plot = plt2)

################################################################################
## GRAPHIC OF TEMPERATURE ON 5 SITES
################################################################################

series_AUS_CLIMATE <- read_csv("D:\\SMAP\\nsidc\\series_AUS_CLIMATE.csv")  %>%
  dplyr::rename(
    Cities = City,
    `Wilting fraction` = wlt,
    Temperature = tmp) %>%
  tidyr::pivot_longer(
    c(`Wilting fraction`, Temperature),
    names_to = "GeophysicalVariables",
    values_to = "GeophysicalValues")

plt_clm <- ggplot(data = series_AUS_CLIMATE) +
  theme_minimal() +
  labs(
    x = "Month of the year") +
  scale_x_continuous(
    breaks = seq(15,350,30),
    labels = month.name[seq(1,12,1)]) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  geom_line(aes(x = DaysNum, y = GeophysicalValues, color = Cities)) +
  facet_wrap(~GeophysicalVariables, scales = "free_y")
plt_clm

