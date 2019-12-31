#!/usr/bin/env Rscript
#author Amelia 
# last edit Dec 28 2019

`%>%`<-magrittr::`%>%`

ARGS <- commandArgs(TRUE)

EXPERIMENT_NAME <- ARGS[1] #"4each_zeroes" # 
DATA_INSTANCE   <- ARGS[2] #"dinst11_30subjs" # 
COEF_VAL        <- -.001 #ARGS[3] #

COEF_VALS <- c(COEF_VAL,0,-COEF_VAL)


MASTER_OUT_CSV <- paste0("2_validation/",
                         "master_dfs/",
                         "master_df_",
                         EXPERIMENT_NAME,
                         "_",
                         DATA_INSTANCE,
                         ".csv")


##################
#create master df#
##################
create_masterdf<-"2_validation/fn_create_masterdf_function_pos_neg.R"
source(create_masterdf)
master_df<- create_masterdf(vars=c("econ","glob","loc"),
                            coef_vals= COEF_VALS,
                            exp_name= EXPERIMENT_NAME,
                            data_inst= DATA_INSTANCE)
                            
readr::write_csv(master_df, path=MASTER_OUT_CSV)





