using CSV
using HTTP
using GraphDataFrameBridge
using DataFrames
using LightGraphs
using MetaGraphs
#crée un dataframe à partir des données tabulaires de l'année.
data = CSV.File(HTTP.get("http://localhost:8984/xpr/data/1726").body, header=1) |> DataFrame
#création d'un vecteur contenant les noms des experts à partir de la colone label du dataframe
expertNodes = data[!, :label]
#nb d'experts
numExperts = length(expertNodes)
#création d'un vecteur contenant les noms des catégories d'expertise à partir du nom des colonnes du dataframe
catNodes = names(select(data, Not(:label)))
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
nodelabel = Vector()
for i in sort(collect(keys(bigraph.vprops)))
    push!(nodelabel, string(bigraph.vprops[i][:label]))
end
gplot(bigraph, nodelabel=nodelabel, layout=circular_layout)
