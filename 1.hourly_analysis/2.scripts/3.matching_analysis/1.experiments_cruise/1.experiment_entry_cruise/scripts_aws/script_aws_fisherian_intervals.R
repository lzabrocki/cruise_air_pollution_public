#------------------------------------------------------------

# SCRIPT RANDOMIZATION INFERENCE: ENTERING CRUISE EXPERIMENT

#------------------------------------------------------------

# this script computes the 95% fisherian intervals
# for the entering cruise experiment at the hourly level

# load packages
library(tidyverse) # for data manipulation and visualization

# load matched data
data_matched <- readRDS("~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/1.experiment_entry_cruise/matched_data_entry_cruise.RDS") %>%
  mutate(is_treated = ifelse(is_treated == TRUE, "treated", "control"))

#--------------------------

# FORMATTING THE DATA

#--------------------------

data <- data_matched %>%
  select(is_treated, pair_number, contains("no2_l"), contains("no2_sl"), contains("o3"), contains("pm10_l"), contains("pm10_sl"),contains("pm25"), contains("so2")) %>%
  pivot_longer(cols = -c(pair_number, is_treated), names_to = "variable", values_to = "concentration") %>%
  mutate(pollutant = NA %>%
           ifelse(str_detect(variable, "no2_l"), "NO2 Longchamp",.) %>%
           ifelse(str_detect(variable, "no2_sl"), "NO2 Saint-Louis",.) %>%
           ifelse(str_detect(variable, "o3"), "O3 Longchamp",.) %>%
           ifelse(str_detect(variable, "pm10_l"), "PM10 Longchamp",.) %>%
           ifelse(str_detect(variable, "pm10_sl"), "PM10 Saint-Louis",.) %>%
           ifelse(str_detect(variable, "pm25"), "PM2.5 Longchamp",.) %>%
           ifelse(str_detect(variable, "so2"), "SO2 Lonchamp",.)) %>%
  mutate(time = 0 %>%
           ifelse(str_detect(variable, "lag_1"), -1, .) %>%
           ifelse(str_detect(variable, "lag_2"), -2, .) %>%
           ifelse(str_detect(variable, "lag_3"), -3, .) %>%
           ifelse(str_detect(variable, "lead_1"), 1, .) %>%
           ifelse(str_detect(variable, "lead_2"), 2, .) %>%
           ifelse(str_detect(variable, "lead_3"), 3, .)) %>%
  select(-variable) %>%
  select(pair_number, is_treated, pollutant, time, concentration) %>% 
  pivot_wider(names_from = is_treated, values_from = concentration)

#--------------------------

# COMPUTE PAIR DIFFERENCES

#--------------------------

data_pair_difference_pollutant <- data %>%
  mutate(difference = treated-control) %>%
  select(-c(treated, control))

#-----------------------------------

# COMPUTING 95% FISHERIAN INTERVALS

#-----------------------------------

# create a nested dataframe with 
# the set of constant treatment effect sizes
# and the vector of observed pair differences
ri_data_fi <- data_pair_difference_pollutant %>%
  select(pollutant, time, difference) %>%
  group_by(pollutant, time) %>%
  summarise(data_difference = list(difference)) %>%
  group_by(pollutant, time, data_difference) %>%
  expand(effect = seq(from = -10, to = 10, by = 0.1)) %>%
  ungroup()

# function to get the observed statistic
adjusted_pair_difference_function <- function(pair_differences, effect){
  adjusted_pair_difference <- pair_differences-effect
  return(adjusted_pair_difference)
} 

# compute the adjusted pair differences
ri_data_fi <- ri_data_fi %>%
  mutate(data_adjusted_pair_difference = map2(data_difference, effect, ~ adjusted_pair_difference_function(.x, .y)))

# compute the observed mean of adjusted pair differences
ri_data_fi <- ri_data_fi %>%
  mutate(observed_mean_difference = map(data_adjusted_pair_difference, ~ mean(.))) %>%
  unnest(cols = c(observed_mean_difference)) %>%
  select(-data_difference) %>%
  ungroup()

# define number of pairs in the experiment
number_pairs <- nrow(data_matched)/2

# define number of simulations
number_simulations <- 100000

# set seed
set.seed(42)

# compute the permutations matrix
permutations_matrix <- matrix(rbinom(number_pairs*number_simulations, 1,.5)*2-1, nrow = number_pairs, ncol = number_simulations)

# randomization distribution function
# this function takes the vector of pair differences
# and then compute the average pair difference according 
# to the permuted treatment assignment
function_randomization_distribution <- function(data_difference) {
  randomization_distribution = NULL
  n_columns = dim(permutations_matrix)[2]
  for (i in 1:n_columns) {
    randomization_distribution[i] =  sum(data_difference * permutations_matrix[, i]) / number_pairs
  }
  return(randomization_distribution)
}

# compute the test statistic distribution
ri_data_fi <- ri_data_fi %>%
  mutate(randomization_distribution = map(data_adjusted_pair_difference, ~ function_randomization_distribution(.)))

# define the p-values functions
function_fisher_upper_p_value <- function(observed_mean_difference, randomization_distribution){
  sum(randomization_distribution >= observed_mean_difference)/number_simulations
}

function_fisher_lower_p_value <- function(observed_mean_difference, randomization_distribution){
  sum(randomization_distribution <= observed_mean_difference)/number_simulations
}

# compute the lower and upper one-sided p-values
ri_data_fi <- ri_data_fi %>%
  mutate(p_value_upper = map2_dbl(observed_mean_difference, randomization_distribution, ~ function_fisher_upper_p_value(.x, .y)),
         p_value_lower = map2_dbl(observed_mean_difference, randomization_distribution, ~ function_fisher_lower_p_value(.x, .y)))

# retrieve the constant effects with the p-values equal or the closest to 0.025
ri_data_fi <- ri_data_fi %>%
  mutate(p_value_upper = abs(p_value_upper - 0.025),
         p_value_lower = abs(p_value_lower - 0.025)) %>%
  group_by(pollutant, time) %>%
  filter(p_value_upper == min(p_value_upper) | p_value_lower == min(p_value_lower)) %>%
  # in case two effect sizes have a p-value equal to 0.025, we take the effect size
  # that make the Fisherian interval wider to be conservative
  summarise(lower_fi = min(effect),
            upper_fi = max(effect))

# compute observed average of pair differences
ri_data_fi_point_estimate <- data_pair_difference_pollutant   %>%
  select(pollutant, time, difference) %>%
  group_by(pollutant, time) %>%
  summarise(observed_mean_difference = mean(difference)) %>%
  ungroup()

# merge ri_data_fi_point_estimate with ri_data_fi
ri_data_fi_final <- left_join(ri_data_fi, ri_data_fi_point_estimate, by = c("pollutant", "time"))

# save the data
saveRDS(ri_data_fi_final, "~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/1.experiment_entry_cruise/ri_data_fisherian_intervals.rds")


