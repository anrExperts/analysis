using HTTP
url = "https://apitest.nakala.fr/datas/uploads"
headers = 
    Dict(
        "X-API-KEY" => "01234567-89ab-cdef-0123-456789abcdef", 
        "accept" => "application/json"
    )

fileOpened = open("/Users/josselinmorvan/files/dh/xpr/analysis/julia/lot/No_man_is_an_island.txt", "r")    

body = HTTP.Form(Dict(:file => fileOpened))

fileCur = Dict("file" => fileOpened)

response = HTTP.post(url, headers=headers, body=body)


