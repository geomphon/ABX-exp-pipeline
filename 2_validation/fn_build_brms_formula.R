#' build brms formula and priors
#' @param posvars a string or vector of strings, predictors to be truncated positive
#' @param negvars a string or vector of strings,predictors to be truncated negative
#' @param normvars a string or vector of strings, predictors to apply a not truncated N(0,10) prior 
#' @return form_prior  the formula and the prior 

build_brms_formula<- function(posvars,
                              negvars,
                              normvars) {
  
  
  if (!is.na(normvars) & !is.na(posvars) & !is.na(negvars)) {
    bform <-bf(as.formula("response_var ~ normvars + posvars + negvars"), nl = TRUE,
               lf(as.formula(paste0("normvars ~ ",normvars)), center = TRUE),
               lf(as.formula(paste0("posvars ~ 0 + ",posvars)), cmc = FALSE),
               lf(as.formula(paste0("negvars ~ 0 + ",negvars,"+ (1|subject) + (1|item)")), cmc = FALSE))
    
  } else if (is.na(normvars)) {
    bform <-bf(as.formula("response_var ~ posvars + negvars"), nl = TRUE,
               lf(as.formula(paste0("posvars ~ 0 + ",posvars)), cmc = FALSE),
               lf(as.formula(paste0("negvars ~ 0 + ",negvars,"+ (1|subject) + (1|item)")), cmc = FALSE))
    
  } else if (is.na(posvars)) {
    bform <-bf(as.formula("response_var ~ normvars + negvars"), nl = TRUE,
               lf(as.formula(paste0("normvars ~ ",normvars)), center = TRUE),
               lf(as.formula(paste0("negvars ~ 0 + ",negvars,"+ (1|subject) + (1|item)")), cmc = FALSE))
    
  } else if (is.na(negvars)) {
    bform <-bf(as.formula("response_var ~ normvars + posvars"), nl = TRUE,
               lf(as.formula(paste0("normvars ~ ",normvars)), center = TRUE),
               lf(as.formula(paste0("posvars ~ 0 + ",posvars, "+ (1|subject) + (1|item)")), cmc = FALSE))
  }
  
  return(bform)
  
}