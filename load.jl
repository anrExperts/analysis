using HTTP;
using JSON;
r = HTTP.request("GET", "https://api.hypothes.is/api/groups")
println(r.status)

stringdata = String(r.body)
JSON.parse(stringdata)
