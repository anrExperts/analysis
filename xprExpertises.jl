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
using StatsBase
using Plots
using StatsPlots
using UnicodePlots
using GR
using MultivariateStats
using GraphIO
using EzXML
using RDatasets


#########################################################
# Données tabulaires brutes
#########################################################
# Année étudiée
year = 1726
# dataframe experts par expertises
expertisesNetwork = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/networks/$year/expertises").body, header=1) |> DataFrame

# dataframe experts par categories
categoriesNetwork = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/networks/$year/categories").body, header=1) |> DataFrame
# données sur les experts
# @ todo compléter dates avec les almanachs
expertsData = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/data/$year/experts").body, header=1) |> DataFrame

# données sur les expertises
expertisesData = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/data/$year/expertises").body, header=1) |> DataFrame

# données sur les catégories
categoriesData = DataFrame(id=names(categoriesNetwork[!, Not(:id)]), name=["Estimer la valeur des biens", "Décrire et évaluer les travaux à venir", "Recevoir et évaluer le travail réalisé", "Départager", "Enregistrer"])


# @todo mettre en évidence la répartition inégale des affaires entre experts

# Les données regroupe 468 d'affaires dépouillées qui représentent un nombre moyen d'affaires dans le dépouillement pour le début de la période étudiée.
# Nous avons 40 experts qui sont tirés du dépouillement des almanachs (année N + année N+1, les alamanchs étant préparé en aout de l'année précédente) et croisé avec les données prosopographiques trouvée par juliette, ainsi que les experts nommés dans les affaires. (1 pour 1726 Montbrouard)
# Une affaire peut avoir 1 à 3 experts (pour 1726)
nbExpertsByExpertises = sum.(eachcol(expertisesNetwork[!, Not(:id)]))
UnicodePlots.histogram(sum.(eachcol(expertisesNetwork[!, Not(:id)])), nbins=length(unique(nbExpertsByExpertises)))

nbExpertisesByExpert = sum.(eachrow(expertisesNetwork[!, Not(:id)]))
UnicodePlots.histogram(nbExpertisesByExpert, nbins=length(unique(nbExpertisesByExpert)))

insertcols!(expertsData, :n => nbExpertisesByExpert)
describe(expertsData)
archis = expertsData[expertsData[!, :column] .== "architecte", :]
describe(archis)
entrepreneurs = (expertsData[expertsData[!, :column] .== "entrepreneur", :])
describe(entrepreneurs)


# @todo ajouter les % et les écarts types et médiane
# met à jour expertData, ajout de la colone nbExpertises
expertsData[!, :nbExpertises] = nbExpertisesByExpert
# @todo sortir un histogramme (stacqed bar chart) avec pour chaque expert le type d'affaires dont il s'occupe + nb d'affaires

#########################################################
# création du métagraphe
#########################################################

# vecteur contenant les id des experts
experts = expertsData[!, :id]
# vecteur contenant les noms des experts
expertNames = expertsData[!, :surname]
# vecteur contenant la catégorie des experts
expertsColumns = expertsData[!, :column]
# nb d'experts
numExperts = length(experts)

# vecteur contenant les id expertises
expertises = expertisesData[!, :id]
# nb d'expertises
numExpertises = length(expertises)

#nb total de nœuds (experts + categories)
numNodes = numExpertises + numExperts

# création du Graph
expertisesGraph = MetaGraph(SimpleGraph())
# Création des nœuds
add_vertices!(expertisesGraph, numNodes)

# ajout des métadonnées pour les nœuds experts
for expert in 1:numExperts
    set_prop!(expertisesGraph, expert, :id, experts[expert])
    set_prop!(expertisesGraph, expert, :name, expertNames[expert])
    set_prop!(expertisesGraph, expert, :column, expertsColumns[expert])
    set_prop!(expertisesGraph, expert, :cat, "expert")
end

# ajout des métadonnées pour les nœuds expertises
pos = 1
for expertise in (numExperts+1):numNodes
    for i in 1:numExpertises
        set_prop!(expertisesGraph, expertise, :id, expertises[pos])
        set_prop!(expertisesGraph, expertise, :cat, "expertise")
    end
    global pos += 1
end

# ajout des edges
col = 1
for column in expertises
    pos = 1
    for expert in expertisesNetwork[!, column]
        if expertisesNetwork[!, column][pos] > 0
            add_edge!(expertisesGraph, pos, col+numExperts)
        end
        global pos += 1
    end
    global col += 1
