# ANR experts
# author: @sardinecan
# date: 2022-12
# description: this Julia script creates collection and sends files via the Nakala API
# licence:

#%% Packages
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames
using HTTP
using JSON


#%% variables
path = @__DIR__ # chemin vers le dossier courant

# identifiants
credentials = CSV.File(path*"/credentials.csv", header=1) |> DataFrame #liste des utilisateurs
user = "jmorvan" #choix de l'utilisateur (api test = nakala)
usrCredentials = filter(:user => n -> n == user, credentials) #récupération des identifiants

apiKey = usrCredentials[1, :apikey] #clé API


# fichiers/collection
# /!\ Une collection publique ne peut contenir que des données publiées /!\
# les fichiers à envoyer sont placés dans un sous dossier lot
metadata = CSV.File(path*"/lot/metadata.csv", header=1) |> DataFrame # fichier de métadonnées 
collectionName = metadata[1,:collection] # nom de la collection (les fichiers d'un même lot appartiennent à la même collection)

# création d'un fichier csv de synthèse
touch(path*"/lot/"*collectionName*".csv")
f = open(path*"/lot/"*collectionName*".csv", "w") 
    write(f, "title,identifier,fileIdentifier")
close(f)

# API Nakala
urlCollections = "https://api.nakala.fr/collections"
urlFiles = "https://api.nakala.fr/datas/uploads"
urlMeta = "https://api.nakala.fr/datas"

# API test Nakala
#urlCollections = "https://apitest.nakala.fr/collections" # API test
#urlFiles = "https://apitest.nakala.fr/datas/uploads" # API test
#urlMeta = "https://apitest.nakala.fr/datas" # API test


#%% Création de la collection
headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
)

body = Dict(
    :status => "private",
    :metas =>  [
        Dict(
            :value => collectionName,
            :propertyUri => "http://nakala.fr/terms#title",
            :typeUri => "http://www.w3.org/2001/XMLSchema#string",
            :lang => "fr"
        )
    ]
)

postCollection = HTTP.request("POST", urlCollections, headers, JSON.json(body)) # envoi des données pour la création de la collection
collectionResponse = JSON.parse(String(HTTP.payload(postCollection))) # réponse du server
collectionId = collectionResponse["payload"]["id"] # récupération de l'id de la collection
println("Identifiant collection : ", collectionId)

f = open(path*"/lot/"*collectionName*".csv", "a") 
    write(f, "\ncollection,"*collectionId*",")
close(f)



#%% Dépôt des fichiers

for (i, row) in enumerate( eachrow( metadata ) )
    println("Envoi du fichier n°", i)
    
    # récupération des métadonnées pour chaque fichier
    filename = row[:filename]
    title = row[:title]
    author = row[:author]
    date = row[:date]
    license = row[:licence]
    status = row[:status]
    datatype = row[:datatype]

    ## dépôt du fichier du Nakala
    headers = Dict(
        "X-API-KEY" => apiKey, 
        :accept => "application/json"
    )
    
    file = open(path*"/lot/"*filename, "r")    
    body = HTTP.Form(Dict(:file => file))

    fileUpload = HTTP.post(urlFiles, headers=headers, body=body)
    fileResponse = JSON.parse(String(HTTP.payload(fileUpload)))
    fileIdentifier = fileResponse["sha1"]
    println(fileIdentifier)

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
        :collectionsIds => [collectionId],
        :status => status,
        :files => files,
        :metas => meta
    )
    println(JSON.json(postdata))

    headers = Dict(
        "X-API-KEY" => apiKey,
        "Content-Type" => "application/json"
    )
    
    metadataUpload = HTTP.request("POST", urlMeta, headers, JSON.json(postdata))
    metadataResponse = JSON.parse(String(HTTP.payload(metadataUpload))) # réponse du server
    metadataId = metadataResponse["payload"]["id"] # récupération de l'id de la collection
    
    println(metadataId)

    f = open(path*"/lot/"*collectionName*".csv", "a") 
        write(f, "\n"*filename*","*metadataId*","*fileIdentifier)
    close(f)


end 

# @todo : gestion des erreurs (réponses server) ?