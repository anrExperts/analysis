# Variables, naming conventions, etc.
x = 5
typeof(x)
y = "string"
typeof(y)
x + y
y = 3.5; x + y
# Julia se comporte comme un langage dynamiquement typé. Une variable d’abord reliée à un entier, peut ensuite être reliée à une chaîne de charactères
x = 10
x = "hello"
# Il est toutefois possible d’ajouter des informations de type à une variable. Cela contraint les valeurs possibles pour cette variable avec `::`, par exemple dans la définition d’une fonction.
# Julia utilise la même syntaxe pour l’assertion de types
(2+3)::String
3::String
isa(1, Bool)
email_pattern = r".+@.+"
input = "john.doe@mit.edu"
println(occursin(email_pattern, input)) #> true
match(email_pattern, input)
email_pattern = r"(.+)@(.+)"
str = "The sky is blue"
reg = r"[\w]{3,}" # matches words of 3 chars or more
r = collect((m.match for m = eachmatch(reg, str)))
show(r) #> ["The","sky","blue"]
iter = eachmatch(reg, str)
for i in iter
    println("\"$(i.match)\" ")
end
arr = [1, 2, 3]
arr .+ 2
arr * 2

# Fonctions

function λ(x, y)
    println("x is $x and y is $y")
    return x * y
end
λ(3,4)
function mult(x, y)
       println("x is $x and y is $y")
       if x == 1
           return y end
           x* y
end
mult(2, 3)
function multi(n, m)
    n*m, div(n, m), n%m
end
multi(3, 4)
