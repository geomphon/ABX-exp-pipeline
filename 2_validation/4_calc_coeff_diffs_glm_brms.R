#!/usr/bin/env Rscript
#author Amelia ameliak@bu.edu
#last edit Dec 28 2019

ARGS <- commandArgs(TRUE)
EXPERIMENT <- ARGS[1] #"4each_144" #
DATA_INST  <- ARGS[2] #"dinst1_30subjs" #
SUB_FOLDER <- ARGS[3] #"2_validation/" #  
RDS_FOLDER <- ARGS[4] #"model_fits_rds/" #


EXP_DATA_COMB <- paste0(EXPERIMENT,"_",DATA_INST)


`%>%` <- magrittr::`%>%`


model_comps<-"fn_model_comparison_functions.R"
source(model_comps)


#####
#glm#
#####
      master_df <-readr::read_csv(paste0("master_dfs/",
                                         "master_df_",
                                         EXP_DATA_COMB,
                                         ".csv"))
      
      
      data_list <- vector(mode = "list")
      mod_list  <- vector(mode = "list")
      sum_list  <- vector(mode = "list")
      
      master_df$Econ_coef_glm <-NA
      master_df$Glob_coef_glm <-NA
      master_df$Loc_coef_glm <-NA
      master_df$ac_dist_coef_glm <-NA
      master_df$acoustic_distance <- -.1784 #value of acoustic distance in sampled data
      
      
      for (i in 1:nrow(master_df)) {
        data_list[[i]] <- readr::read_csv(paste0("sampled_data/",master_df$csv_filename[i]))

        mod_list[[i]] <- glm(response_var~Econ+Glob+Loc+acoustic_distance,
                             family=binomial(),
                             data = data_list[[i]])

        sum_list[[i]]<- summary(mod_list[[i]])

        master_df$Econ_coef_glm[i]<-sum_list[[i]]$coefficients[2] #Econ
        master_df$Glob_coef_glm[i]<-sum_list[[i]]$coefficients[3] #Glob
        master_df$Loc_coef_glm[i]<-sum_list[[i]]$coefficients[4] #Loc
        master_df$ac_dist_coef_glm[i]<-sum_list[[i]]$coefficients[5] #acoustic_distance
      }
      
      
      master_df<- 
          dplyr::mutate(master_df,Econ_glm_diff = Econ_coef_glm-d_coef_econ) %>%
          dplyr::mutate(.,Glob_glm_diff = Glob_coef_glm-d_coef_glob) %>%
          dplyr::mutate(.,Loc_glm_diff = Loc_coef_glm-d_coef_loc) %>%
          dplyr::mutate(.,ac_dist_diff = ac_dist_coef_glm-acoustic_distance)
      
      
      
brms_fixef <- vector(mode = "list")
brms_mods  <- vector(mode = "list")
econ_post  <- vector(mode="list")
glob_post  <- vector(mode="list")
loc_post   <- vector(mode="list")
beta_post  <- vector(mode="list")
      
master_df$intercept_brms_coef <-NA
master_df$Econ_brms_coef      <-NA
master_df$Glob_brms_coef      <-NA
master_df$Loc_brms_coef       <-NA
master_df$ac_dist_brms_coef   <-NA
master_df$econ_sd             <-NA
master_df$glob_sd             <-NA
master_df$loc_sd              <-NA
      
master_df$intercept_brms_rhat <-NA
master_df$Econ_brms_rhat      <-NA
master_df$Glob_brms_rhat      <-NA
master_df$Loc_brms_rhat       <-NA
master_df$ac_dist_brms_rhat   <-NA



for (i in 1:nrow(master_df)){
    brms_mods[[i]] <- readRDS(paste0("model_fits_rds/",
                                     EXPERIMENT,
                                     "/",
                                     model_fit_filename(master_df[i,])))
    
    brms_fixef[[i]] <- brms::fixef(brms_mods[[i]])

    master_df$intercept_brms_coef[i]  <- brms_fixef[[i]][grep("*Intercept",row.names(brms_fixef[[i]])),"Estimate"]
    master_df$ac_dist_brms_coef[i]    <- brms_fixef[[i]][grep("*acoustic_distance",row.names(brms_fixef[[i]])),"Estimate"]
    master_df$Econ_brms_coef[i]       <- brms_fixef[[i]][grep("*Econ",row.names(brms_fixef[[i]])),"Estimate"]
    master_df$Glob_brms_coef[i]       <- brms_fixef[[i]][grep("*Glob",row.names(brms_fixef[[i]])),"Estimate"]
    master_df$Loc_brms_coef[i]        <- brms_fixef[[i]][grep("*Loc",row.names(brms_fixef[[i]])),"Estimate"]
    
    
}

master_df<- 
  dplyr::mutate(master_df,Econ_brms_diff = Econ_brms_coef-d_coef_econ) %>%
  dplyr::mutate(.,Glob_brms_diff = Glob_brms_coef-d_coef_glob) %>%
  dplyr::mutate(.,Loc_brms_diff = Loc_brms_coef-d_coef_loc) %>%
  dplyr::mutate(.,ac_brms_diff = ac_dist_brms_coef-acoustic_distance)
    

readr::write_csv(master_df, paste0("final_master_",EXP_DATA_COMB,".csv"))




