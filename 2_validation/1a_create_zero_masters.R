#!/usr/bin/env Rscript
#author Amelia 
# last edit Dec 28 2019


`%>%` <- magrittr::`%>%`

ARGS <- commandArgs(TRUE)

MASTER_DF <- ARGS[1] #"2_validation/master_dfs/master_df_4each_144_dinst11_30subjs.csv"
EXPERIMENT <- ARGS[2] # 4each_zeroes
DATA_INSTANCE <- ARGS[3] # dinst11_30subjs

master <- readr::read_csv(MASTER_DF)

mastfilt<- dplyr::filter(master,m_neg_vars == "Econ+Glob+Loc")
mastfilt$m_neg_vars <-"zero_model"

OUT_FILENAME <- paste0("2_validation/",
                       "master_dfs",
                       "master_df_",
                       EXPERIMENT,
                       "_",
                       DATA_INSTANCE,
                       ".csv")

readr::write_csv(mastfilt,OUT_FILENAME)

