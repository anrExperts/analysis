#########################################################
# global variables for graphs viz
#########################################################
# couleur des labels
nodelabelc = colorant"white"
# vecteur couleurs
colors = [colorant"#FF4500", colorant"#00D6AB", colorant"#700DFF", colorant"#FFF819"]

#########################################################
# experts - expertises bipartite metagraph
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
expertisesBigraph = MetaGraph(SimpleGraph())
# Création des nœuds
add_vertices!(expertisesBigraph, numNodes)

# ajout des métadonnées pour les nœuds experts
for expert in 1:numExperts
    set_prop!(expertisesBigraph, expert, :id, experts[expert])
    set_prop!(expertisesBigraph, expert, :name, expertNames[expert])
    set_prop!(expertisesBigraph, expert, :column, expertsColumns[expert])
    set_prop!(expertisesBigraph, expert, :cat, "expert")
    set_prop!(expertisesBigraph, expert, :degree, sum(expertisesNetwork[expert, Not(:id)]))
end

# ajout des métadonnées pour les nœuds expertises
global posExpertise = 1
for expertise in (numExperts+1):numNodes
    for i in 1:numExpertises
        set_prop!(expertisesBigraph, expertise, :id, expertises[posExpertise])
        set_prop!(expertisesBigraph, expertise, :cat, "expertise")
    end
    global posExpertise += 1
end

# ajout des edges
col = 1
for column in expertises
    global pos = 1
    for expert in expertisesNetwork[!, column]
        if expertisesNetwork[!, column][pos] > 0
            add_edge!(expertisesBigraph, pos, col+numExperts)
        end
        global pos += 1
    end
    global col += 1
end

#########################################################
# experts - expertises bipartite graph VIZ
#########################################################
#node color
ncExpertisesBigraph = Vector()
#pour chaque nœuds du graph, on vérifie son type pour mettre à jour le vecteur (valeur 1 ou 2 correspondant au position du vecteur color ci-après)
for i in sort(collect(keys(expertisesBigraph.vprops)))
  if expertisesBigraph.vprops[i][:cat] == "expert"
    if expertisesBigraph.vprops[i][:column] == "architecte"
      push!(ncExpertisesBigraph, 1)
    elseif expertisesBigraph.vprops[i][:column] == "entrepreneur"
      push!(ncExpertisesBigraph, 2)
    else
      push!(ncExpertisesBigraph, 3)
    end
  else
    push!(ncExpertisesBigraph, 4)
  end
end

layoutExpertisesBigraph = (args...)->spring_layout(args...; C=30)
expertisesBigraphPlot = gplot(
  expertisesBigraph,
  nodefillc=colors[ncExpertisesBigraph],
  layout=layoutExpertisesBigraph
)

#########################################################
# experts - categories bipatite metagraph
#########################################################
categories = names(select(categoriesNetwork, Not([:id])))
categoriesNames = categoriesData[!, :name]

#nb de catégories
numCategories = length(categories)

# création du Graph
categoriesBigraph = MetaGraph(SimpleGraph())

# Création des nœuds
add_vertices!(categoriesBigraph, (numExperts+numCategories))
# ajout des métadonnées pour les nœuds experts
for expert in 1:numExperts
    set_prop!(categoriesBigraph, expert, :id, experts[expert])
    set_prop!(categoriesBigraph, expert, :name, expertNames[expert])
    set_prop!(categoriesBigraph, expert, :column, expertsColumns[expert])
    set_prop!(categoriesBigraph, expert, :cat, "expert")
end

# ajout des métadonnées pour les nœuds categories
global posCategory = 1
for category in (numExperts+1):(numExperts+numCategories)
    for i in 1:numCategories
        set_prop!(categoriesBigraph, category, :id, categories[posCategory])
        set_prop!(categoriesBigraph, category, :name, categoriesNames[posCategory])
        set_prop!(categoriesBigraph, category, :cat, "category")
    end
    global posCategory += 1
end

# ajout des edges
col = 1
for column in categories
    global pos = 1
    for expert in categoriesNetwork[!, column]
        if categoriesNetwork[!, column][pos] > 0
            add_edge!(categoriesBigraph, pos, col+numExperts)
        end
        global pos += 1
    end
    global col += 1