end
#########################################################
# VIZ
#########################################################

# couleur des labels
nodelabelc = colorant"white"

# vecteur couleurs
color = [colorant"#FF4500", colorant"#19FFD1", colorant"#700DFF", colorant"#FFF819"]

nodecolor = Vector()
#pour chaque nœuds du graph, on vérifie son type pour mettre à jour le vecteur (valeur 1 ou 2 correspondant au position du vecteur color ci-après)
for i in sort(collect(keys(expertisesGraph.vprops)))
  if expertisesGraph.vprops[i][:cat] == "expert"
    if expertisesGraph.vprops[i][:column] == "architecte"
      push!(nodecolor, 1)
    elseif expertisesGraph.vprops[i][:column] == "entrepreneur"
      push!(nodecolor, 2)
    else
      push!(nodecolor, 3)
    end
  else
    push!(nodecolor, 4)
  end
end
 # creation du vecteur expert/couleur(rgb)
nodefillc=color[nodecolor]
layout=(args...)->spring_layout(args...; C=30)
gplot(expertisesGraph, nodefillc=nodefillc, layout=layout)

#########################################################
# Métagraph experts - categories
#########################################################
categories = names(select(categoriesNetwork, Not([:id])))
categoriesNames = categoriesData[!, :name]
#nb de catégories
numCategories = length(categories)
# création du Graph
categoriesGraph = MetaGraph(SimpleGraph())

# Création des nœuds
add_vertices!(categoriesGraph, (numExperts+numCategories))
# ajout des métadonnées pour les nœuds experts
for expert in 1:numExperts
    set_prop!(categoriesGraph, expert, :id, experts[expert])
    set_prop!(categoriesGraph, expert, :name, expertNames[expert])
    set_prop!(categoriesGraph, expert, :column, expertsColumns[expert])
    set_prop!(categoriesGraph, expert, :cat, "expert")
end

# ajout des métadonnées pour les nœuds categories
pos = 1
for category in (numExperts+1):(numExperts+numCategories)
    for i in 1:numCategories
        set_prop!(categoriesGraph, category, :id, categories[pos])
        set_prop!(categoriesGraph, category, :name, categoriesNames[pos])
        set_prop!(categoriesGraph, category, :cat, "category")
    end
    global pos += 1
end

# ajout des edges
col = 1
for column in categories
    pos = 1
    for expert in categoriesNetwork[!, column]
        if categoriesNetwork[!, column][pos] > 0
            add_edge!(categoriesGraph, pos, col+numExperts)
        end
        global pos += 1
    end
    global col += 1
end

nodecolorCatGraph = Vector()
#pour chaque nœuds du graph, on vérifie son type pour mettre à jour le vecteur (valeur 1 ou 2 correspondant au position du vecteur color ci-après)
for i in sort(collect(keys(categoriesGraph.vprops)))
  if categoriesGraph.vprops[i][:cat] == "expert"
    if categoriesGraph.vprops[i][:column] == "architecte"
      push!(nodecolorCatGraph, 1)
    elseif categoriesGraph.vprops[i][:column] == "entrepreneur"
      push!(nodecolorCatGraph, 2)
    else
      push!(nodecolorCatGraph, 3)
    end
  else
    push!(nodecolorCatGraph, 4)
  end
end

nodelabelCatGraph = Vector()
for name in 1:(numExperts+numCategories)
    push!(nodelabelCatGraph, categoriesGraph.vprops[name][:name])
end

 # creation du vecteur expert/couleur(rgb)
nodefillcCatGraph=color[nodecolorCatGraph]
layout=(args...)->spring_layout(args...; C=20)
# @todo faire un parallel coordinates networks
gplot(categoriesGraph, nodelabel=nodelabelCatGraph, nodelabelc=nodelabelc, nodelabeldist=3.5, nodelabelangleoffset=π/2, nodefillc=nodefillcCatGraph, layout=layout)

# il semble a priori que les architectes et les entrepreneurs participent à tous les types d'affaires
expertsData = innerjoin(expertsData, categoriesNetwork, on=:id)
# afficher les statistiques de base sur la répartiton des affaires.
categoriesStats = describe(select(expertsData, :nbExpertises, :estimation, :assessment, :settlement, :acceptation, :registration), :mean, :min, :median, :max, :std)
# la médianne est très inférieure à la moyenne, certains experts monopolisent de nombreuses expertises. L’écart type est particulièrement élevé sur le nombre d’affaires.
expertsData[!, :nbExpertises]
transform!(
    expertsData,
    :nbExpertises => (x -> x / sum(x)) => :percent
)

