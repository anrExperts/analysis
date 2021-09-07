using CSV
using LinearAlgebra
using HTTP
using GraphDataFrameBridge
using DataFrames
using LightGraphs
using MetaGraphs
using GraphPlot
using Colors
using Statistics
using UnicodePlots

#crée un dataframe à partir des données tabulaires de l'année.
data = CSV.File(HTTP.get("http://localhost:8984/xpr/data/1726/expertises").body, header=1) |> DataFrame
data1 = CSV.File(HTTP.get("http://localhost:8984/xpr/data/1726").body, header=1) |> DataFrame
#création d'un vecteur contenant les noms des experts à partir de la colone label du dataframe
expertisesNodes = data[!, :label]
#nb d'experts
numExpertises = length(expertisesNodes)
#création d'un vecteur contenant les noms des catégories d'expertise à partir du nom des colonnes du dataframe
expertNames = data1[!, :label]
expertNodes = names(select(data, Not(:label)))
#nb de catégories
numExperts = length(expertNodes)
#nb total de nœuds (experts + categories)
numNodes = numExpertises + numExperts
#Création du Graph
expertisesGraph = MetaGraph(SimpleGraph())
#création du nombre de nœuds total, ne nécessite pas de faire de boucle, ajoute autant de nœuds que le nb indiqué en arg2
add_vertices!(expertisesGraph, numNodes)
# pour les n premiers nœuds correspondants aux experts => création des métadonnées liées
for expertise in 1:numExpertises
    set_prop!(expertisesGraph, expertise, :label, expertisesNodes[expertise])
    set_prop!(expertisesGraph, expertise, :cat, "expertise")
end
expertisesGraph.vprops
pos = 1
for expert in (numExpertises+1):numNodes
    for i in 1:numExperts
        set_prop!(expertisesGraph, expert, :label, expertNodes[pos])
    end
    set_prop!(expertisesGraph, expert, :cat, "Expert")
    global pos += 1
end

expertisesGraph.vprops[500]

col = 1
for column in expertNodes
    print(col)
    pos = 1
    for expertise in data[!, column]
        if data[!, column][pos] > 0
            add_edge!(expertisesGraph, pos, col+numExpertises)
        end
        global pos += 1
    end
    global col += 1
end
#control
collect(edges(expertisesGraph))
#création d'un vecteur pour la couleur
nodecolor = Vector()
#pour chaque nœuds du graph, on vérifie son type pour mettre à jour le vecteur (valeur 1 ou 2 correspondant au position du vecteur color ci-après)
for i in sort(collect(keys(expertisesGraph.vprops)))
    if expertisesGraph.vprops[i][:cat] == "Expert"
        push!(nodecolor, 1)
    else
        push!(nodecolor, 2)
    end
end
#vecteur couleur
color = [colorant"lightseagreen", colorant"orange"]
#creation du vecteur couleur (rgb)
nodefillc=color[nodecolor]
gplot(expertisesGraph, nodefillc=nodefillc, layout=layout)
ExpertiseMatrix = Matrix(adjacency_matrix(expertisesGraph))
m = ExpertiseMatrix[1:numExpertises, (numExpertises+1):numNodes]
mp = transpose(m) * m
mt = m * transpose(m)
gmp = Graph(mp)
nodesizeGmp = [LightGraphs.outdegree(Graph(gmp), v) for v in 1:numExperts]
layout=(args...)->spring_layout(args...; C=20)
gplot(gmp, nodelabel=expertNames, layout=layout, nodesize=nodesizeGmp)
bc =LightGraphs.betweenness_centrality(gmp)
df = DataFrame(Experts = expertNodes, bc = bc)
describe(df)
