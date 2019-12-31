#!/usr/bin/env Rscript
#author Amelia ameliak@bu.edu
#last edit Dec 28 2019


ARGS <- commandArgs(TRUE)

ZERO_FOLDER <- ARGS[1] # "2_validation/model_fits_rds/4each_zeroes" # 
POS_FOLDER  <- ARGS[2] # "2_validation/model_fits_rds/4each_144"   # 
PAIRS_FILE  <- ARGS[3] # "2_validation/pairs_for_bf.csv" # 
OUT_FILE    <- ARGS[4] # "bayes_factors.csv"
  
pairs_df <- readr::read_csv(PAIRS_FILE) 

list_pos_mods <- list.files(POS_FOLDER)
list_zero_mods <-list.files(ZERO_FOLDER)


pairs_df$bf <- NA 

for (i in (1:nrow(pairs_df))) {
  
  pos_mod_name <-  pairs_df$pos_mod[i]
  zero_mod_name <- pairs_df$zero_mod[i]
    
   if (pos_mod_name %in% (list_pos_mods) & (zero_mod_name %in% list_zero_mods)) {
     
     pos_mod  <- readRDS(paste0(POS_FOLDER,"/",pos_mod_name))
     zero_mod <- readRDS(paste0(ZERO_FOLDER,"/",zero_mod_name))
     bfactor <- brms::bayes_factor(pos_mod,zero_mod) 
  
     pairs_df$bf[i] <- bfactor$bf

  }
  
  
  else{
    pairs_df$bf[i] <- NA
  }
  
}

readr::write_csv(pairs_df, OUT_FILE)



