include("Interface.jl")

import .Interface
import JSON

Interface.run()

sleep(0.05)

push!(Interface.serialwrite, JSON.json(Dict("command"=>"LED", "value"=>"1")))

sleep(0.05)

push!(Interface.serialwrite, JSON.json(Dict("command"=>"LED", "value"=>"2")))