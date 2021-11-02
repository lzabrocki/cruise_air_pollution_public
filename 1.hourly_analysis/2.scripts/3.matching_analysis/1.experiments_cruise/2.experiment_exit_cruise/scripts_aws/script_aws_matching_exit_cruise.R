#--------------------------------------------------------------------

# SCRIPT: TIME SERIES MATCHING IN AWS FOR EXITING CRUISE EXPERIMENT

#--------------------------------------------------------------------

# load required packages
library(tidyverse) # for data manipulation and visualization
library(Rcpp) # for running the matching algorithm
library(optmatch) # for matching pairs
library(igraph) # for pair matching via bipartite maximal weighted matching

# load matching functions
source("~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/2.scripts/3.matching_analysis/0.script_matching_algorithm/script_time_series_matching_function.R")

# load data
data_all_years <- readRDS("~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/0.main_data/data_for_analysis_hourly.RDS")

#-------------------------------------------------------------

# SETTING UP THE DATA FOR MATCHING

#-------------------------------------------------------------

# select relevant variables
relevant_variables <- c(
  # date variable
  "date", 
  # air pollutants variables
  "mean_no2_l", "mean_no2_sl", "mean_pm10_l", "mean_pm10_sl", "mean_pm25_l", "mean_so2_l", "mean_o3_l",
  # total gross tonnage
  "total_gross_tonnage", "total_gross_tonnage_entry", "total_gross_tonnage_exit",
  "total_gross_tonnage_other_vessels", "total_gross_tonnage_cruise", "total_gross_tonnage_ferry",
  "total_gross_tonnage_entry_cruise", "total_gross_tonnage_entry_ferry", "total_gross_tonnage_entry_other_vessels",
  "total_gross_tonnage_exit_cruise", "total_gross_tonnage_exit_ferry", "total_gross_tonnage_exit_other_vessels",
  # weather factors
  "temperature_average", "rainfall_height_dummy", "humidity_average", "wind_speed", "wind_direction_categories", "wind_direction_east_west",
  # road traffic flow
  "road_traffic_flow",
  # calendar data
  "hour", "day_index", "weekday", "holidays_dummy", "bank_day_dummy", "month", "year")

# create processed_data with the relevant variables
if (exists("relevant_variables") && !is.null(relevant_variables)){
  # extract relevant variables (if specified)
  processed_data = data_all_years[relevant_variables]
} else {
  processed_data = data_all_years
}


#-----------------------------------------------------------------------------------------------------------

# CREATING LAGS AND LEAGS 

#-----------------------------------------------------------------------------------------------------------

# we first define processed_data_leads and processed_data_lags
# to store leads and lags

processed_data_leads <- processed_data
processed_data_lags <- processed_data

#
# create leads
# 

# create a list to store dataframe of leads
leads_list <- vector(mode = "list", length = 3)
names(leads_list) <- c(1:3) 

# create the leads
for(i in 1:3){
  leads_list[[i]] <- processed_data_leads %>%
    mutate_at(vars(-date), ~  lead(., n = i, order_by = date)) %>%
    rename_at(vars(-date),function(x) paste0(x,"_lead_", i))
}

# merge the dataframes of leads
data_leads <- leads_list %>%
  reduce(left_join, by = "date")

# merge the leads with the processed_data_leads
processed_data_leads <- left_join(processed_data_leads, data_leads, by = "date") %>%
  select(-c(mean_no2_l:year))

#
# create lags
# 

# create a list to store dataframe of lags
lags_list <- vector(mode = "list", length = 3)
names(lags_list) <- c(1:3) 

# create the lags
for(i in 1:3){
  lags_list[[i]] <- processed_data_lags %>%
    mutate_at(vars(-date), ~  lag(., n = i, order_by = date)) %>%
    rename_at(vars(-date),function(x) paste0(x,"_lag_", i))
}

# merge the dataframes of lags
data_lags <- lags_list %>%
  reduce(left_join, by = "date")

# merge the lags with the initial processed_data_lags
processed_data_lags <- left_join(processed_data_lags, data_lags, by = "date")

#
# merge processed_data_leads with processed_data_lags
#

processed_data <- left_join(processed_data_lags, processed_data_leads, by = "date")

#-----------------------------------------------------------------------------

# DEFINING TREATMENT ASSIGNMENT

#-----------------------------------------------------------------------------

