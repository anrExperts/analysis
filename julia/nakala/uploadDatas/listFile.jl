# ANR experts
# author: @sardinecan
# date: 2022-12
# description: this Julia script creates a csv file that lists files for each folder
# licence:

#%% Packages
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames

#%% 
path = @__DIR__

directories = []
for (root, dirs, files) in walkdir(path)
  for dir in dirs
    touch(joinpath(root, dir, "files.csv"))
    f = open(joinpath(root, dir, "files.csv"), "w")
      write(f, "filename")
    close(f)

    println(dir)
    push!(directories, dir)

    list = readdir(joinpath(root, dir))

    extentions = [".tiff", ".tif", ".jpg", "jpeg", ".png", ".txt"]

    for file in list
      for extention in extentions
        if endswith(lowercase(file), extention)
          f = open(joinpath(root, dir, "files.csv"), "a")
            write(f, "\n"*file)
          close(f)
        end
      end
    end
  end
end