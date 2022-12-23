using DataFrames
using CSV
using LightGraphs
using HTTP
using LinearAlgebra
#load the CSV data with http get request and build a dataframe
df = CSV.File(HTTP.get("http://localhost:8984/xpr/data/1726").body, header=1) |> DataFrame
describe(df)
#subset of the data without experts label column
df1 = select(df, Not(:label))
#replace values greater than 0 with 1
df1 .= ifelse.(df1 .> 0, 1, df1)
#if we only want to modify one columns (i.e. estimation)
#df1[df1.estimation .> 0,:estimation] .= 1

#make a matrix from our subset dataframe
m = Matrix(df1)
mp = transpose(m) * m
mt = m * transpose(m)
gmp = Graph(mp)
gmt = Graph(mt)
expertName = df.label
gplot(gmt, nodelabel=expertName)
catLabel = names(df1)
gplot(gmp, nodelabel=catLabel)




#-------------------------
#building bipartite graph from dataframe
#test=DataFrame(experts = ["xpr0086","xpr0086","xpr0086","xpr0086","xpr0086", "xpr0221", "xpr0221", "xpr0221", "xpr0221", "Albert", "Albert"], cat = ["Estimer", "Décrire", "Recevoir", "Départager", "Enregistrer", "Estimer", "Décrire", "Recevoir", "Départager", "Recevoir", "Départager"], weights = [2,3,4,1,2,3,4,1,3,4,5])
#mg = MetaGraph(test, :experts, :cat, weight=:weights)

data = CSV.File(HTTP.get("http://localhost:8984/xpr/data/1726").body, header=1) |> DataFrame
#subset of the data without experts label column
data1 = select(df, Not(:label))
#replace values greater than 0 with 1
data1 .= ifelse.(data1 .> 0, 1, data1)
mData = Matrix(data1)
#sum of each rows (the number by which we need to multiply each expert)
data2 = sum(mData, dims=2)
