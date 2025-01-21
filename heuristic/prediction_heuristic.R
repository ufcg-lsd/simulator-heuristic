library(tidyverse)
library(tsibble)

#' Runs the simulation.
#'
#'@param demands data frame with start_date and num_instances columns
#'@param window prediction window in hours
#'@param ondemand_price on-demand hourly price
#'@param upfront_cost reserved instance upfront cost
#'@param hourly_cost_res reserved instance hourly cost
#'@param reserve_duration length of a reserved instance acquisition in hours
#'@param start index of simulation's start
#'@param end index of simulation's end 
#'@param prediction_list vector with all the predictions needed in simulation
#'@param short_future length of time slice for deciding if a reserve should be purchased now or latter 
run_simulation <- function(demands, window, ondemand_price, upfront_cost, hourly_cos_res, reserve_duration, start, end, prediction_list, short_future){
  heuristic_data <- as_tsibble(demands, index = start_date)[1:end, ]
  results <- aug_heuristic(heuristic_data, window, ondemand_price, upfront_cost, hourly_cos_res, reserve_duration, start, prediction_list, short_future)
  
  work_data <- as_tsibble(demands, index = start_date)[start:end, ]
  work_data$reserves <- results$reserves[start:end]
  work_data$ondemand <- results$ondemand[start:end]
  work_data$cost <- work_data$reserves * hourly_cost_res + work_data$ondemand * ondemand_price
  work_data$cost <- cumsum(work_data$cost)
  
  return(work_data)
  
}


#' Runs the predictive heuristic
#'
#' @param demands data frame with start_date and num_instances columns
#' @param window prediction window in hours
#' @param start index of simulation start
#' @param prediction_list vector with all simulation's predictions
#' @param short_future time slice of profitability veriction
aug_heuristic <- function(demands, window, ondemand_price, upfront_cost, hourly_cos_res, reserve_duration, start, prediction_list, short_future){
  time_period <- length(demands$start_date)
  ondemand <- rep(0, time_period)
  p_reserves <- rep(0, time_period + reserve_duration)
  new_reserves <- rep(0, time_period)
  reserves <- rep(0, time_period + reserve_duration)
  
  
  reserve_price <- upfront_cost + hourly_cost_res * reserve_duration
  it_num <- 1
  pred_window <- 8760
  for (t in seq(start, time_period)){
    predict <- c(demands$num_instances[1:t],load_predicted(prediction_list, it_num, pred_window))
    it_num <- it_num + 1
    while(aug_online_reserve(t, demands, predict, p_reserves, window, ondemand_price, reserve_price, reserve_duration, short_future)){
      new_reserves[t] <- new_reserves[t] + 1
      
      #Adds a "Phantom" reservation in the past and an active in the future
      for(i in max(1, t - reserve_duration + window + 1):(t + reserve_duration - 1)){
        p_reserves[i] <- p_reserves[i] + 1
      }
      
      #Updates the active reservations in the future
      for (i in t:(t + reserve_duration - 1)) {
        reserves[i] <- reserves[i] + 1
      }
    }
    ondemand[t] <- demands$num_instances[t] - p_reserves[t]
    if (ondemand[t] < 0) {
      ondemand[t] <- 0
    }
  }
  return(list("new_reserves" = new_reserves, "reserves" = reserves, "ondemand" = ondemand))
}

aug_online_reserve <- function(present,demands, predict, p_reserves, window, ondemand_price, reserve_price, reserve_duration, short_future){
  ondemand_hours <- 0
  # Verifica do passado até o presente
  for (i in seq(max(1, present + window - reserve_duration + 1),present)){
    if (demands$num_instances[i] > p_reserves[i]){
      ondemand_hours <- ondemand_hours + 1
    }
  }
  
  #Verifica do presente até o futuro
  for(i in seq(present + 1, min(present + window, length(predict)))){
    if (predict[i] > p_reserves[i]){
      ondemand_hours <- ondemand_hours + 1
    } 
  }  
  
  return (ondemand_hours * ondemand_price >= reserve_price && p_reserves[present] < demands$num_instances[present] && advisor(present, p_reserves, predict, ondemand_price, hourly_cost_res, short_future))
}


#' load prediction vector
#'
#'@param predicted_list vector with all simulation's predictions
#'@param window length of each prediction
load_predicted <- function(predicted_list, iteration_num, window){
  start <- window * (iteration_num - 1) + 1
  end <- window * iteration_num
  return (predicted_list[start:end])
}


#' profitability verification
#'
#' Verifies if a new reservation is profitable in a short future
#' @param present index
#' @param p_reserves vector with the future active reservations
#' @param demands prediction vector with future demands
#' @param short_future time slice window for profitability verification
#' 
#' @return true if acquiring a new reserve is profitable
advisor <- function(present, p_reserves, demands, ondemand_price, hourly_cost_res, short_future){
  current_cost <- 0
  for(i in seq(present, min(present + short_future, length(demands)))){
    ondemand_instances = demands[i] - p_reserves[i]
    if (ondemand_instances < 0){
      ondemand_instances = 0
    }
    current_cost <- current_cost + (p_reserves[i] * hourly_cost_res) + (ondemand_instances * ondemand_price) 
  }
  
  post_reserve_cost <- 0
  for(i in seq(present, min(present + short_future, length(demands)))){
    ondemand_instances = demands[i] - p_reserves[i] - 1
    if (ondemand_instances < 0){
      ondemand_instances = 0
    }
    post_reserve_cost <- post_reserve_cost + ((p_reserves[i] + 1) * hourly_cost_res) + (ondemand_instances * ondemand_price) 
  }
  
  return (post_reserve_cost <= current_cost)
  
}


