using RDatasets
using DataFrames
using StatsBase
using Statistics
using Random

# Manipulating a DataFrame
# cf. https://alan-turing-institute.github.io/DataScienceTutorials.jl/data/dataframe/
# cf. https://github.com/bkamins/Julia-DataFrames-Tutorial/blob/e2f78da6635231e8b1d0c397d6b8d5e57b887804/01_constructors.ipynb

# Utiliser le jeu de données Boston de `RDatasets.jl`
boston = dataset("MASS", "Boston");

# la fonction dataset `renvoit` un objet DataFrame
typeof(boston)

# Un DataFrame est un moyen commode d’accéder à des tableaux
boston
# Il s’agit d’une manière d’englober plusieurs colonnes sous la forme de `Vector` avec des types et des noms
names(boston)
# Voir les 4 premières lignes avec first()
first(boston, 4)
# accéder à une colonne par son nom retourne un vecteur auquel on peut accéder comme n’importe quel autre vecteur dans Julia
boston.Crim[1:5]
# il est également possible de désigner un sous ensemble du tableau comme dans une matrice
boston[3, 5]
# ou encore de spécifier une étendue de lignes et de colonnes
boston[1:5, [:Crim, :Zn]]
# ou encore en sélectionnant deux étendues
boston[1:5, 1:2]
# La fonction select() est très commode pour sélectionner des sous-DataFrames
b1 = select(boston, [:Crim, :Zn, :Indus])
first(b1, 2)
# Dans certains cas, il peut être utile d’utiliser la syntaxe Not() pour exclure une ou plusieurs colonnes
b2 = select(boston, Not(:NOx))
first(b2, 2)
b2 = select(boston, Not([:NOx, :Indus]))

# La libraire `StatsBase` propose une fonction `describe()` très commode pour avoir une vue générale sur les données
describe(boston, :min, :max, :mean, :median, :std)
# il est possible d’ajouter des fonctions personnalisées [ne fonctionne pas]
foo(x) = sum(abs.(x)) / length(x)
d = describe(boston, :mean, :median, :foo => foo())
first(d, 3)
# Convertir les données du DataFrame en une matrice (nota : convert(Matrix, df) ne fonctionne plus)
mat = Matrix(boston)
mat[1:3, 1:3]
# Créer de nouvelles valeurs
insertcols!(boston, 3, :foo => boston.Crim .* boston.Zn)
# Supprimer une colonne par son nom
select!(boston, Not(:foo))
# Valeurs manquantes
mao = dataset("gap", "mao")
describe(mao, :nmissing)
# comme le jeu de données présente de nombreuses données manquantes, les calculs sur les colonnes
std(mao.Age)
std(skipmissing(mao.Age))

# Combinaisons, etc.
iris = dataset("datasets", "iris")
first(iris, 3)
# `groupby()` permet decréer des sous-dataframes correspondant à des groupes de ligne ce qui peut être très commode pour faire des analyses spécifiques sans avoir à copier les données
unique(iris.Species)
gdf = groupby(iris, :Species);
typeof(gdf)
subdf_setosa = gdf[3]
describe(subdf_setosa, :min, :mean, :max)
# Attention subdf_setosa est un SubDataFrame, il s’agit seulement d’une vue du DataFrame parent `iris`. La modification du parent entraîne celle du sous-dataframe.

# La fonction `combine()`` permet de dériver un nouveau dataframe à partir de la transformation d’un autre dataframe
df = DataFrame(a=2:4, b=4:6)
combine(df, :a => sum, nrow)
foo(v) = v[1:2]
combine(df, :a => maximum, :b => foo)
bar(v) = v[end-1:end]
combine(df, :a => foo, :b => bar)

# Combine avec groupby
combine(groupby(iris, :Species), :PetalLength => maximum)
combine(groupby(iris, :Species), :PetalLength => minimum, :PetalLength => maximum, :PetalLength => mean)

# il est également possible de renommer les colonnes
combine(groupby(iris, :Species), :PetalLength => mean, :PetalLength => length => :n)
gdf = groupby(iris, :Species)
combine(gdf, names(iris, Not(:Species)) .=> std)

# DataFrames https://github.com/bkamins/Julia-DataFrames-Tutorial/blob/e2f78da6635231e8b1d0c397d6b8d5e57b887804/01_constructors.ipynb
DataFrame()
DataFrame(A=1:3, B=rand(3), C=randstring.([3,3,3]))
# transformer un dictionnaire en tableau
x = Dict("A" => [1, 2], "B" => [true, false], "C" => ['a', 'b'])
DataFrame(x)
DataFrame(x).A
x = Dict(:A => [1,2], :B => [true, false], :C => ['a', 'b'])
DataFrame(x)