# Contrôle : afficher Loir
# select(filter(x -> occursin("Loir", x.name), expertsData), :id, :name, :percent)

transform!(
    expertsData,
    AsTable([:estimation, :nbExpertises]) => ByRow(x -> x.estimation / x.nbExpertises) => :estimationpcent,
    AsTable([:assessment, :nbExpertises]) => ByRow(x -> x.assessment / x.nbExpertises) => :assessmentpcent,
    AsTable([:acceptation, :nbExpertises]) => ByRow(x -> x.acceptation / x.nbExpertises) => :acceptationpcent,
    AsTable([:settlement, :nbExpertises]) => ByRow(x -> x.settlement / x.nbExpertises) => :settlementpcent,
    AsTable([:registration, :nbExpertises]) => ByRow(x -> x.registration / x.nbExpertises) => :registrationpcent
)

select(expertsData, :surname, :nbExpertises, :estimationpcent, :assessmentpcent, :acceptationpcent, :settlementpcent, :registrationpcent )
# @todo faire un stacked bar histogram avec les catégories d'expertises par expert.

## Analyse factorielle
# Cibois, Philippe. s. d. « Principe de l’analyse factorielle ». https://cibois.pagesperso-orange.fr/PrincipeAnalyseFactorielle.pdf.
# >L’analyse  factorielle  est  une  technique  statistique  aujourd’hui  surtout  utilisée pour  dépouiller  des  enquêtes :  elle  permet,  quand  on  dispose  d’une  population d’individus pour lesquelles on possède de nombreux renseignements concernant les opinions,  les  pratiques  et  le  statut  (sexe,  âge,  etc.),  d’en  donner  une  représentation géométrique1, c'est-à-dire en utilisant un graphique qui permet de voir les rapprochements et les oppositions entre les caractéristiques des individus.
# analyse en composantes principales (ACP), et analyse factorielle des correspondances (AFC)

# Analyse des composantes principales
x = select(expertsData, :id, :estimation, :assessment, :acceptation, :settlement, :registration)

# ne fonctionne pas
# x = parse.(Float64, x[:, 2:5])

# split half to training set
Xtr = convert(Array,Array{Float64}(x[1:2:end,2:5]))'
Xtr_labels = convert(Array,Array(x[1:2:end, 1]))
# split other half to testing set
Xte = convert(Array, Array{Float64}(x[2:2:end,2:5]))'
Xte_labels = convert(Array,Array(x[2:2:end, 1]))
# suppose Xtr and Xte are training and testing data matrix,
# with each observation in a column
# train a PCA model, allowing up to 3 dimensions
M = fit(PCA, Xtr; maxoutdim=2)
# apply PCA model to testing set
Yte = MultivariateStats.transform(M, Xte)
# reconstruct testing observations (approximately)
Xr = reconstruct(M, Yte)


# Factor analysis
# https://multivariatestatsjl.readthedocs.io/en/stable/fa.html

Mfact = fit(FactorAnalysis, Xtr; maxoutdim=4)

YteFact = MultivariateStats.transform(Mfact, Xte)

XrFact = reconstruct(Mfact, YteFact)

# Graph projeté des experts par catégories

expertsByCategories = Matrix(select(categoriesNetwork, Not(:id)))

expertsByCategoriesNormP = [sum(mapslices(minimum,[i j],dims=2)) for i in eachrow(transpose(expertsByCategories)),j in eachcol(expertsByCategories)]

expertsByCategoriesNormT = [sum(mapslices(minimum,[i j],dims=2)) for i in eachrow(expertsByCategories),j in eachcol(transpose(expertsByCategories))]
expertsByCategoriesNormPGraph = Graph(expertsByCategoriesNormP)

# pondération des edges avec les valeurs normalisées
edgesCollectionCat = collect(edges(expertsByCategoriesNormPGraph))
edgelinewidthCat = Vector()
for i in edgesCollectionCat
    edgesString = split(string(i), " ")
    from = parse(Int64, edgesString[2])
    to = parse(Int64, edgesString[4])
    push!(edgelinewidthCat, expertsByCategoriesNormP[from, to])