# construct treatment assigment variable
processed_data <- processed_data %>% 
  mutate(is_treated = NA) %>%
  # the hour is defined as treated if there was positive cruise traffic in t
  mutate(is_treated = ifelse(total_gross_tonnage_exit_cruise > 0, TRUE, is_treated)) %>% 
  # the hour is defined as treated if there was no cruise traffic in t
  mutate(is_treated = ifelse(total_gross_tonnage_exit_cruise == 0, FALSE, is_treated))

# remove the hours for which assignment is undefined
matching_data_all_years = processed_data[!is.na(processed_data$is_treated),]

# susbet treated and control units
treated_units = subset(matching_data_all_years,is_treated)
control_units = subset(matching_data_all_years,!is_treated)
N_treated = nrow(treated_units) # gives the total number of treated units for all years
N_control = nrow(control_units) # gives the total number of control units for all years

#---------------------------------------------------------------------------

# DEFINING THRESHOLDS

#---------------------------------------------------------------------------

# we create the scaling list as it is needed for running the algorithm
# but we do not use it

scaling =  rep(list(1),ncol(matching_data_all_years))
names(scaling) = colnames(matching_data_all_years)

# instead, we manually defined the threshold for each covariate
thresholds = rep(list(Inf),ncol(matching_data_all_years))
names(thresholds) = colnames(matching_data_all_years)

# threshold for hour
thresholds$hour = 0
thresholds$hour_lag_1 = 0
thresholds$hour_lag_2 = 0

# threshold for weekday
thresholds$weekday = 0
thresholds$weekday_lag_1 = 0
thresholds$weekday_lag_2 = 0

# threshold for holidays
thresholds$holidays_dummy = 0
thresholds$holidays_dummy_lag_1 = 0
thresholds$holidays_dummy_lag_2 = 0

# threshold for bank days
thresholds$bank_day_dummy = 0
thresholds$bank_day_dummy_lag_1 = 0
thresholds$bank_day_dummy_lag_2 = 0

# threshold for distance in days (day_index variable)
thresholds$day_index = 30

# thresholds for rainfall dummy
thresholds$rainfall_height_dummy = 0
thresholdsrainfall_height_dummy_lag_1 = 0
thresholds$rainfall_height_dummy_lag_2 = 0

# thresholds for average humidity
thresholds$humidity_average = 9
thresholds$humidity_average_lag_1 = 9
thresholds$humidity_average_lag_2 = 9

# thresholds for temperature average
thresholds$temperature_average = 4
thresholds$temperature_average_lag_1 = 4
thresholds$temperature_average_lag_2 = 4

# thresholds for wind direction categories
thresholds$wind_direction_east_west = 0
thresholds$wind_direction_east_west_lag_1 = 0
thresholds$wind_direction_east_west_lag_2 = 0

# thresholds for wind speed
thresholds$wind_speed = 1.8
thresholds$wind_speed_lag_1 = 1.8
thresholds$wind_speed_lag_2 = 1.8

#--------------------------------------------------------------------------------

# RUNNING THE MATCHING PROCEDURE

#--------------------------------------------------------------------------------

# we run the matching procedure for each year on the amazon EC2 t3.2xlarge
# we cannot run the matching on the full dataset at once
# as the computation is too intensive

# running the loop

