# Read CSV to Data Frame in Julia #

# La première étape pour toute analyse de données consiste à récupérer les données. Les fonctions utiles pour charger des fichiers CSV dans des DataFrames se répartissent entre `CSV.jl` et `DataFrames.jl`, il y a plusieurs manière de les combiner entre eux

# chargez les deux librairies après les avoir installées avec le gestionnaire de paquets (`add CSV; add DataFrames`)
using CSV
using DataFrames

#= Enregistrer le fichier CSV suivant
```csv
col1,col2,col3
A,13,4.0
B,12,7.1
```
=#

# print working directory
println(pwd())

# load csv file
csvReader = CSV.File("data/file.csv")

# le résultat est un object `CSV.File`
println(typeof(csvReader))

# On peut itérer cet objet `CSV.Files` pour obtenir des CSV.Rows
for row in csvReader
    println(typeof(row))
end

# Il est possible d’accéder aux valeurs en utilisant leur nom de colonne
for row in csvReader
    println("values: $(row.col1), $(row.col2), $(row.col3)")
end

# Par défaut, les étiquettes `header` figurent en ligne 1, tandis que les délimiteurs `delim` sont des `,`
for row in csvReader
    println("values: $(row.col1), $(row.col2), $(row.col3)")
end

# Ces paramètres peuvent être définis lors du chargement des fichiers. header peut valoir `false`
csvReader = CSV.File("data/file.csv"; header=1, delim=",")
# La convention de Julia est de séparer l’argument clef `key arguments (kwargs)` par un `;`
# toutefois, la `,` fonctionne aussi
csvReader = CSV.File("data/file.csv", header=1, delim=",")


# Trois manières de lire un fichier CSV vers un DataFrame

# Afin de tourner l’objet `CSV.File` en DataFrame, il faut le passer à l’objet `DataFrame.DataFrame`. Il y a trois manières de le faire avec Julia.

df = DataFrame(CSV.File("data/file.csv"))

# utiliser l’opérateur pipe `|>`
df = CSV.File("data/file.csv") |> DataFrame

# Utiliser la fonction `CSV.read()`
df = CSV.read("data/file.csv", DataFrame)


# Encodage des fichiers

# Julia s’attend à ce que les fichiers soient encodés en UTF-8. Il est toutefois possible de préciser l’encodage

DataFrame(CSV.File(open(read,"file_encoding.csv", enc"windows-1250")))
#or
DataFrame(CSV.File(read("file_encoding.csv", enc"windows-1250")))

# Paramètres

# Les paramètres `select=[1,2,3]` permet de sélectionner des colonnes, `drop["col1",:col5]` de spécifier celle à ignorer. Les colonnes sont identifiées par leur ordre. Il est possible d’utiliser les chaînes des identifiants `"col1"` ou des symboles en utilisant le préfix `:` ou encore de les déclarer explicitement `Symbol("col1")`

# Types

# CSV reader infère le type mais celui-ci peut être erroné. Il est possible de spécifier un type avec `type` pour l’ensemble du DataFrame ou avec `types` pour une colonne donnée.




# Dans l’objet `CSV.Row`
data = CSV.File("../../Downloads/dataScience/Magic/magic04.csv")
