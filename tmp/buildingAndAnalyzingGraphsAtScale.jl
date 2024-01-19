# JuliaCon 2020 | Building and Analyzing Graphs at Scale
# https://www.youtube.com/watch?v=K3z0kUOBy2Y
# https://github.com/matbesancon/lightgraphs_workshop
using LightGraphs
using MetaGraphs
using SimpleWeightedGraphs
using GraphPlot
using Random
using BenchmarkTools: @btime
using SNAPDatasets
using GraphPlot: gplot, gplothtml
using Colors: @colorant_str

# LightGraphs et MetaGraphs sont des packages "officiels" de Julia et sont rédigés en Julia.
# Pour l'analyse de graph, dans les benchmark, Julia et LightGraphs se sont montrés particulier performants, ce ne sont pas toujours les plus rapides, mais globalement les résultats sont dans le haut du panier. (un peut moins performant en ce qui concerne le chargement des graphs).

#LightGraphs
# - Les nœuds (vertices) sont des integers
# - Les nœuds (vertices) sont continus (il peut y avoir des nœuds isolés (reliés à aucun autre), mais si on a un nœud "no7", il doit obligatoirement y avoir un nœud "no6").
# - un graph peut être orienté ou non-orienté
# - il n'y a pas de multiedges
# - il n'y a pas de self loop

#MetaGraphs
# dans un MetaGraph, chaque nœud et chaque edge peut avoir une propriété qui peut ête de n'importe quel type Julia
# on peut donc donner des noms à des nœuds ou des edges, indiquer une pondération, etc.

# Simple(Di)Graph
# c'est le premier graph défini pas LightGraphs. Il est fondé sur un liste d'adjacence, qui est la structure typique d'un graph.
# dans une liste d'adjacence, chaque nœud est associé à une collection non-ordonnée de voisins

#crée un réseau bipartite, 2*2 nœuds ([1,2]; [3,4]) et chaque nœud d'un mode est connecté aux deux autres nœuds de l'autre mode
g = complete_bipartite_graph(2,2)
# @rmq je ne comprends pas bien ce que fait cette function seed!, mais elle change l'aspect du gplot qui suit => chaque type de nœud d'un côté.
Random.seed!(42)
#affichage du réseau avec les noms des nœuds
gplot(g, nodelabel=vertices(g))
# Liste d'adjacence (dans un graph non orienté) : c'est la liste des voisins de chaque sommet ou nœud.
# l = (
#      {3,4} # voisins du nœud 1
#      {3,4} # voisins du nœud 2
#      {1,2} # voisins du nœud 3
#      {1,2} # voisins du nœud 4
#     )
# fadjlist ne retourne pas une liste mais un vecteur de vecteur(s), qui est plus léger pour la gestion de la mémoire et plus rapide pour certaines opérations.
g.fadjlist
# Commentaires
# il y une redondance, puisque les informations sur les edges sont stockées deux fois : 1 est lié à 3 ({3,4}) mais dans la liste d'adjacence 3 est aussi lié à 1 ({1,2})
# => chaque information sur une edge est donc stockée deux fois dans la liste d'adjacence. Pour autant cela permet en réalité des accès plus rapides.
# L'utilisation de dictionnaires seraient beaucoup gourmande en resource et donc plus lente.

#SimpleGraphs est donc très efficace pour créer de gros graphs, qu'ils soient complets ou non
# @btime affiche le temps nécessaire à l'exécution de la commande dans le Repl
@btime SimpleGraph(1000)
@btime complete_graph(1000)

