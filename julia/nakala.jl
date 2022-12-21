#
#
#
#
#


#%% Packages
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames
using HTTP
using JSON


#%% variables
apiKey = "" # À obtenir dans l'onglet "mon profil" sur Nakala.fr
#apiKey = "01234567-89ab-cdef-0123-456789abcdef" # API test

collectionName = "Z1J432" # nom de la collection 
path = "/Users/josselinmorvan/files/dh/xpr/analysis/julia/Z1J431" # chemin vers les documents à déposer sur Nakala
#normalisation du chemin
path =  if endswith(path, "/") path
        else path*"/"
        end
metadata = CSV.File(path*"metadata.csv", header=1) |> DataFrame # fichier de métadonnées

urlCollections = "https://api.nakala.fr/collections"
urlFiles = "https://api.nakala.fr/datas/uploads"
urlMeta = "https://api.nakala.fr/datas"

#urlCollections = "https://apitest.nakala.fr/collections" # API test
#urlFiles = "https://apitest.nakala.fr/datas/uploads" # API test
#urlMeta = "https://apitest.nakala.fr/datas"




#%% Création de la collection
headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
)

body = Dict(
    :status => "public",
    :metas =>  [
        Dict(
            :value => collectionName,
            :propertyUri => "http://nakala.fr/terms#title",
            :typeUri => "http://www.w3.org/2001/XMLSchema#string",
            :lang => "fr"
        )
    ]
)

collectionRequest = HTTP.request("POST", urlCollections, headers, JSON.json(body)) # envoi des données pour la création de la collection
collectionResponse = JSON.parse(String(HTTP.payload(collectionRequest))) # réponse du server
collectionId = collectionResponse["payload"]["id"] # récupération de l'id de la collection
println("Identifiant collection : ", collectionId)



#%% Dépôt des fichiers

for (i, row) in enumerate( eachrow( metadata ) )
    println("Envoi du fichier n°", i)
    
    # récupération des métadonnées pour chaque fichier
    filename = row[1]
    title = row[2]
    author = row[3]
    date = row[4]
    license = row[5]
    status = row[6]
    datatype = row[7]

    ## dépôt du fichier du Nakala
    headers = Dict(
        "X-API-KEY" => apiKey, 
        :accept => "application/json"
    )
    
    file = open(path*filename, "r")    
    body = HTTP.Form(Dict(:file => file))

    sendFile = HTTP.post(urlFiles, headers=headers, body=body)
    fileResponse = JSON.parse(String(HTTP.payload(sendFile)))
    
    files = Vector() 
    push!(files, fileResponse) # récupération de l'identifiant du fichier pour le dépot des métadonnées

    ## gestion des métadonnées du fichier
    meta = Vector()

    # titre (obligatoire)
    metaTitle = Dict(
        :value => title,
        :typeUri => "http://www.w3.org/2001/XMLSchema#string",
        :propertyUri => "http://nakala.fr/terms#title"
    )
    push!(meta, metaTitle)

    # datatype (obligatoire)
    metaType = Dict(
        :value => datatype,
        :typeUri => "http://www.w3.org/2001/XMLSchema#anyURI",
        :propertyUri => "http://nakala.fr/terms#type"
    )
    push!(meta, metaType)

    # authorité/creator (obligatoire, mais accepte la valeur null)
    metaAuthor = Dict(
        :value => Dict(
            :givenname => author,
            :surname => ""
        ),
        :propertyUri => "http://nakala.fr/terms#creator"
    )
    push!(meta, metaAuthor)

    # data (obligatoire, mais accepte la valeur null)    
    metaCreated = Dict(
        :value => date,
        :typeUri => "http://www.w3.org/2001/XMLSchema#string",
        :propertyUri => "http://nakala.fr/terms#created"
    )
    
    push!(meta, metaCreated)
    
    # licence (obligatoire pour une donnée publiée)
    metaLicense = Dict(
        :value => "CC-BY-4.0",
        :typeUri => "http://www.w3.org/2001/XMLSchema#string",
        :propertyUri => "http://nakala.fr/terms#license"
    )
    push!(meta, metaLicense)


    postdata = Dict(
        :status => status,
        :files => files,
        :metas => meta
    )
    println(JSON.json(postdata))

    headers = Dict(
        "X-API-KEY" => apiKey,
        "Content-Type" => "application/json"
    )
    
    response = HTTP.request("POST", urlMeta, headers, JSON.json(postdata))
    
    println(response)

end 

# @todo : gestion des erreurs (réponses server) + ajouter la collection dans les métadonnées
# @quest : envoyer toutes les métadonnées en même temps ? 