end
[rem_edge!(expertsByCategoriesNormPGraph, i, i) for i in 1:numCategories]

gplot(expertsByCategoriesNormPGraph, edgelinewidth=edgelinewidthCat, nodelabel=categoriesNames, nodelabelc=nodelabelc, nodelabeldist=1.5, nodelabelangleoffset=π/2)
# trivial car le graph est complet. Certains experts réalisant des affaires de toutes les catégories
# resultMatrix[row][column] = sum(A[row][every column x]*B[row x][column])
# The sequence of operations should do the following:
# resultMatrix[row][column] = sum(min(A[row][every column x],B[row x][column]))
# Where B is the transpose of A.

expertsByCategoriesNormTGraph = Graph(expertsByCategoriesNormT)
[rem_edge!(expertsByCategoriesNormTGraph, i, i) for i in 1:numExperts]
# pondération des edges avec les valeurs normalisées
edgesCollectionCat_T = collect(edges(expertsByCategoriesNormTGraph))
edgelinewidthCat_T = Vector()
for i in edgesCollectionCat_T
    edgesString = split(string(i), " ")
    from = parse(Int64, edgesString[2])
    to = parse(Int64, edgesString[4])
    push!(edgelinewidthCat_T, expertsByCategoriesNormT[from, to])
end
nlist = Vector{Vector{Int}}(undef, 2) # two shells
nlist[1] = 1:5 # first shell
nlist[2] = 6:nv(expertsByCategoriesNormTGraph) # second shell
locs_x, locs_y = shell_layout(expertsByCategoriesNormTGraph, nlist)

gplot(expertsByCategoriesNormTGraph, edgelinewidth=edgelinewidthCat_T, nodelabel=expertNames, nodelabelc=nodelabelc, nodefillc=nodefillc[1:40], nodelabeldist=1.5, nodelabelangleoffset=π/2, layout=circular_layout, linetype="curve")

# discuter des répartition inégale des experts selon les catégories d'affaires. S'il y a des liens plus fort c'est certainement dû au nombre d'affaires (même ajusté ça persiste). Le graphe des experts par catégories montre la proéminence de certains types d'affaires, mais en revanche le graphe projeté par experts ne permet pas à première vue de déterminer des communautés d'experts ni un mécanisme d'attribution des types d'expertise.
# pas de structuration de la communauté à partir des catégories. Il faudrait peut être faire des analyses de bi-cliques ou de sous-cliques (même si vraisemblablement il n'y en a pas). Mais dans le fond, c'est déjà un résultat.

# @todo faire un stacked bar histogram avec les catégories d'expertises par expert.

#########################################################
# Conversion vers des données unimodales
#########################################################
# Matrice bimodale experts par expertises
expertisesMatrix = Matrix(adjacency_matrix(expertisesGraph))
# matrice d'affiliation bimodale à partir du graph
expertisesAfM = expertisesMatrix[1:numExperts, (numExperts+1):numNodes]

expertisesAfM_t = expertisesAfM * transpose(expertisesAfM)

gExpertisesAfM_t = Graph(expertisesAfM_t)

nodesize = vec(sum(expertisesAfM_t, dims=1))
# to keep or not to keep ?
nodesize = [log(i) for i in nodesize]

[rem_edge!(gExpertisesAfM_t, i, i) for i in 1:40]

edgelinewidth = Vector()
for i in collect(edges(gExpertisesAfM_t))
    edgesString = split(string(i), " ")
    from = parse(Int64, edgesString[2])
    to = parse(Int64, edgesString[4])
    push!(edgelinewidth, expertisesAfM_t[from, to])
end
edgelinewidth
# attribution d'un couleur pour les experts
expertColor = nodecolor[1:numExperts]
expertfillc=color[expertColor]
# paramètres du layout
expertLayout=(args...)->spring_layout(args...; C=20)
gplot(gExpertisesAfM_t, nodelabel=expertNames, nodelabelc=nodelabelc, nodelabeldist=3.5, nodelabelangleoffset=π/2, nodesize=nodesize, nodefillc=expertfillc, layout=expertLayout, edgelinewidth=edgelinewidth)

# certains experts participent à plus d’affaires, Borgatti suggère de normaliser les valeurs en utilisant Bonacich

# dans m, diviser les valeurs de la matrice d’origine par la √ de la somme de la colonne d’origine
colsum = sum(expertisesAfM, dims=2)

