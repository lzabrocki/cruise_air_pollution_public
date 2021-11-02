#-------------------------------------------------------------------------

# SCRIPT REGRESSION ANALYSIS ON MATCHING DATA: EXITING CRUISE EXPERIMENT

#-------------------------------------------------------------------------

# load packages
library(tidyverse) # for data manipulation and visualization

# load matched data
data_matching <- readRDS("~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/matching_data.rds") %>%
  mutate(is_treated = ifelse(is_treated == TRUE, "treated", "control"))

#------------------------------------------------------

# FORMATTING THE MATCHING DATA FOR REGRESSION ANALYSIS

#------------------------------------------------------

data_matching_analysis <- data_matching %>%
  # select relevant variables
  select(is_treated, temperature_average, humidity_average, wind_speed, rainfall_height_dummy,
         wind_direction_categories, hour, weekday, holidays_dummy, bank_day_dummy, month, year, 
         contains("no2"), contains("o3"), contains("pm10"), contains("pm25"), contains("so2")) %>%
  # make sure categorical variables are factors
  mutate_at(vars(is_treated, rainfall_height_dummy:year), ~ as.factor(.)) %>%
  # reshape in long according to pollutants
  pivot_longer(cols = c(contains("no2"), contains("o3"), contains("pm10"), contains("pm25"), contains("so2")),
               names_to = "pollutant_variable", values_to = "concentration")

# create a nicely label pollutant variable and an hour indicator
data_matching_analysis <- data_matching_analysis %>%
  mutate(pollutant = NA %>%
           ifelse(str_detect(pollutant_variable, "no2_l"), "NO2 Longchamp",.) %>%
           ifelse(str_detect(pollutant_variable, "no2_sl"), "NO2 Saint-Louis",.) %>%
           ifelse(str_detect(pollutant_variable, "o3"), "O3 Longchamp",.) %>%
           ifelse(str_detect(pollutant_variable, "pm10_l"), "PM10 Longchamp",.) %>%
           ifelse(str_detect(pollutant_variable, "pm10_sl"), "PM10 Saint-Louis",.) %>%
           ifelse(str_detect(pollutant_variable, "pm25"), "PM2.5 Longchamp",.) %>%
           ifelse(str_detect(pollutant_variable, "so2"), "SO2 Lonchamp",.)) %>%
  mutate(time = 0 %>%
           ifelse(str_detect(pollutant_variable, "lag_1"), -1, .) %>%
           ifelse(str_detect(pollutant_variable, "lag_2"), -2, .) %>%
           ifelse(str_detect(pollutant_variable, "lag_3"), -3, .) %>%
           ifelse(str_detect(pollutant_variable, "lead_1"), 1, .) %>%
           ifelse(str_detect(pollutant_variable, "lead_2"), 2, .) %>%
           ifelse(str_detect(pollutant_variable, "lead_3"), 3, .)) %>%
  select(-pollutant_variable)

# we nest the data by pollutant and time for the regression analysis
data_matching_analysis <- data_matching_analysis %>% 
  group_by(pollutant, time) %>%
  nest()

#-------------------------------------------

# RUNNING THE MODEL AND CLEANING ITS OUTPUT

#-------------------------------------------

# running the model
data_matching_analysis <- data_matching_analysis %>%
  mutate(
    # regression_model
    regression_model = map(data, ~lm(concentration ~ is_treated + 
                                       temperature_average + I(temperature_average^2) + 
                                       rainfall_height_dummy + humidity_average +
                                       wind_speed + wind_direction_categories + 
                                       hour + weekday + holidays_dummy + bank_day_dummy + 
                                       month*year, data = .)))

# storing the results
data_matching_analysis <- data_matching_analysis %>%
  select(-data) %>%
  mutate(regression_results = map(regression_model, ~ broom::tidy(., conf.int	= TRUE))) %>%
  unnest(regression_results) %>%
  dplyr::filter(term=="is_treatedtreated") %>%
  select(pollutant, time, estimate, std.error)

# save results
saveRDS(data_matching_analysis, "~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/data_matching_regression.RDS")