for (i in 2008:2018){
  # select relevant year
  matching_data <- matching_data_all_years %>%
    filter(year == i)
  
  # susbet treated and control units
  treated_units = subset(matching_data,is_treated)
  control_units = subset(matching_data,!is_treated)
  N_treated = nrow(treated_units)
  N_control = nrow(control_units)
  
  #-----------------------------------------------------------------------------------
  
  # COMPUTE DISCREPANCY MATRIX
  
  #-----------------------------------------------------------------------------------
  
  # first we compute the discrepancy matrix
  discrepancies = discrepancyMatrix(treated_units, control_units, thresholds, scaling)
  
  rownames(discrepancies) = format(matching_data$date[which(matching_data$is_treated)])
  colnames(discrepancies) = format(matching_data$date[which(!matching_data$is_treated)])
  rownames(matching_data) = matching_data$date
  
  #-----------------------------------------------------------------------------------
  
  # RUN MATCHING
  
  #-----------------------------------------------------------------------------------
  
  # run the fullmatch algorithm
  matched_groups = fullmatch(discrepancies, data = matching_data, remove.unmatchables = TRUE, max.controls = 1)
  
  # get list of matched  treated-control groups
  groups_labels = unique(matched_groups[!is.na(matched_groups)])
  groups_list = list()
  for (j in 1:length(groups_labels)){
    IDs = names(matched_groups)[(matched_groups==groups_labels[j])]
    groups_list[[j]] = as.Date(IDs[!is.na(IDs)])
  }
  
  #-----------------------------------------------------------------------------------
  
  # BIPARTITE GRAPH AND GET FINAL DATA
  
  #-----------------------------------------------------------------------------------
  
  # we build a bipartite graph with one layer of treated nodes, and another layer of control nodes.
  # the nodes are labeled by integers from 1 to (N_treated + N_control)
  # by convention, the first N_treated nodes correspond to the treated units, and the remaining N_control
  # nodes correspond to the control units.
  
  # build pseudo-adjacency matrix: edge if and only if match is admissible
  # NB: this matrix is rectangular so it is not per say the adjacendy matrix of the graph
  # (for this bipartite graph, the adjacency matrix had four blocks: the upper-left block of size
  # N_treated by N_treated filled with 0's, bottom-right block of size N_control by N_control filled with 0's,
  # top-right block of size N_treated by N_control corresponding to adj defined below, and bottom-left block
  # of size N_control by N_treated corresponding to the transpose of adj)
  adj = (discrepancies<Inf)
  
  # extract endpoints of edges
  edges_mat = which(adj,arr.ind = TRUE)
  
  # build weights, listed in the same order as the edges (we use a decreasing function x --> 1/(1+x) to
  # have weights inversely proportional to the discrepancies, since maximum.bipartite.matching
  # maximizes the total weight and we want to minimize the discrepancy)
  weights = 1/(1+sapply(1:nrow(edges_mat),function(j)discrepancies[edges_mat[j,1],edges_mat[j,2]]))
  
  # format list of edges (encoded as a vector resulting from concatenating the end points of each edge)
  # i.e c(edge1_endpoint1, edge1_endpoint2, edge2_endpoint1, edge2_endpoint1, edge3_endpoint1, etc...)
  edges_mat[,"col"] = edges_mat[,"col"] + N_treated
  edges_vector = c(t(edges_mat))
  
  # NB: by convention, the first N_treated nodes correspond to the treated units, and the remaining N_control
  # nodes correspond to the control units (hence the "+ N_treated" to shift the labels of the control nodes)
  
  # build the graph from the list of edges
  BG = make_bipartite_graph(c(rep(TRUE,N_treated),rep(FALSE,N_control)), edges = edges_vector)
  
  # find the maximal weighted matching
  MBM = maximum.bipartite.matching(BG,weights = weights)
  
  # list the dates of the matched pairs
  pairs_list = list()
  N_matched = 0
  for (j in 1:N_treated){
    if (!is.na(MBM$matching[j])){
      N_matched = N_matched + 1
      pairs_list[[N_matched]] = c(treated_units$date[j],control_units$date[MBM$matching[j]-N_treated])
    }
  }
  
  # transform the list of matched pairs to a dataframe
  matched_pairs <- enframe(pairs_list) %>%
    unnest(cols = "value") %>%
    rename(pair_number = name,
           date = value)
  
  # select the matched data for the analysis
  final_data <- left_join(matched_pairs, matching_data, by = "date")
  
  # save the data
  saveRDS(final_data, paste0(paste0("~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/temporary_matched_data_", i), ".RDS"))
}

#-----------------------------------------------------------------------------------------------------------

# COMBINING YEARLY DATA INTO A SINGLE FILE

#-----------------------------------------------------------------------------------------------------------

# list the names of the matched data for each year
matched_data_all_years <- list.files(path = "~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/",
                                     pattern = "temporary", 
                                     full.names = T) %>%
  map_df(~readRDS(.))

# recreate the pair ids
matched_data_all_years <- matched_data_all_years %>%
  mutate(pair_number = rep(1:(nrow(matched_data_all_years)/2), each=2))

# save the data
saveRDS(matched_data_all_years, "~/Dropbox/vessel_traffic_air_pollution_project/1.hourly_analysis/1.data/2.data_for_analysis/1.matched_data/1.experiments_cruise/2.experiment_exit_cruise/matched_data_exit_cruise.RDS")
