#%% Packages
# alt + enter (⌥ + ↵) to execute cells
using CSV
using DataFrames
using HTTP
using JSON
using Dates

#%% credentials
path = @__DIR__
credentials = CSV.read(joinpath(path,"credentials.csv"), DataFrame, header=1) #liste des utilisateurs
user = "jmorvan" #choix de l'utilisateur (api test = nakala)
usrCredentials = filter(:user => n -> n == user, credentials) #récupération des identifiants
apiKey = usrCredentials[1, :apikey] #clé API

#%% Création d'une collection
collectionName = "collection"

headers = Dict(
  "X-API-KEY" => apiKey,
  "Content-Type" => "application/json"
)

body = Dict(
  :status => "private",
  :metas =>  [Dict(
    :value => collectionName,
    :propertyUri => "http://nakala.fr/terms#title",
    :typeUri => "http://www.w3.org/2001/XMLSchema#string",
    :lang => "fr"
  )]
)

postCollection = HTTP.request("POST", "https://api.nakala.fr/collections", headers, JSON.json(body)) # envoi des données pour la création de la collection
collectionResponse = JSON.parse(String(HTTP.payload(postCollection))) # réponse du server
collectionId = collectionResponse["payload"]["id"] # récupération de l'id de la collection
println("Identifiant collection : ", collectionId)

#%% Récupération des informations utilisateur
headers = Dict(
  "X-API-KEY" => apiKey,
  "Content-Type" => "application/json"
)
userInfo = HTTP.request("GET", "https://api.nakala.fr/users/me", headers)
userInfoResponse = JSON.parse(String(HTTP.payload(userInfo))) # réponse du server
username = userInfoResponse["username"]
userGroupId = userInfoResponse["userGroupId"]


#%% Récupération des ressources accessibles par un utilisateur

scope = ["deposited", "owned", "shared", "editable", "readable", "all"]
#deposited : les données déposées par l'utilisateur (ROLE_DEPOSITOR)
#owned : les données dont l'utilisateur est propriétaire (ROLE_OWNER)
#shared : les données partagées avec l'utilisateur (ROLE_ADMIN, ROLE_EDITOR ou ROLE_READER, mais pas ROLE_OWNER)
#editable : les données modifiables par l'utilisateur (ROLE_OWNER, ROLE_ADMIN ou ROLE_EDITOR)
#readable : les données lisibles par l'utilisateur (ROLE_OWNER, ROLE_ADMIN, ROLE_EDITOR ou ROLE_READER)
#all : toute
s = scope[1]
url = joinpath("https://api.nakala.fr/users/datas", s)

headers = Dict(
  "X-API-KEY" => apiKey,
  "Content-Type" => "application/json"
)
userDatas = HTTP.request("POST", url, headers)
userDatasResponse = JSON.parse(String(HTTP.payload(userDatas))) # réponse du server