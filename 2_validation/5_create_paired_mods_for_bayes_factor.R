#!/usr/bin/env Rscript
#author Amelia 
# last edit Dec 28 2019

`%>%` <- magrittr::`%>%`

ARGS <- commandArgs(TRUE)

POS_MASTER  <- ARGS[1] #"2_validation/master_dfs/master_df_4each_144_dinst11_30subjs.csv"
ZERO_MASTER <- ARGS[2] #
PAIR_FILE   <- ARGS[3] # ""paired_mods.csv"


model_functions <- source("2_validation/fn_model_comparison_functions.R")


pos_mast  <- readr::read_csv(POS_MASTER)
pos_mast$fit_name <-model_fit_filename(pos_mast)

zero_mast <- readr::read_csv(ZERO_MASTER)
zero_mast$fit_name <- model_fit_filename(zero_mast)

pairs_df <- dplyr::left_join(pos_mast,
                             zero_mast, 
                            by= c("d_coef_econ","d_coef_glob","d_coef_loc")) %>%
            dplyr::select(fit_name.x,fit_name.y, d_coef_econ, d_coef_glob,
                          d_coef_loc, m_pos_vars.x)

pairs_df<-as.data.frame(pairs_df)

colnames(pairs_df)<-c("pos_mod",
                      "zero_mod", 
                      "d_coef_econ",
                      "d_coef_glob",
                      "d_coef_loc",
                      "m_pos_vars")

readr::write_csv(pairs_df,PAIR_FILE)