##Graphs orientés
# un graph est orienté lorsque les edges ont une direction entre un sommet et un autre ; ce ne sont plus uniquement des "connexions" entre deux sommets.
g = complete_digraph(5)
gplot(g)
# La liste d'adjacence pose plus de problème
# il est facile de trouver un sommet et de de trouver ses voisins dans un vecteur trié, puis de passer au suivant
# il est plus difficile de partir d'un nœud X, puis de chercher dans toutes les listes où X est un voisin, et de passer au suivant.
# Il y a donc deux listes d'adjacence = fadjlist (forward adjacence list) et badjlist (backward adjacence list)
#cycle_digraph => chaque nœud est relié au suivant, comme dans un cercle, le 1 au 2, le 2 au 3, etc.
g = cycle_digraph(4)
gplot(g, nodelabel=vertices(g))
g.fadjlist
g.badjlist

## Construire des graphs simples
# Il est possible de construire des graphs de différences manières, en fonction des sources de données dont nous disposons.
#création d'un graph simple from scratch, avec un type custom
SimpleGraph(UInt)
#création d'un graph simple from scratch, avec un autre type custom
SimpleGraph(UInt8)
#on peut aussi le faire à partir d'une matrice d'ajacence, qui est en réalité une autre manière de réprésenter un graph
gplot(
    SimpleDiGraph(
        [
            0 1 1 0
            0 0 1 0
            0 0 0 0
            0 0 1 0
        ]
    ),
    nodelabel=vertices(g)
)
# Il est aussi possible de créer un graph à partir d'une liste de edges, ou encore à partir d'une liste de vecteur de edges.
gplot(
    SimpleGraph(
        [
            Edge(1,2),
            Edge(1,3),
            Edge(3,3) #on a ajouté une self loop ici, qui ne fait pas planter le système, mais comme dit en intro ça peut parfois poser problème.
        ]
    ),
    nodelabel = 1:3
)
# on peut également créer un graph à partir d'un iterateur d'edges
iter = (Edge(i, i+1) for i in 1:4)
gplot(SimpleGraphFromIterator(iter), nodelabel=1:5)

## Autres types de graph

# function pour simplifier la visualisation des graph qui suivent
function viz(
        g::LightGraphs.AbstractSimpleGraph{T};
        vertex_labels = 1:nv(g),
        color_vertices = Vector{T}(),
        color_edges = Vector{Edge{T}}(),
        edge_labels = String[],
        weights = nothing
    ) where {T}

    order_edge(e::Edge) = Edge(minmax(src(e), dst(e)))

    color_vertices = Set(color_vertices)
    color_edges = is_directed(g) ? Set(color_edges) : Set(order_edge.(color_edges))

    if weights != nothing && isempty(edge_labels)
        edge_labels = map(e -> string(weights[dst(e), src(e)]), edges(g))
    end

    vertex_colors = map(v -> v ∈ color_vertices ? colorant"lightblue" : colorant"lightgrey", vertices(g))
    edge_colors = map(e -> e ∈ color_edges ? colorant"red" : colorant"lightgrey", edges(g))

    Random.seed!(5)
    gplot(g,
        nodelabel    = vertex_labels,
        edgestrokec  = edge_colors,
        edgelabel    = edge_labels,
        nodefillc    = vertex_colors,
        nodestrokec  = colorant"darkgrey",
        nodestrokelw = 1,
        NODELABELSIZE = 5,
        EDGELABELSIZE = 5
    )
end
viz(gw::AbstractSimpleWeightedGraph; kwargs...) =
    viz(is_directed(gw) ? SimpleDiGraph(gw) : SimpleGraph(gw); weights=adjacency_matrix(gw), kwargs...)
