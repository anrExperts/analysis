using Random
using http

x = 3
y = 6
typeof(y)
f(x) = 2 + x
f
f(10)
function g(x, y)
    z = x + y
    return z^2
end
2^2

g(1,2)
let s = 0
    for i in 1:10
        s+= i
    end
    s
end
function mysum(n)
    s = 0
    for i in 1:n
        s += i
    end
    return s
end

mysum(100)
a = 3
a < 5

v = [1, 2, 3]

typeof(v)

v[2]
v[2] = 10
v[2]

v2 = [i^2 for i in 1:10]
M = [1 2
     3 4]

typeof(M)
zeros(5, 5)

zeros(Int, 4, 5)
[1:10; ]
[1:10]
[1:10; ]
x = y = z = 1
x
y
0 < x ≠ 3
5 < x != y < 5
function add_one(i)
    return i + 1
end
add_one(9)

3/2
3%2
3÷2
7\3
[1, 2, 3] .+ [1, 2, 3]
x = [1, 2, 3] .+ [1, 2, 3]
println(x)
M1 = [1 2
     3 4]

M2 = [1 2
      3 4]
M1 .+ M2
M3 = M1 .+ M2
println(M3)
M4 = M1 .* M2
println(M4)

a = 1
b = 2

a == 2 ? "equal" : "not"
str = "Learn" * " " * "Julia"
str = "learn"^3

N = 8
N ∈ [8, 16, 32, 64, 128]
pi
π

M = [1 2
     3 4]

M = [1 2; 3 4]
ℯ^5

typeof(ans)

log(7)
Bernoulli(p)=(-1+2*(rand()<p))
Bernoulli(233)

mutable struct Personna
    nom::String
    prenom::String
    age::Int64
end

nouveau = Personna("Pan", "Peter", 33)
nouveau.age+=1

a = [
]
b=["un", "deux"]
c=["trois"]

v=[a;b;c]
println(v)
