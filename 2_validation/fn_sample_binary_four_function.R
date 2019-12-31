#' Samples binary responses from a logistic regression model with a
#' given coefficient set to a given value.
#'
#' @param d A data frame
#' @param response_var The name of a column in `d` containing only 0 and 1
#' @param predictor_vars The name of four columns in `d`
#' @param coef_values The coefficient value to use for sampling
#' @param intercept a numeric. value of intercept
#' 
#' @return data frame identical to `d`, with `response_var` replaced with
#' values sampled from a logistic regression model fit to `d` that has 
#' `response_var`as the response variable and `predictor_vars` as the  
#' predictor variables, with the value of the coefficient for `predictor_vars` 
#' replaced with `coef_values`
#' 
#' 
sample_binary_four <- function(d, response_var, predictor_vars, coef_values,intercept) {
  if (!is.data.frame(d)) {
    stop("d is not a data frame")
  }
  if (!(response_var %in% names(d))) {
    stop(paste0("d must contain '", response_var, "' as a column"))
  }
  for (i in 1:3){
    if (!(predictor_vars[i] %in% names(d))) {
      stop(paste0("d must contain '", predictor_vars[i], "' as a column"))
    }
  }

  
  
  f <- paste(as.character(response_var),
             "~", 
             as.character(predictor_vars[1]),
             "+",
             as.character(predictor_vars[2]),
             "+",
             as.character(predictor_vars[3]),
             "+",
             as.character(predictor_vars[4]),
             sep="")
  

  #1.3592 on logit scale 
  
  m <- glm(formula(f), data=d, family="binomial", maxit = 100)
  m$coefficients["(Intercept)"]<- intercept
  m$coefficients[predictor_vars[1]] <- coef_values[1]
  m$coefficients[predictor_vars[2]] <- coef_values[2]
  m$coefficients[predictor_vars[3]] <- coef_values[3]
  m$coefficients[predictor_vars[4]] <- coef_values[4]
  
  pred_prob <- predict(m, type="response", newdata=d)
  for (i in 1:nrow(d)){
    d[[response_var]][i] <- sample(c(0,1), 1,
                                   prob=c((1-pred_prob[i]), pred_prob[i]))
  }
  return(d) 
}