import CSV;
import DataFrames;
import Random;
import Distributions;
import StatsBase;
import Statistics

# CSV.File("../../Downloads/beers/beers.csv") |> DataFrame

Random.seed!(825)
N = 50

df1 = DataFrame(
    x1 = rand(Normal(2,1), N),
    x2 = [sample(["High", "Medium", "Low"],
        pweights([0.25, 0.45, 0.30])) for i = 1:N ],
    x3 = rand(Pareto(2,1), N)
    )
