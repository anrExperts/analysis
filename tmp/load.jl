using HTTP;
using JSON;
using JSON3;
r = HTTP.request("GET", "https://api.hypothes.is/api/groups")
println(r.status)

stringdata = String(r.body)
JSON.parse(stringdata)

eng2sp = Dict()
eng2sp["one"] = "uno";
eng2sp
eng2sp = Dict("one" => "uno", "two" => "dos", "three" => "tres")

print(keys(eng2sp);)
"one" ∈ keys(eng2sp)

resp = JSON.parse(stringdata)


function printhist(arg)
    for item in keys(arg)
        println(item, " : ", arg[item] )
    end
end

printhist(resp[1])

println(JSON.parse(stringdata))

dic1 = resp[1]

println(iterate(dic1))

files = ["a.txt", "b.txt", "c.txt"]
fvars = Dict()
for (n, f) in enumerate(files)
   fvars["x_$(n)"] = f
end
x = Dict("1"=>"a")

req = HTTP.request("GET", "https://jsonplaceholder.typicode.com/posts")
data = JSON.parse(String(req.body))
data[1]
data = JSON3.read(req.body)
