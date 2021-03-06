#' @title Sample from a 2D Distribution Given FX(x) and F(y|X = x)
#'
#' @author Peter Reiker
#' @date 11/26/2018
#'
#' @description
#' Sample from a 2D Distribution Given FX(x) and F(y|X = x)
#' This function samples from a 2D distribution given the marginal pdf of X and the conditional pdf of Y given X = x.
#' Its output is in the form of a data frame where the elements are x and y samples from the specified 2D distribution.
#'
#' This function uses the rejection_sampling function.
#' Depending upon the sample size and complexity of the distribution, this function may run more than 1 minute.
#'
#' @param n is the number of samples to generate.
#' @param fx is the marginal pdf of X.
#' @param fyx is the conditional pdf of Y given X = x (it is in the form function(y,x) expression).
#'
#' @return my_samples is a data frame of x and y samples from the desired 2D distribution.
#' @export
#'
#' @examples
#' d2_sampler_special(2*10^3, function(x) {exp(-x^2/2)/sqrt(2*pi)}, function(y,x){exp(-y^2/2)/sqrt(2*pi)})
#' d2_sampler_special(2*10^3, function(x) {ifelse(x > 0, exp(-x), 0)}, function(y,x){ifelse(0 < y & y < x, 1/x, 0)})
#' d2_sampler_special(2*10^3, function(x) {ifelse(0.01 < x & x < 1.01, 1, 0)}, function(y,x){ifelse(0 < y, x*exp(-y*x), 0)})

d2_sampler_special <- function(n = 1, fx, fyx) {
  # Determine the values to be used with the rejection_sampling function (first time).
  a = -0.01
  b = 0.01

  while(integrate(fx, -Inf, a, stop.on.error = F)$value > 1/10^4) a = a - 0.1
  while(integrate(fx, b, Inf, stop.on.error = F)$value > 1/10^4) b = b + 0.1

  # Now find an approximate value for C (first time).
  C = fx(optimize(fx, c(a,b), maximum = T)$maximum)

  # Now use rejection sampling to find a vector of sample values of x.
  my_samplesx = rejection_sampling(n, fx, a, b, C)

  # Here I initialize this vector to all 0s to save runtime.
  my_samplesy = replicate(n,0)

  for (i in 1:n) {
      # Repeat the same process to find a sample from the conditional pdf of Y given X = x.
      fyx_given_x = function(y) fyx(y,my_samplesx[i])

      j = -0.01
      k = 0.01

      while(integrate(fyx_given_x, -Inf, j, stop.on.error = F)$value > 1/10^4) j = j - 0.1
      while(integrate(fyx_given_x, k, Inf, stop.on.error = F)$value > 1/10^4) k = k + 0.1

      D = fyx_given_x(optimize(fyx_given_x, c(j,k), maximum = T)$maximum)

      y = rejection_sampling(1, fyx_given_x, j, k, D)

    my_samplesy[i] = y
  }

  my_samples = data.frame(x = my_samplesx, y = my_samplesy)

  return(my_samples)
}
