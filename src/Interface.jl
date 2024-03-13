module Interface
    
include("Webapp.jl")
include("Console.jl")

import .Webapp
import .Console

import Reactive
import JSON

global command, serialread, serialwrite, serialjson, serialall

export command, serialread, serialwrite, serialjson, serialall

function parseJSON(jsonString::String)
    try 
        o = JSON.parse(jsonString);
        return o
    catch e
        println(e)
    end
    return Dict();
end

function run()
    global command = Reactive.Signal("")
    global serialread = Reactive.Signal("")
    global serialwrite = Reactive.Signal("")
    global serialjson = Reactive.map(parseJSON, serialread, typ=Dict)
    global serialall = Reactive.foldp(push!, [], serialjson)

    Webapp.app(command)

    @async Console.console("COM7", "9600", serialread, serialwrite)

    foreach(x->Reactive.push!(serialwrite, x), command)
end







#filter the signal for empty values



#y = Reactive.foreach(+, x, xsquared; typ=Float64, init=0)

#

#sleep(0.05)

#push!(serialwrite, JSON.json(Dict("command"=>"LED", "value"=>"1")))

#sleep(0.05)

#push!(serialwrite, JSON.json(Dict("command"=>"LED", "value"=>"2")))

end