ponderation = vec(broadcast(√, colsum))

ponderate(x) = x ./ ponderation

# calculer la matrice normalisée en supprimant les valeurs NaN
normExpertisesAfM = replace!(mapslices(x -> ponderate(x), expertisesAfM, dims=1), NaN => 0)

# matrice normalisée projetée
normExpertisesAfM_p = transpose(normExpertisesAfM) * normExpertisesAfM

# matrice normalisée transposée
normExpertisesAfM_t = normExpertisesAfM * transpose(normExpertisesAfM)

# Cette valeur est interprétée comme un indice de la force de la proximité sociale entre deux experts.
# Pour l'interprétation, voir Bogartti 1997 p. 245-246

# collaboration avec des architectes, mis à jour avec la boucle ci-dessous
collabArchi = Int.(vec(zeros(40, 1)))
# collaboration avec des entrepreneurs, mis à jour avec la boucle ci-dessous
collabEnt = Int.(vec(zeros(40, 1)))
# collaboration avec des transfuges (ou inconnus), mis à jour avec la boucle ci-dessous
collabAutres = Int.(vec(zeros(40, 1)))

for expert in 1:numExperts
    for collab in 1:numExperts
        if normExpertisesAfM_t[expert, collab] > 0
            if expertsData[collab, :column] == "entrepreneur"
                collabEnt[expert] += 1
            elseif expertsData[collab, :column] == "architecte"
                collabArchi[expert] += 1
            else
                collabAutres[expert] += 1
            end
        end
    end
end

#graphe de la matrice normalisée transposée
g_normExpertisesAfM_t = MetaGraph(SimpleGraph(normExpertisesAfM_t))

[rem_edge!(g_normExpertisesAfM_t, i, i) for i in 1:40]

#########################################################
# VIZ
#########################################################

# pondération des edges avec les valeurs normalisées
edgesCollection = collect(edges(g_normExpertisesAfM_t))


edgelinewidth = Vector()
for i in edgesCollection
    edgesString = split(string(i), " ")
    from = parse(Int64, edgesString[2])
    to = parse(Int64, edgesString[4])
    push!(edgelinewidth, normExpertisesAfM_t[from, to]^3)
end
edgelinewidth
# pondération de la taille de nœuds avec la sommes des valeurs normalisées pour chaque experts
nodesizeA = vec(sum(normExpertisesAfM_t, dims=1))
nodesize = [log(i) for i in nodesizeA]

# attribution d'un couleur pour les experts
expertColor = nodecolor[1:numExperts]
expertfillc=color[expertColor]

# paramètres du layout
expertLayout=(args...)->spring_layout(args...; C=20)

gplot(g_normExpertisesAfM_t, nodelabel=expertNames, nodelabelc=nodelabelc, nodelabeldist=3.5, nodelabelangleoffset=π/2, nodesize=nodesize, nodefillc=expertfillc, layout=expertLayout, edgelinewidth=edgelinewidth)

#########################################################
# Metrics
#########################################################

# Bigraph experts par expertises (expertisesGraph)

# La densité d'un réseau bipartite nb edges/(nb experts * nb affaires) puisque les nœuds d'un mode ne peuvent pas avoir de relations entre eux.
# si densité = 1 tous les nœuds sont connectés entre eux, si 0 aucune connection.
bigraphDensity = ne(expertisesGraph)/(numExperts*numExpertises)

# travaillent avec peu de gens
g_ExpertisesAfM_tDensity = LightGraphs.density(gExpertisesAfM_t)
g_normExpertisesAfM_tDensity = LightGraphs.density(g_normExpertisesAfM_t)

# Centralité de degré
# C'est la somme des edges d'un nœud
# dans notre graphe bimodal, pour un expert c'est le nombre d'expertises auxquelles il participe, et pour une expertise, c'est le nombre d'experts qui y participe
bigraphDeg = vec(sum(expertisesMatrix, dims=2))

# Il est possible, pour interpréter cette valeur de la normaliser
# Pour Borgatti, la méthode Freeman n'est pas adaptée pour les données bimodales (Borgatti 1997, p. 254)
# On divise le degré de chaque nœud par le nombre de nœuds de l'autre mode
bigraphNormDeg = Vector()
for i in 1:numNodes
    if i <= numExperts
        value = (bigraphDeg[i]/numExpertises)*100
        push!(bigraphNormDeg, value)
    else
        value = (bigraphDeg[i]/numExperts)*100
        push!(bigraphNormDeg, value)
    end
