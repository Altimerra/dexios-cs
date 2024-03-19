module Interface

include("Webapp.jl")
include("Console.jl")

import .Webapp
import .Console

import Reactive
import JSON


function parseJSON(jsonString::String)
    try
        o = JSON.parse(jsonString)
        return o
    catch e
        println(e)
    end
    return Dict()
end

command = Reactive.Signal("")
serialread = Reactive.Signal("")
serialwrite = Reactive.Signal("")
serialjson = Reactive.map(parseJSON, serialread, typ=Dict)
serialall = Reactive.foldp(push!, [], serialjson)


function run()

    Webapp.app(command)

    @async Console.console("COM7", "9600", serialread, serialwrite)

    foreach(x -> Reactive.push!(serialwrite, x), command)
end

export command, serialread, serialwrite, serialjson, serialall






#filter the signal for empty values



#y = Reactive.foreach(+, x, xsquared; typ=Float64, init=0)

#

#sleep(0.05)

#push!(serialwrite, JSON.json(Dict("command"=>"LED", "value"=>"1")))

#sleep(0.05)

#push!(serialwrite, JSON.json(Dict("command"=>"LED", "value"=>"2")))

end