#' initializes master dataframe to be used to create datasets and standats in
#' next script. 
#' 
#'@param vars vector of strings of names of each variable
#'@param coef_vals vector of numeric values to be used as coefficients for 
#'         each variable 
#'@param exp_name a string, the name of the experiment that this sampled 
#'data comes from
#'
#'@param data_inst a string, the name of the data sampled (can be iterated 
#'if you sample more than one version of the same data)

#'@return data frame 
#' 
#' 
#'
#'

create_masterdf <- function(vars,coef_vals,exp_name,data_inst) {
  #check that function inputs are of correct type
  if (!is.vector(vars)) {
    stop("vars must be a list")
  }
  if (!is.vector(coef_vals)) {
    stop("coef_vals must be a list")
  }

  
  
  df<-expand.grid(coef_vals,coef_vals,coef_vals)
  x <- c("d_coef_econ","d_coef_loc", "d_coef_glob")
  colnames(df) <- x

    
  #expand by the list of all the models 
  model_list<-as.data.frame(c("Econ+Glob+Loc",
                              "Econ+Glob",
                              "Econ+Loc",
                              "Glob+Loc",
                              "Econ",
                              "Glob",
                              "Loc",
                              ""))
  
  df_mods<-reshape::expand.grid.df(model_list,df)
  names(df_mods)[1]<- 'm_pos_vars'

  #add column for data instance 
  df_mods$d_id<-rep_len(data_inst, nrow(df_mods))
  
  #add column for experiment 
  df_mods$d_experiment<-rep_len(exp_name, nrow(df_mods))
  
  df_mods$m_neg_vars<-
    dplyr::case_when(
      df_mods$m_pos_vars =="Econ+Glob+Loc" ~  "",
      df_mods$m_pos_vars =="Econ+Glob"~"Loc",
      df_mods$m_pos_vars =="Econ+Loc"~ "Glob",
      df_mods$m_pos_vars =="Glob+Loc"~ "Econ",
      df_mods$m_pos_vars =="Econ"~"Glob+Loc",
      df_mods$m_pos_vars =="Glob"~"Econ+Loc",
      df_mods$m_pos_vars =="Loc"~"Econ+Glob",
      df_mods$m_pos_vars ==""~ "Econ+Glob+Loc")

  
data_pos_vars<-
    dplyr::case_when(
      df_mods$d_coef_econ>0 & df_mods$d_coef_glob>0 & df_mods$d_coef_loc>0 ~ "Econ+Glob+Loc",
      df_mods$d_coef_econ>0 & df_mods$d_coef_glob>0 & df_mods$d_coef_loc<=0 ~ "Econ+Glob",
      df_mods$d_coef_econ>0 & df_mods$d_coef_glob<=0 & df_mods$d_coef_loc>0 ~ "Econ+Loc",
      df_mods$d_coef_econ<=0 & df_mods$d_coef_glob>0 & df_mods$d_coef_loc>0 ~  "Glob+Loc",
      df_mods$d_coef_econ>0 & df_mods$d_coef_glob<=0 & df_mods$d_coef_loc<=0 ~  "Econ",
      df_mods$d_coef_econ<=0 & df_mods$d_coef_glob>0 & df_mods$d_coef_loc<=0 ~ "Glob",
      df_mods$d_coef_econ<=0 & df_mods$d_coef_glob<=0 & df_mods$d_coef_loc>0 ~ "Loc",
      df_mods$d_coef_econ<=0 & df_mods$d_coef_glob<=0 & df_mods$d_coef_loc<=0 ~  "")
  
  
  #add a model correct column
  df_mods$is_correct_model<-dplyr::case_when(df_mods$m_pos_vars == data_pos_vars~ "TRUE",
                                       df_mods$m_pos_vars != data_pos_vars~"FALSE"
                                       )

  #add a stan file column
  df_mods$m_stanfile<-dplyr::case_when(df_mods$m_pos_vars==""~ "stan_models/master_neg.stan",
                                     df_mods$m_pos_vars=="Econ+Glob+Loc"~ "stan_models/master_pos.stan",
                                     df_mods$m_pos_vars!="Econ+Glob+Loc"& df_mods$m_pos_vars!=""~"stan_models/master_model.stan"
                                     )

# create csv name 
   df_mods$csv_filename<-paste0(EXPERIMENT_NAME,"/",
                                DATA_INSTANCE,"/",
                                "econ_",df_mods$d_coef_econ,
                                "_loc_",df_mods$d_coef_loc,
                                "_glob_",df_mods$d_coef_glob,
                                ".csv"
                               )
  
 #add seed column 
 df_mods$seed<-runif(nrow(df_mods),min = 1, max =10000)
 

 
return(df_mods) 
}
