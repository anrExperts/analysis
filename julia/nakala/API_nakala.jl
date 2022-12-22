


h = Dict(
    "X-API-KEY" => apiKey,
    "accept" => "application/json"
)

getDatas = HTTP.request("GET", "https://api.nakala.fr/datas/uploads", h) # envoi des données pour la création de la collection