end

#########################################################
# experts - categories bipartite graph VIZ
#########################################################
#node color
ncCategoriesBigraph = Vector()
#pour chaque nœuds du graph, on vérifie son type pour mettre à jour le vecteur (valeur 1 ou 2 correspondant au position du vecteur color ci-après)
for i in sort(collect(keys(categoriesBigraph.vprops)))
  if categoriesBigraph.vprops[i][:cat] == "expert"
    if categoriesBigraph.vprops[i][:column] == "architecte"
      push!(ncCategoriesBigraph, 1)
    elseif categoriesBigraph.vprops[i][:column] == "entrepreneur"
      push!(ncCategoriesBigraph, 2)
    else
      push!(ncCategoriesBigraph, 3)
    end
  else
    push!(ncCategoriesBigraph, 4)
  end
end

#node label
nlCategoriesBigraph = Vector()
for name in 1:(numExperts+numCategories)
    push!(nlCategoriesBigraph, categoriesBigraph.vprops[name][:name])
end

layoutCategoriesBigraph = (args...)->spring_layout(args...; C=25)
# @todo faire un parallel coordinates networks
categoriesBigraphPlot = gplot(
  categoriesBigraph,
  nodefillc=colors[ncCategoriesBigraph],
  layout=layoutCategoriesBigraph,
  nodelabel=nlCategoriesBigraph,
  nodelabelc=nodelabelc,
  nodelabeldist=3.5,
  nodelabelangleoffset=π/2
)

#########################################################
# bipartite to unipartite
#########################################################
# experts – expertises
#########################################################

# Matrice bimodale experts par expertises
expertsByExpertisesMatrix = Matrix(adjacency_matrix(expertisesBigraph))
# Matrice d'affiliation bimodale à partir du graph
amExpertsByExpertises = expertsByExpertisesMatrix[1:numExperts, (numExperts+1):numNodes]
# Projection sur les experts
ampExpertsByExpertises = amExpertsByExpertises * transpose(amExpertsByExpertises)

# Graphe de co-occurence des experts par les affaires
expertsGraphFromExpertises = Graph(ampExpertsByExpertises)
# calcul du degré des nœuds
#nodesize = vec(sum(ampExpertsByExpertises, dims=1))
#pour faire un node size sur la force des nœuds (retire les selfLoop)
nsExpertsGraphFromExpertises = [first(sum(ampExpertsByExpertises[:, i], dims=1)) - ampExpertsByExpertises[i, i] for i in 1:numExperts]
# pondération
nsExpertsGraphFromExpertises = [sqrt(i) for i in nsExpertsGraphFromExpertises]

# supression des boucles (self-loops)
[rem_edge!(expertsGraphFromExpertises, i, i) for i in 1:numExperts]

# pondération des edges
# @todo insérer les valeurs dans les propriétés du graphe
elwExpertsGraphFromExpertises = Vector()
for i in collect(edges(expertsGraphFromExpertises))
    edgesString = split(string(i), " ")
    from = parse(Int64, edgesString[2])
    to = parse(Int64, edgesString[4])
    push!(elwExpertsGraphFromExpertises, ampExpertsByExpertises[from, to])
end
# attribution d'une couleur pour les experts
ncExperts = ncExpertisesBigraph[1:numExperts]

layoutExpertsGraphFromExpertises = (args...)->spring_layout(args...; C=22)

expertsGraphFromExpertisesPlot = gplot(
  expertsGraphFromExpertises,
  nodelabel=expertNames,
  nodelabelc=nodelabelc,
  nodelabeldist=3.5,
  nodelabelangleoffset=π/2,
  nodesize=nsExpertsGraphFromExpertises,
  nodefillc=colors[ncExperts],
  layout=layoutExpertsGraphFromExpertises,
  edgelinewidth=elwExpertsGraphFromExpertises
)

#########################################################
# Normalized experts – expertises
#########################################################
# certains experts participent à plus d’affaires, Borgatti suggère de normaliser les valeurs en utilisant Bonacich
# diviser les valeurs de la matrice d’origine par la √ de la somme de la colonne d’origine

