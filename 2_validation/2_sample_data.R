#!/usr/bin/env Rscript
#author Amelia ameliak@bu.edu
# last edit Dec 28 2019

`%>%`<-magrittr::`%>%`

ARGS <- commandArgs(TRUE) 

DESIGN_FILENAME <- ARGS[1] # "2_validation/design_4each.csv"# 
DATA_SUB_FOLDER <- ARGS[2] #"2_validation/sampled_data"  # 
MASTER_DF       <- ARGS[3] # "2_validation/master_dfs/master_df_4each_zeroes_dinst_TEST.csv" #
NUM_SUBJS       = 30 # ARGS[4] # 


#####################################################
#create csv dataset with arbitrary response variable#
#####################################################
design_df <- readr::read_csv(DESIGN_FILENAME)

num_trials = nrow(design_df)

colnames(design_df)[colnames(design_df)=="mean_dist"] <- "acoustic_distance"
colnames(design_df)[colnames(design_df)=="stat_econ"] <- "Econ"
colnames(design_df)[colnames(design_df)=="stat_loc"] <- "Loc"
colnames(design_df)[colnames(design_df)=="stat_glob"] <- "Glob"

subjs<- c()
for (i in 1:NUM_SUBJS) {
  subjs[i] = paste("subject",i,sep = "_")
}

trials <- c()
for (i in 1:num_trials){
  trials[i] = paste("trial",i,sep = "_")
}

subs_trials <- expand.grid(trials,subjs)
names(subs_trials)<-c("subject","trial")


rep_design_df<- design_df %>% dplyr::slice(rep(dplyr::row_number(), NUM_SUBJS))

full_design <- dplyr::bind_cols(rep_design_df,subs_trials)

full_design$item <- NA

for (i in 1:nrow(full_design)) {
  full_design$item[i] <- paste(full_design$Phone_NOTENG[i],full_design$Phone_ENG[i],sep = "_")
}

full_design$item <- as.factor(full_design$item)

#the below are dummy values, but must be present for the sampler to work. 
full_design$response_var <- 1



######################
#sample response_variable and savecsv#
######################
master_df <- readr::read_csv(MASTER_DF)

sample_binary_four<-"2_validation/fn_sample_binary_four_function.R"
source(sample_binary_four)

coef_dist <- -.1784  #effect of acoustic distance. taken from pilot data 

corr_mods <-subset(master_df, master_df$is_correct_model=="TRUE")

uniq_filenames<-unique(master_df$csv_filename)

for (i in 1:nrow(corr_mods)){
  
  data_i <- sample_binary_four(d = full_design,
                               
                               response_var = "response_var",
                               predictor_vars = c("Econ",
                                                  "Glob",
                                                  "Loc",
                                                  "acoustic_distance"),
                               
                               coef_values = c(corr_mods$d_coef_econ[i],
                                               corr_mods$d_coef_glob[i],
                                               corr_mods$d_coef_loc[i],
                                               coef_dist),
                               
                               intercept = 1.3592
  )
  
  readr::write_csv(data_i,path = paste0(DATA_SUB_FOLDER,"/",uniq_filenames[i]))
}

