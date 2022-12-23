# ANR experts
# author: @sardinecan
# date: 2022-12
# description: this Julia script creates collection and sends files via the Nakala API
# licence: CC-0

# @todo : gestion des erreurs (réponses server) ?
# @todo : écrire un fichier de log pour récupérer les identifiants des ressources crées.

#%% Upload datas
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames
using HTTP
using JSON
using Dates

path = @__DIR__ # chemin vers le dossier courant
parentDir = dirname(path)

# identifiants
credentials = CSV.read(joinpath(parentDir,"credentials.csv"), DataFrame, header=1) #liste des utilisateurs
user = "jmorvan" #choix de l'utilisateur (api test = nakala)
usrCredentials = filter(:user => n -> n == user, credentials) #récupération des identifiants
apiKey = usrCredentials[1, :apikey] #clé API

# API Nakala
urlFiles = "https://api.nakala.fr/datas/uploads"
urlMeta = "https://api.nakala.fr/datas"
# API test Nakala
#urlFiles = "https://apitest.nakala.fr/datas/uploads" # API test
#urlMeta = "https://apitest.nakala.fr/datas" # API test

# Data upload
include("listFile.jl") # un script qui crée, pour chaque sous-dossier, la liste des images à envoyer.
directories
for directory in directories

  files2upload = CSV.read(joinpath(path, directory, "files.csv"), DataFrame, header=1) # fichier de métadonnées 

  #%% Dépôt des fichiers
  files = Vector()
  for (i, row) in enumerate(eachrow(files2upload))
    filename = row[:filename]
    
    println("Envoi du fichier n°", i, " - ", filename)

    headers = Dict(
      "X-API-KEY" => apiKey, 
      :accept => "application/json"
    )
    
    file = open(joinpath(path, directory, filename), "r")
    body = HTTP.Form(Dict(:file => file))

    fileUpload = HTTP.post(urlFiles, headers, body)
    fileResponse = JSON.parse(String(HTTP.payload(fileUpload)))
    fileIdentifier = fileResponse["sha1"]
    println(fileIdentifier)

    push!(files, fileResponse) # récupération de l'identifiant Nakala du fichier (fileIdentifier) pour le dépot des métadonnées et de la ressource
  end

  # métadonnées de la ressource
  meta = Vector()

  metadata = CSV.read(joinpath(path, "metadata.csv"), DataFrame, header=1) # fichier de métadonnées 

  collections = split(metadata[!, :collections][1], ";")
  authors = split(metadata[!, :authors][1], ";")
  date = metadata[!, :date][1]
  license = metadata[!, :licence][1]
  status = metadata[!, :status][1]
  datatype = metadata[!, :datatype][1]
  description = metadata[!, :description][1]
  keywords = split(metadata[!, :keywords][1], ";")
  datarights = split(metadata[!, :rights][1], ";")

  # titre (obligatoire)
  metaTitle = Dict(
    :value => directory,
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
  for author in authors   
    if length(split(author, ",")) > 1
      identity = split(author, ",")
      metaAuthor = Dict(
        :value => Dict(
          :givenname => identity[2],
          :surname => identity[1]
        ),
        :propertyUri => "http://nakala.fr/terms#creator"
      )
      push!(meta, metaAuthor)
    else
      metaAuthor = Dict(
        :value => Dict(
          :givenname => author,
          :surname => ""
        ),
        :propertyUri => "http://nakala.fr/terms#creator"
      )
      push!(meta, metaAuthor)
    end
  end

  # date (obligatoire, mais accepte la valeur null)    
  metaCreated = Dict(
    :value => Dates.today(),
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :propertyUri => "http://nakala.fr/terms#created"
  )
  push!(meta, metaCreated)
    
  # licence (obligatoire pour une donnée publiée)
  metaLicense = Dict(
    :value => license,
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :propertyUri => "http://nakala.fr/terms#license"
  )
  push!(meta, metaLicense)

  # Droits (facultatif)
  rights = []
  for dataright in datarights
    right = Dict(
      :id => split(dataright, ",")[1],
      :role => split(dataright, ",")[2]
    )
    push!(rights, right)
  end

  # Description (facultatif)
  metaDescription = Dict(
    :value => description,
    :lang => "fr",
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :propertyUri => "http://purl.org/dc/terms/description"
  )
  push!(meta, metaDescription)

  # Mots-clés
  for keyword in keywords
    metaKeyword = Dict(
      :value => keyword,
      :lang => "fr",
      :typeUri => "http://www.w3.org/2001/XMLSchema#string",
      :propertyUri => "http://purl.org/dc/terms/subject"
    )
    push!(meta, metaKeyword)
  end

  # assemblage des métadonnées avant envoi de la ressource
  postdata = Dict(
    :collectionsIds => collections,
    :status => "pending",
    :files => files,
    :metas => meta,
    :rights => rights
  )
  println(JSON.json(postdata))

  headers = Dict(
    "X-API-KEY" => apiKey,
    "Content-Type" => "application/json"
  )
   
  metadataUpload = HTTP.request("POST", urlMeta, headers, JSON.json(postdata))
  metadataResponse = JSON.parse(String(HTTP.payload(metadataUpload))) # réponse du server
  metadataId = metadataResponse["payload"]["id"] # récupération de l'identifiant Nakala de la ressource (identifier)
    
  println(metadataId)
end
