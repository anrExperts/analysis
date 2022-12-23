# ANR experts
# author: @sardinecan
# date: 2022-12
# description: this Julia script creates a csv file with metadata for each file in a folder
# licence:

#%% Packages
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames
using Dates

#%% 
path = @__DIR__

for (root, dirs, files) in walkdir(path)
  for dir in dirs
    touch(joinpath(root, dir, "testMeta.csv"))
    f = open(joinpath(root, dir, "testMeta.csv"), "w")
      write(f, "filename,title,collection,author,date,licence,status,datatype")
    close(f)

    listFile = readdir(dir)

    collection = dir
    author = "projetExperts"
    date = "2022-12-22"
    licence = "CC"
    status = "pending"
    datatype = "http://purl.org/coar/resource_type/c_c513"

    for file in listFile
      if contains(file, "DS_Store")

      else
        posExt = findlast(isequal('.'),file)
        title = SubString(file, 1, posExt-1)
    
          println(title)
    
          f = open(joinpath(root, dir, "testMeta.csv"), "a")
            write(f, "\n"*file*","*title*","*collection*","*author*","*date*","*licence*","*status*","*datatype)
          close(f)
      end
    end
  end
end