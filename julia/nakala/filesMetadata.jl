# ANR experts
# author: @sardinecan
# date: 2022-12
# description: this Julia script creates a metadate file
# licence:

#%% Packages
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames

#%% 
path = @__DIR__

touch(path*"/testMeta.csv")
f = open(path*"/testMeta.csv", "w")
    write(f, "filename,title,collection,author,date,licence,status,datatype")
close(f)

for (root, dirs, files) in walkdir(path)
    println("Directories in $root")
    for dir in dirs
        println(joinpath(root, dir)) # path to directories
    end
    println("Files in $root")
    for file in files
        println(joinpath(root, file)) # path to files
    end
end

filesList = readdir(path)

collection = 

for file in filesList
println(file)
end