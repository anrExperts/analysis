using Random, DataFrames, Distributions, StatsBase
Random.seed!(123)

d = Normal(1,2)

a = Float64
v5 = [sample([0,1,2], pweights([0.2,0.6,0.2])) for i=1:100]

N = 50

df1 = DataFrame(
    x1 = rand(Normal(2,1), N),
    x2 = [sample(["High", "Medium", "Low"],
        pweights([0.25, 0.45, 0.30])) for i = 1:N ],
    x3 = rand(Pareto(2,1), N)
    )

df1[:y] = [df1[i,:x2] == "High" ? *(4, df1[i, :x3]) :
    df1[i,:x2] == "Medium" ? *(2, df1[i, :x3]) :
        *(0.5, df1[i, :x3]) for i=1:N]
