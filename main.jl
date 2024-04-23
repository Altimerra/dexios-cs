include("Interface.jl")

import .Interface

Interface.run()

foreach(x -> println(x), Interface.serialwrite)
foreach(x -> println(x), Interface.serialread)