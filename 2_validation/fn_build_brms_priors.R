#' build brms formula and priors
#' @param posvars a string or vector of strings, predictors to be truncated positive
#' @param negvars a string or vector of strings,predictors to be truncated negative
#' @param normvars a string or vector of strings, predictors to apply a not truncated N(0,10) prior 
#' @return form_prior  the formula and the prior 

build_brms_priors<- function(posvars,
                             negvars,
                             normvars) {
  
  form_prior <- list()
  
  if (!is.na(normvars) & !is.na(posvars) & !is.na(negvars)) {
    
    
    priornl <-prior(normal(0, 10), class = "b", nlpar = "normvars")+
      prior(normal(0, 10), lb = 0, class = "b", nlpar = "posvars")+
      prior(normal(0, 10), ub = 0, class = "b", nlpar = "negvars")
    
    
  } else if (is.na(normvars)) {

    priornl <-prior(normal(0, 10), lb = 0, class = "b", nlpar = "posvars")+
      prior(normal(0, 10), ub = 0, class = "b", nlpar = "negvars")
    
  } else if (is.na(posvars)) {
    
    priornl <-prior(normal(0, 10), class = "b", nlpar = "normvars")+
      prior(normal(0, 10), ub = 0, class = "b", nlpar = "negvars")
    
  } else if (is.na(negvars)) {

    priornl <-prior(normal(0, 10), class = "b", nlpar = "normvars")+
      prior(normal(0, 10), lb = 0, class = "b", nlpar = "posvars")
  }
  
  return(priornl)
}