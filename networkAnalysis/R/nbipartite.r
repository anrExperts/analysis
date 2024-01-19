library(igraph)
library(Matrix)
library(tidyr)
library(dplyr)

## globalVar
year <- "1726"
networksUri <- "https://experts.huma-num.fr/xpr/networks/"
dataUri <- "https://experts.huma-num.fr/xpr/data/"

## function 
source("/Volumes/data/github/analysis/R/assortativity_remainin_weights.r")

## Networks & Data
expertisesNetwork <- read.csv2(paste(networksUri,year,"/expertises", sep=""), header=TRUE, sep = ",") 
categoriesNetwork <- read.csv2(paste(networksUri,year,"/categories", sep=""), header=TRUE, sep = ",")
expertsData <- read.csv2(paste(dataUri,year,"/experts", sep=""), header=TRUE, sep = ",") 
expertsData <- expertsData %>%
  mutate(C = if_else(column=="architecte", 1, 2))
expertisesData <- read.csv2(paste(dataUri,year,"/expertises", sep=""), header=TRUE, sep = ",")
totalNodes = nrow(expertsData)+nrow(expertisesData)

## normalization 
nExpertisesNetwork <- as.matrix(expertisesNetwork[, -1])
nExpertisesNetwork <- nExpertisesNetwork/sqrt(rowSums(nExpertisesNetwork))
nExpertisesNetwork[is.nan(nExpertisesNetwork)] <- 0
#nExpertisesNetwork <- apply(nExpertisesNetwork, 2, function(i) i/sqrt(sum(i)))
rownames(nExpertisesNetwork) <- expertsData[, c("name")]

nWeight <- NULL
nList <- NULL
for (i in 1:nrow(nExpertisesNetwork) ){
  for (j in 1:ncol(nExpertisesNetwork)) {
    if(nExpertisesNetwork[i,j] > 0) {
      nWeight <- c(nWeight, nExpertisesNetwork[i,j])
      nList <- c(nList, rownames(nExpertisesNetwork)[i])
      nList <- c(nList, colnames(nExpertisesNetwork)[j])
    }
  }
}
nEdgesList <- as.matrix(data.frame(nList))

## make bipartite graph, & add vertices & attributes
nExpertisesGraph <- make_empty_graph(directed = FALSE) %>%
  add_vertices(nrow(expertsData) + nrow(expertisesData), attr = list())%>%
  set_vertex_attr("id", index=1:nrow(expertsData), value=expertsData[, c("id")])%>%
  set_vertex_attr("label", index=1:nrow(expertsData), value=expertsData[, c("name")])%>%
  set_vertex_attr("type", index=1:nrow(expertsData), value=FALSE)%>%
  set_vertex_attr("name", index=1:nrow(expertsData), value=expertsData[, c("name")])%>%
  set_vertex_attr("column", index=1:nrow(expertsData), value=expertsData[, c("column")])%>%
  
  set_vertex_attr("id", index=nrow(expertsData)+1:nrow(expertisesData), value=expertisesData[, c("id")])%>%
  set_vertex_attr("name", index=nrow(expertsData)+1:nrow(expertisesData), value=expertisesData[, c("id")])%>%
  set_vertex_attr("label", index=nrow(expertsData)+1:nrow(expertisesData), value=expertisesData[, c("id")])%>%
  set_vertex_attr("type", index=nrow(expertsData)+1:nrow(expertisesData), value=TRUE)%>%
  
  add_edges(nEdgesList)%>%
  set_edge_attr("weight", value=nWeight)

plot(nExpertisesGraph, layout=layout.bipartite, vertex.label=NA)

## projections of two one-mode graphs from bipartite Graph
nProj <- bipartite_projection(nExpertisesGraph)
nProjMatrix <- get.adjacency(nProj$proj1)

nExpertsGraph <- graph_from_adjacency_matrix(nProjMatrix, mode = "undirected") %>%
  set_vertex_attr("column", index=1:nrow(expertsData), value=expertsData[, c("C")])


## normalized one-mode projection Graph from scratch
transpose <- t(nExpertisesNetwork)
nExpertsMatrix <- nExpertisesNetwork %*% transpose
nExpertsMatrix[is.na(nExpertsMatrix)] = 0
nExpertsMatrix[nExpertsMatrix > 0.9999] <- 0

nExpertsWeight <- NULL
for (i in 1:nrow(nExpertsMatrix) ){
  for (j in 1:ncol(nExpertsMatrix)) {
    if(nExpertsMatrix[i,j] != 0) {
      nExpertsWeight <- c(nExpertsWeight, nExpertsMatrix[i,j])
    }
  }
}

nExpertsGraph <- graph_from_adjacency_matrix(nExpertsMatrix, weighted=TRUE, mode="max") %>%
  set_vertex_attr("label", index=1:nrow(expertsData), value=expertsData[, c("name")])%>%
  set_vertex_attr("type", index=1:nrow(expertsData), value=FALSE)%>%
  set_vertex_attr("name", index=1:nrow(expertsData), value=expertsData[, c("name")])%>%
  set_vertex_attr("column", index=1:nrow(expertsData), value=expertsData[, c("C")])


E(nExpertsGraph)$weight
E(nExpertsGraph)[1]$weight
# assign edge's width as a function of weights.
E(nExpertsGraph)$width <- sqrt(E(nExpertsGraph)$weight)
plot(nExpertsGraph)

degree(nExpertsGraph)
strength(nExpertsGraph)

nAssortNominal <- assortativity.nominal(nExpertsGraph, types=V(nExpertsGraph)$column)
nAssort <- assortativity(nExpertsGraph, types1=V(nExpertsGraph)$column)
nAssortDegree <- assortativity_degree(nExpertsGraph)
#assortativity(nExpertsGraph, types1 = graph.strength(nExpertsGraph), directed = F)
#assortativity.weightEdge(nExpertsGraph)
nAssortRemainingWeights <- assortativity.remainingWeights(nExpertsGraph)
