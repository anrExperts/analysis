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
data = CSV.File(HTTP.get("http://localhost:8984/xpr/networks/1726/categories").body, header=1) |> DataFrame
#création d'un vecteur contenant les noms des experts à partir de la colone label du dataframe
expertNodes = data[!, :label]
#nb d'experts
numExperts = length(expertNodes)
#création d'un vecteur contenant les noms des catégories d'expertise à partir du nom des colonnes du dataframe
catNodes = names(select(data, Not([:label, :colonne])))
#nb de catégories
numCategories = length(catNodes)
#nb total de nœuds (experts + categories)
numNodes = numExperts + numCategories
#Création du Graph
bigraph = MetaGraph(SimpleGraph())
#création du nombre de nœuds total, ne nécessite pas de faire de boucle, ajoute autant de nœuds que le nb indiqué en arg2
add_vertices!(bigraph, numNodes)
# pour les n premiers nœuds correspondants aux experts => création des métadonnées liées
for expert in 1:numExperts
    set_prop!(bigraph, expert, :label, expertNodes[expert])
    set_prop!(bigraph, expert, :cat, "expert")
end

# control
bigraph.vprops
#Pour chaque nœuds catégories (positionnés après les nœuds expert et jusqu'à la fin) :
# - ajout un une propriété cat avec valeur category
# - avec l'incrémentation de pos, tourne sur le vecteur catégories pour récupérer les labels des nœuds.
#@todo fonctionnel mais faire plus propre !!!!
pos = 1
for category in (numExperts+1):numNodes
    for i in 1:numCategories
        set_prop!(bigraph, category, :label, catNodes[pos])
    end
    set_prop!(bigraph, category, :cat, "category")
    global pos += 1
end
# control
bigraph.vprops[50]
#ajout des edges
#tourne sur chaque catégorie, et pour chaque expert teste s'il a participé à au moins une expertise de ce type => si oui création de l'edge correspondante
#@todo faire plus propre (incrémentation des variables col et pos pour déterminer les experts et la catégories pour les edges)
col = 1
for column in catNodes
    print(col)
    pos = 1
    for expert in data[!, column]
        if data[!, column][pos] > 0
            add_edge!(bigraph, pos, col+numExperts)
        end
        global pos += 1
    end
    global col += 1
end
#control
collect(edges(bigraph))

#création d'un vecteur pour la couleur
nodecolor = Vector()
#pour chaque nœuds du graph, on vérifie son type pour mettre à jour le vecteur (valeur 1 ou 2 correspondant au position du vecteur color ci-après)
for i in sort(collect(keys(bigraph.vprops)))
    if bigraph.vprops[i][:cat] == "expert"
        push!(nodecolor, 1)
    else
        push!(nodecolor, 2)
    end
end
#vecteur couleur
color = [colorant"lightseagreen", colorant"orange"]
#creation du vecteur couleur (rgb)
nodefillc=color[nodecolor]

nodelabel = Vector()
for i in sort(collect(keys(bigraph.vprops)))
    push!(nodelabel, string(bigraph.vprops[i][:label]))
end

#taille des nœuds par degré
nodesize = [LightGraphs.outdegree(bigraph, v) for v in sort(collect(keys(bigraph.vprops)))]
#taille des nœuds experts par nombre d'affaires/type d'affaire (faire les deux boucles for qui suivent)
nodesize = Vector()
for expert in 1:numExperts
    value = 1
    for column in names(select(data, Not(:label)))
        global value += data[!, column][expert]*10
    end
    #set_prop!(bigraph, expert, :nodesize, value)
    push!(nodesize, value)
end
#ajout d'une valeur pour les nœuds catégories
for cat in catNodes
    push!(nodesize, 50)
end

#control
nodesize
bigraph.vprops
#control
is_bipartite(bigraph)
layout=(args...)->spring_layout(args...; C=30)
gplot(bigraph, nodelabel=nodelabel, nodefillc=nodefillc, nodesize=nodesize, layout=layout)
#création de la Matrice d'ajacence à partir de bigraph
BigraphMatrix = Matrix(adjacency_matrix(bigraph))
m = BigraphMatrix[1:numExperts, (numExperts+1):numNodes]
#matrice projetée de bigraph (catégories)
transpose(m)
mp = transpose(m) * m
#matrice transposée de bigraph (experts)
mt = m * transpose(m)

#Graph de la matrice projetée
gmp = Graph(mp)

#Graph de la matrice transposée
gmt = Graph(mt)

nodesizeGmt = [LightGraphs.outdegree(Graph(mt), v) for v in 1:46]

layout=(args...)->spring_layout(args...; C=30)
gplot(gmt, nodelabel=expertNodes,  layout=layout, nodesize=nodesizeGmt)
LightGraphs.degree(gmt)
bc =LightGraphs.betweenness_centrality(gmt)

df = DataFrame(Experts = expertNodes, bc = bc)
describe(df)
histogram(bc, nbins=46, xscale=log10)










data1 = data[:, Not([:colonne, :label])]

#replace values greater than 0 with 1
data1 .= ifelse.(data1 .> 0, 1, data1)

test = Matrix(data1)

sumTest = sum(test, dims=2)
toto = Vector()
for value in sumTest
    var = sqrt(value)
    push!(toto, var)
end

toto
toto .= ifelse.(toto .== 0.00, 1.00, toto)
sumTest/toto

df = DataFrame(a = rand(1:10, 3), b = rand(1:10, 3), c=rand(1:10, 3))
collect(eachrow(df))
dfn = DataFrame(0, 3) ## create a new dataframe with same number of columns
for r in eachrow(df)
    m = collect(r) ./ maximum(r)
    push!(dfn, m)
end
