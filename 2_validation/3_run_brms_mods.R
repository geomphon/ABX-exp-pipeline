#!/usr/bin/env Rscript
#author Amelia ameliak@bu.edu
# last edit Dec 28 2019

ARGS <- commandArgs(TRUE)
EXPERIMENT <-  ARGS[1] #"4each_144" #
DATA_INST <- ARGS[2] #"dinst1_30subjs" #
SUB_FOLDER <-ARGS[3] #"2_validation/" #  
RDS_FOLDER <- ARGS[4] #"model_fits_rds/" #


BATCH_SIZE <- 4

library(brms)
library(doParallel)
#library(doMC)
options(cores=20) #ceiling number of cores to use total
options(mc.cores = 4)#cores per model (= should equal numb of chains) 
registerDoParallel(cores=4)

model_fns <-"2_validation/fn_model_comparison_functions.R"
source(model_fns)

source("2_validation/fn_build_brms_formula.R")
source("2_validation/fn_build_brms_priors.R")

master_df<-readr::read_csv(paste0(SUB_FOLDER,
                                  "master_df_",
                                  EXPERIMENT,
                                  "_",
                                  DATA_INST,
                                  ".csv"))

EXP_DATA_COMB <- paste0(EXPERIMENT,"_",DATA_INST)

brms_mods <- vector(mode = "list")

batch_starts <- seq(1, nrow(master_df) - 1, BATCH_SIZE)

filelist = list.files(paste(SUB_FOLDER,RDS_FOLDER,EXPERIMENT,sep="/"))


for (batch_start in batch_starts){
  
  foreach(i=batch_start:(batch_start+BATCH_SIZE)) %dopar% {
    
    filename = model_fit_filename(master_df[i,])
    
    out_file = paste0(SUB_FOLDER,
                      RDS_FOLDER,
                      EXPERIMENT,
                      "/",
                      model_fit_filename(master_df[i,]))
    
    
    if (!filename %in% filelist){
      formulanl <- build_brms_formula(posvars = master_df$m_pos_vars[i],
                                      normvars = "acoustic_distance",
                                      negvars = master_df$m_neg_vars[i])
        
      priornl <- build_brms_priors(posvars = master_df$m_pos_vars[i],
                                   normvars = "acoustic_distance",
                                   negvars = master_df$m_neg_vars[i])
        
      brms_data <- readr::read_csv(paste0(SUB_FOLDER,"sampled_data/",master_df$csv_filename[i]))
      
     # not_run <- TRUE # this is supposed to help restart when the program is stuck
      #while (not_run) { #but isntead it breaks the whole thing. 
     #   tryCatch({
          brms_mods[[i]] <- brms::brm(formulanl,
                                            data = brms_data,
                                            family = 'bernoulli',
                                            prior = priornl,
                                            chains = 4,
                                            cores = 4,
                                            save_all_pars = TRUE)
       #   not_run <- FALSE
        #  }, error=function(e) e)
      #}
      
      
      saveRDS(brms_mods[[i]],file=out_file)
      
    } else {
      print(paste(filename,"already exists, model skipped",sep=" "))
    }
  }
}

 
saved_brms_mod_list <-saveRDS(brms_mods, paste0("brms_mods_list_",EXP_DATA_COMB,".rds"))

