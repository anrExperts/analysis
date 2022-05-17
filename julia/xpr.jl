#%% packages
# alt + enter (⌥ + ↵) to execute cells
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
# Cairo et Compose : pour sauvegarder les gplot
using Cairo
using Compose

using RCall

#%% Variables
year = 1726
# dataframe experts par expertises
expertisesNetwork = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/networks/$year/expertises").body, header=1) |> DataFrame
# dataframe experts par categories
categoriesNetwork = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/networks/$year/categories").body, header=1) |> DataFrame
# données sur les experts
expertsData = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/data/$year/experts").body, header=1) |> DataFrame
# données complétées par RC
#expertsData = CSV.File("/Volumes/data/github/analysis/data/expertsData$year.csv", header=1) |> DataFrame
# données sur les expertises
expertisesData = CSV.File(HTTP.get("https://experts.huma-num.fr/xpr/data/$year/expertises").body, header=1) |> DataFrame
# données sur les catégories
categoriesData = DataFrame(id=names(categoriesNetwork[!, Not(:id)]), name=["Recevoir et évaluer le travail réalisé", "Décrire et évaluer les travaux à venir", "Estimer la valeur des biens", "Départager", "Enregistrer"])

#%% Graphs viz cell
include("makeGraphs.jl")

expertisesBigraphPlot

categoriesBigraphPlot

expertsGraphFromExpertisesPlot

expertsGraphFromExpertisesNPlot

#%% Metrics
metrics

metricsEnt

metricsArchi

centrality

#R scripts for assortativity
R"source('/Volumes/data/github/analysis/R/nbipartite.r')"
R"source('/Volumes/data/github/analysis/R/bipartite.r')"

@rget nAssort
@rget nAssortNominal
@rget nAssortDegree
@rget nAssortRemainingWeights

@rget assort
@rget assortNominal
@rget assortDegree
@rget assortRemainingWeights


# écrire le fichier
# CSV.write("file.csv", metrics)

##
expertisesBigraphCentrality[numExperts+1: numNodes]
nbExpertsByExpertises = sum.(eachcol(expertisesNetwork[!, Not(:id)]))
UnicodePlots.histogram(sum.(eachcol(expertisesNetwork[!, Not(:id)])), nbins=length(unique(nbExpertsByExpertises)))
expertisesBigraphCentrality[1:numExperts]
nbExpertisesByExpert = sum.(eachrow(expertisesNetwork[!, Not(:id)]))
print(UnicodePlots.histogram(nbExpertisesByExpert, nbins=length(unique(nbExpertisesByExpert))))

insertcols!(expertsData, :n => nbExpertisesByExpert)
describe(expertsData)
archis = expertsData[expertsData[!, :column] .== "architecte", :]
describe(archis)

entrepreneurs = (expertsData[expertsData[!, :column] .== "entrepreneur", :])
describe(entrepreneurs)

# @todo ajouter les % et les écarts types et médiane
# @todo sortir un histogramme (stacqed bar chart) avec pour chaque expert le type d'affaires dont il s'occupe + nb d'affaires
