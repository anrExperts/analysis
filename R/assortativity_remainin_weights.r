assortativity.remainingWeights <- function(g){
  linkedNodes <- data.frame(
    n1 = rep(NA, length(E(g))),
    n2 = rep(NA, length(E(g))),
    s1 = rep(NA, length(E(g))),
    s2 = rep(NA, length(E(g))),
    s1_remaining = rep(NA, length(E(g))),
    s2_remaining = rep(NA, length(E(g))),
    k_nn_1 = rep(NA, length(E(g))),
    k_nn_2 = rep(NA, length(E(g)))
  )
  
  # standard Newman 2002, http://arxiv.org/pdf/cond-mat/0205405v1.pdf
  # but usign the "remaining strengths"
  num1 = 0
  num2 = 0
  den1 = 0  
  
  #iterate over edges
  for (i in 1:length(E(g))){
    n1 = ends(g,E(g))[i,1]
    n2 = ends(g,E(g))[i,2]
    
    s1 = sum(g[n1,]) - g[n1,n2] # stregth of "remaining" connected nodes 
    s2 = sum(g[n2,]) - g[n1,n2] #   "
    
    linkedNodes$n1[i] <- n1
    linkedNodes$n2[i] <- n2
    linkedNodes$s1_remaining[i] <- s1
    linkedNodes$s2_remaining[i] <- s2
    
    num1 = num1 + s1 * s2
    num2 = num2 + s1 + s2
    den1 = den1 + (s1^2 + s2^2)
  }
  
  num1 = num1 / length(E(g))
  num2 = num2 / (length(E(g)) * 2)
  num2 = num2 * num2
  den1 = den1 / (length(E(g)) * 2)
  
  (num1-num2) / (den1-num2)
}