expertsByExpertisesRowsum = sum(amExpertsByExpertises, dims=2)
expertsByExpertisesPonderation = vec(broadcast(√, expertsByExpertisesRowsum))
ponderate(x) = x ./ expertsByExpertisesPonderation

# calculer la matrice normalisée en supprimant les valeurs NaN
amExpertsByExpertisesN = replace!(mapslices(x -> ponderate(x), amExpertsByExpertises, dims=1), NaN => 0)

# matrice normalisée transposée
ampExpertsByExpertisesN = amExpertsByExpertisesN * transpose(amExpertsByExpertisesN)

# Cette valeur est interprétée comme un indice de la force de la proximité sociale entre deux experts.
# Pour l'interprétation, voir Bogartti 1997 p. 245-246

# collaboration avec des architectes, mis à jour avec la boucle ci-dessous
collabArchi = Int.(vec(zeros(numExperts, 1)))
# collaboration avec des entrepreneurs, mis à jour avec la boucle ci-dessous
collabEnt = Int.(vec(zeros(numExperts, 1)))
# collaboration avec des transfuges (ou inconnus), mis à jour avec la boucle ci-dessous
collabAutres = Int.(vec(zeros(numExperts, 1)))
for expert in 1:numExperts
    for collab in 1:numExperts
        if ampExpertsByExpertisesN[expert, collab] > 0
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
expertsGraphFromExpertisesN = MetaGraph(SimpleGraph(ampExpertsByExpertisesN))
[rem_edge!(expertsGraphFromExpertisesN, i, i) for i in 1:numExperts]

#########################################################
# VIZ
#########################################################
# pondération des edges avec les valeurs normalisées
ecExpertsGraphFromExpertisesN = collect(edges(expertsGraphFromExpertisesN))
elwExpertsGraphFromExpertisesN = Vector()
for i in ecExpertsGraphFromExpertisesN
    edgesString = split(string(i), " ")
    from = parse(Int64, edgesString[2])
    to = parse(Int64, edgesString[4])
    push!(elwExpertsGraphFromExpertisesN, ampExpertsByExpertisesN[from, to])
end

# pondération de la taille de nœuds avec la sommes des valeurs normalisées pour chaque experts
nsExpertsGraphFromExpertisesN = [first(sum(ampExpertsByExpertisesN[:, i], dims=1)) - ampExpertsByExpertisesN[i, i] for i in 1:numExperts]
#nodesizeA = vec(sum(ampExpertsByExpertisesN, dims=1))
nsExpertsGraphFromExpertisesN = [sqrt(i) for i in nsExpertsGraphFromExpertisesN]

layoutExpertsGraphFromExpertisesN = (args...)->spring_layout(args...; C=22)
# Graphe valué de co-occurence des experts par les affaires pondéré sur le nombre d’expertises
expertsGraphFromExpertisesNPlot = gplot(
  expertsGraphFromExpertisesN,
  nodelabel=expertNames,
  nodelabelc=nodelabelc,
  nodelabeldist=3.5,
  nodelabelangleoffset=π/2,
  nodesize=nsExpertsGraphFromExpertisesN,
  nodefillc=colors[ncExperts],
  layout=layoutExpertsGraphFromExpertisesN,
  edgelinewidth=elwExpertsGraphFromExpertisesN
)

#########################################################
# Metrics
#########################################################
expertsMetrics = expertsData

# Bigraph experts par expertises (expertisesBigraph)
# La densité d'un réseau bipartite nb edges/(nb experts * nb affaires) puisque les nœuds d'un mode ne peuvent pas avoir de relations entre eux.
# si densité = 1 tous les nœuds sont connectés entre eux, si 0 aucune connection.
expertisesBigraphDensity = ne(expertisesBigraph)/(numExperts*numExpertises)
expertsGraphFromExpertisesDensity = LightGraphs.density(expertsGraphFromExpertises)
expertsGraphFromExpertisesNDensity = LightGraphs.density(expertsGraphFromExpertisesN)

