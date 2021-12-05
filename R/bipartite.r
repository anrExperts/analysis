library(igraph)
library(Matrix)
library(tidyr)
library(dplyr)

## globalVar
year <- "1726"
networksUri <- "https://experts.huma-num.fr/xpr/networks/"
dataUri <- "https://experts.huma-num.fr/xpr/data/"

## Networks & Data
expertisesNetwork <- read.csv2(paste(networksUri,year,"/expertises", sep=""), header=TRUE, sep = ",") 
categoriesNetwork <- read.csv2(paste(networksUri,year,"/categories", sep=""), header=TRUE, sep = ",")
expertsData <- read.csv2(paste(dataUri,year,"/experts", sep=""), header=TRUE, sep = ",") 
## for assortativity Types must be integers starting from 1
expertsData <- expertsData %>%
  mutate(C = if_else(column=="architecte", 1, 2))
expertisesData <- read.csv2(paste(dataUri,year,"/expertises", sep=""), header=TRUE, sep = ",")
totalNodes = nrow(expertsData)+nrow(expertisesData)

## edges list from data
expertisesMatrix <- data.matrix(expertisesNetwork)
expertisesMatrix <- expertisesMatrix[,-1]
rownames(expertisesMatrix) <- expertsData[, c("name")]
#rownames(expertisesMatrix) <- 1:40
#colnames(expertisesMatrix) <- 41:506

from <- NULL
to <- NULL
weight <- NULL
list <- NULL
for (i in 1:nrow(expertisesMatrix) ){
  for (j in 1:ncol(expertisesMatrix)) {
    if(expertisesMatrix[i,j] == 1) {
      from <- c(from, rownames(expertisesMatrix)[i])
      to <- c(to, colnames(expertisesMatrix)[j])
      weight <- c(weight, expertisesMatrix[i,j])
      list <- c(list, rownames(expertisesMatrix)[i])
      list <- c(list, colnames(expertisesMatrix)[j])
    }
    
  }
}

edgesList <- as.matrix(data.frame(list))


## make graph, & add vertices & attributes
expertisesGraph <- make_empty_graph(directed = FALSE) %>%
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
  
  add_edges(edgesList)%>%
  set_edge_attr("weight", value=weight)

is_bipartite(expertisesGraph)
##test if the nodes of one mode are only connected to the nodes of the other mode
i <- which(V(expertisesGraph)$type[match(ends(expertisesGraph,1:ecount(expertisesGraph))[,1],V(expertisesGraph)$name)] == V(expertisesGraph)$type[match(ends(expertisesGraph,1:ecount(expertisesGraph))[,2],V(expertisesGraph)$name)])
ends(expertisesGraph, i)

## plotting
plot(expertisesGraph, layout=layout.bipartite, vertex.label=NA)

V(expertisesGraph)
V(expertisesGraph)[1]$name
V(expertisesGraph)$name
E(expertisesGraph)
E(expertisesGraph)[1]
E(expertisesGraph)[1]$weight

## projections of two one-mode graphs
proj <- bipartite_projection(expertisesGraph)

print(proj[[1]], g=TRUE, e=TRUE)
print(proj[[2]], g=TRUE, e=TRUE)
typeof(proj[[1]])
projMatrix <- get.adjacency(proj$proj1)

expertsGraph <- graph_from_adjacency_matrix(projMatrix, mode = "undirected") %>%
  set_vertex_attr("column", index=1:nrow(expertsData), value=expertsData[, c("C")])

plot(expertsGraph)
V(expertsGraph)$name

##test homophily
assortativity.nominal(expertsGraph, types=V(expertsGraph)$column)
assortativity_degree(expertsGraph)

degree(expertsGraph)
strength(expertsGraph)

assortativity.nominal(simplify(expertsGraph), types=V(expertsGraph)$column)
assortativity(expertsGraph, types1 = graph.strength(expertsGraph), directed = F)
assortativity_degree(expertsGraph)
assortativity.weightEdge(expertsGraph)