end
bigraphNormDeg

# centralité de proximité
# Indique à quel point un nœud est proche de tous les autres nœuds du réseau.
# Elle est calculée comme la moyenne de la longueur du chemin le plus court entre le nœud et tous les autres nœuds du réseau.
# ex le réseau A-B-C-D-E-F (lettres = nœuds et tirets les edges)
# pour D, sa distance la plus courte à A = 3 (nombre de edges), B=2, C=1, E=1, F=2
# la centralité de proximité pour D = distance la plus courte à chaque nœuds (3+2+1+1+2)/(nb nœuds-1) dans un graphe normal
# plus la valeur est faible plus le nœud est central

#degree(gnormmp)
betweennessCentrality = betweenness_centrality(g_normExpertisesAfM_t)
closenessCentrality = closeness_centrality(g_normExpertisesAfM_t)
degreeCentrality = degree_centrality(g_normExpertisesAfM_t)
eigenvectorCentrality = eigenvector_centrality(g_normExpertisesAfM_t)
katzCentrality = katz_centrality(g_normExpertisesAfM_t)
#pagerank = pagerank(gnormmp)
radialityCentrality = radiality_centrality(g_normExpertisesAfM_t)
stressCentrality = stress_centrality(g_normExpertisesAfM_t)

rowsum = sum(expertisesGraph, 2)

bigraphDegreeCentrality = rowsum[1:numExperts]/numExpertises

# closenessCentrality normalisée
# @bug pb avec valeur 13 et 34
v = Vector()
for i in 1:numExperts
    push!(v, (numExpertises + 2numExperts - 2) / sum(replace(gdistances(expertisesGraph, i), 9223372036854775807 => 0)))
end

metrics = DataFrame(expert = expertNames, colonne=expertsColumns, normDeg=bigraphNormDeg[1:40],  bigraphDegreeCentrality=bigraphDegreeCentrality, degree=degree(g_normExpertisesAfM_t), betweennessCentrality=betweenness_centrality(g_normExpertisesAfM_t), closenessCentrality=closenessCentrality, degreeCentrality=degreeCentrality, eigenvectorCentrality=eigenvectorCentrality, katzCentrality=katzCentrality, pagerank=pagerank(g_normExpertisesAfM_t), radialityCentrality=radialityCentrality, stressCentrality=stressCentrality, collabArchi=collabArchi, collabEnt=collabEnt, collabAutres=collabAutres)
collabArchi

metrics

metricsArchi = metrics[metrics[!, :colonne] .== "architecte", :]
metricsEnt = metrics[metrics[!, :colonne] .== "entrepreneur", :]
# écrire le fichier
# CSV.write("file.csv", metrics)

sort(vec(Matrix(select(metrics, :normDeg))))

Plots.scatter()

sort!(metrics, [:eigenvectorCentrality])
Plots.scatter(
    metrics[!, :eigenvectorCentrality],
    color = color[1],
    label = "eigenvCent.",
    legend = :topleft,
    title = "Mesures de centralité dans le réseau bipartite",
    xtickfont = font(5, "Arial")
    )

scatter!(metrics[!, :bigraphDegreeCentrality], label = "degreeCent.", color = color[2])
scatter!(metrics[!, :closenessCentrality], label = "closCent.", color = color[3])
scatter!(metrics[!, :betweennessCentrality], label = "btwCent.", color = color[4])

scatter!(xticks=(1:size(metrics,1), metrics[!, :expert]), xrotation = 45, xtickfont = font(7, "Arial"))

# community detection
label_propagation(g_normExpertisesAfM_t)
println(maximal_cliques(g_normExpertisesAfM_t))

nlist = Vector{Vector{Int}}(undef, 2) # two shells
nlist[1] = 1:46 # first shell
nlist[2] = 47:514 # second shell

locs_x, locs_y = shell_layout(expertisesGraph, nlist)

locs_x = Vector()
for i in 1:numNodes
    if i < 47
        push!(locs_x, 1.00)
    else
        push!(locs_x, 2.00)
    end
end

locs_y = Vector()
for i in 1:numNodes
    if i < 47
        push!(locs_y, Float64(i))
    else i > 46
        push!(locs_y, Float64(i-46))
    end
end
locs_y
gplot(expertisesGraph, locs_x, locs_y)

readedgelist(expertisesGraph)