# Centralité de degré
# C'est la somme des edges d'un nœud
# dans notre graphe bimodal, pour un expert c'est le nombre d'expertises auxquelles il participe, et pour une expertise, c'est le nombre d'experts qui y participe
expertisesBigraphCentrality = vec(sum(expertsByExpertisesMatrix, dims=2))

# Il est possible, pour interpréter cette valeur de la normaliser
# Pour Borgatti, la méthode Freeman n'est pas adaptée pour les données bimodales (Borgatti 1997, p. 254)
# On divise le degré de chaque nœud par le nombre de nœuds de l'autre mode
expertisesBigraphCentralityN = Vector()
for i in 1:numNodes
    if i <= numExperts
        value = (expertisesBigraphCentrality[i]/numExpertises)*100
        push!(expertisesBigraphCentralityN, value)
    else
        value = (expertisesBigraphCentrality[i]/numExperts)*100
        push!(expertisesBigraphCentralityN, value)
    end
end
expertsGraphFromExpertisesNCloseness = closeness_centrality(expertsGraphFromExpertisesN)

# closenessCentrality normalisée
# @bug pb avec valeur 13 et 34
#%%
expertsGraphFromExpertisesNClosenessN = Vector()
for i in 1:numExperts
    push!(expertsGraphFromExpertisesNClosenessN, (numExpertises + 2numExperts - 2) / sum(replace(gdistances(expertisesBigraph, i), 9223372036854775807 => 0)))
end
#%%
# centralité de proximité
# Indique à quel point un nœud est proche de tous les autres nœuds du réseau.
# Elle est calculée comme la moyenne de la longueur du chemin le plus court entre le nœud et tous les autres nœuds du réseau.
# ex le réseau A-B-C-D-E-F (lettres = nœuds et tirets les edges)
# pour D, sa distance la plus courte à A = 3 (nombre de edges), B=2, C=1, E=1, F=2
# la centralité de proximité pour D = distance la plus courte à chaque nœuds (3+2+1+1+2)/(nb nœuds-1) dans un graphe normal
# plus la valeur est faible plus le nœud est central

#degree
degreeMeasure = degree(expertsGraphFromExpertisesN)
betweennessCentrality = betweenness_centrality(expertsGraphFromExpertisesN)
degreeCentrality = degree_centrality(expertsGraphFromExpertisesN)
closenessCentrality = closeness_centrality(expertsGraphFromExpertisesN)
eigenvectorCentrality = eigenvector_centrality(expertsGraphFromExpertisesN)
katzCentrality = katz_centrality(expertsGraphFromExpertisesN)
#pagerank = pagerank(gnormmp)
radialityCentrality = radiality_centrality(expertsGraphFromExpertisesN)
stressCentrality = stress_centrality(expertsGraphFromExpertisesN)
pagerankMeasure = pagerank(expertsGraphFromExpertisesN)

metrics = DataFrame(
            expert = expertNames,
            colonne = expertsColumns,
            bigraphDegreeCentrality = expertisesBigraphCentrality[1:numExperts],
            bigraphDegreeCentralityN = expertisesBigraphCentralityN[1:numExperts],
            bigraphCloseness = expertsGraphFromExpertisesNCloseness,
            bigraphClosenessN = expertsGraphFromExpertisesNClosenessN,
            degree = degreeMeasure,
            betweenness = betweennessCentrality,
            closeness = closenessCentrality,
            degreeCentrality = degreeCentrality,
            eigenvectorCentrality = eigenvectorCentrality,
            katzCentrality = katzCentrality,
            pagerank = pagerankMeasure,
            radialityCentrality = radialityCentrality,
            stressCentrality = stressCentrality,
            collabArchi = collabArchi,
            collabEnt = collabEnt,
            collabAutres = collabAutres
        )
metricsArchi = metrics[metrics[!, :colonne] .== "architecte", :]
metricsEnt = metrics[metrics[!, :colonne] .== "entrepreneur", :]

centrality = describe(
                select(
                    metrics,
                    :expert,
                    :bigraphCloseness,
                    :bigraphClosenessN,
                    :closeness,
                    :bigraphDegreeCentrality,
                    :bigraphDegreeCentralityN,
                    :degreeCentrality
                ))