#smallgraph permet la création de petits graphs, avec comme argument des graphs prédéfinis
g = smallgraph(:house)
#visualisation des edges
edges(g) |> collect
#fonction créée plus haut avec le graph comme parametre => graph en forme de maison (:house).
viz(g)
# the minimum spanning tree => quand on a un graph (non orienté et connexe (tous les objets sont reliés entre eux ), dont les arêtes sont pondérées) et qu'on souhaite avoir un subset des edges qui permettent d'avoir tous les nœuds connectés.
# en fr on parle d'Arbre couvrant de poids minimal = dont la somme des poids des arêtes est minimale, c'est-à-dire de poids inférieur ou égal à celui de tous les autres arbres couvrants du graphe.
# https://fr.wikipedia.org/wiki/Arbre_couvrant_de_poids_minimal
prim_mst(g)
# pour les visualiser sur le graphe
viz(g, color_edges = prim_mst(g))
# Arbre couvrant de poids minimal pondéré = Weighted minimum spanning tree
# On ajoute ici un propriété aux edges : la pondération.
# on récupère ici la matrice d'adjacence. Le poids étant
weight_matrix = adjacency_matrix(g) |> Matrix
# on met à jour le poids des arêtes
# NB : dans un graph non orienté la matrice doit être symétrique
weight_matrix[1, 3] = 100; weight_matrix[3, 1] = 100;
#weight_matrix[1, 2] = 100; weight_matrix[2, 1] = 100;
#weight_matrix[3, 5] = 100; ws[5, 3] = 100;
#matrice mise à jour
weight_matrix
#visualisation : l'Arbre couvrant de poids minimal a changé, avec la pondération il veut éviter de passer par l'arête 1,3.
viz(g, color_edges=prim_mst(g, weight_matrix),  weights=weight_matrix)
#Si je ne veux par exemple que l'arbre couvrant de poids minimal passe par (1,2) ni par (5,4), il suffit d'augmenter le poids de ces arêtes
weight_matrix = adjacency_matrix(g) |> Matrix
# NB : dans un graph non orienté la matrice doit être symétrique
weight_matrix[1, 2] = 100; weight_matrix[2, 1] = 100;
weight_matrix[4, 5] = 100; weight_matrix[5, 4] = 100;
#visualisation : l'Arbre couvrant de poids minimal a changé, avec la pondération il veut éviter de passer par l'arête 1,3.
viz(g, color_edges=prim_mst(g, weight_matrix),  weights=weight_matrix)
# dans l'exemple précédent, pour ajouter la pondération, nous avons créé une matrice et avons mis à jour la pondération pour que le visualiseur puisse la prendre en considération.
# Avec SimpleWeightedGraphs, il est possible de stocker les métadonnées liées à la pondération dans le graphe.
gw = SimpleWeightedGraph(smallgraph(:house))
# comme nous n'avons pas spécifié le poids, il prend la valeur standard de 1
viz(gw)
#créons une matrice d'adjacence symétrique
A = Float64[
     0 4 2
     4 0 1
     2 1 0
    ]
# on notera que le poids est bien une décimale (Float64) comme typé dans la matrice d'adjacence
gw2 = SimpleWeightedGraph(A)
viz(gw2)
viz(gw2, color_edges = prim_mst(gw2))
#Pour modifier la pondération, il est possible de passer par la fonction add_edge!($graph, $node1, $node2, $weight)
add_edge!(gw2, 2 , 3, 100)
viz(gw2)
# la valeur 0 est ignorée car elle représente une arête inexistante.
add_edge!(gw2, 2 , 3, 0)
viz(gw2)
# de la même manière, il est possible de supprimer des arêtes
rem_edge!(gw2, 2, 3)
viz(gw2)
# si on observe la matrice, on s'aperçoit que la pondération y est indiquée
# NB intéressant pour nous car si nous produisons une matrice avec les graphes pondérés ça devrait être pris en compte directement, sans avoir besoin de remplacer les valeurs.
adjacency_matrix(gw2) |> Matrix

# directed star graph without weights
viz(star_digraph(4))
#Create a matrix that represents the weighted adjacency matrix of the following graph
# Note source of edge is column number not row number
A = [
    0 0 0 0
    2 0 0 0
    3 0 0 0
    4 0 0 0
    ]
#Ensure that edge (1, n) has weight n
#Convert the graph to SimpleWeightedDiGraph
gwd = SimpleWeightedDiGraph(A)
viz(gwd)

#Si l'on veut ajouter plus de propriétés à notre graph, il faut utiliser MetaGraphs.jl
