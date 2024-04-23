module Interface

#include("Webapp.jl")
include("Console.jl")

#import .Webapp
import .Console

import Reactive
import JSON
import GenieFramework


function parseJSON(jsonString::String)
    try
        o = JSON.parse(jsonString)
        return o
    catch e
        println(e)
    end
    return Dict()
end

#command = Reactive.Signal("")
serialread = Reactive.Signal("")
serialwrite = Reactive.Signal("")
serialjson = Reactive.map(parseJSON, serialread, typ=Dict)
serialall = Reactive.foldp(push!, [], serialjson)


function run()
    GenieFramework.Genie.loadapp()
    GenieFramework.Server.isrunning() || GenieFramework.up(async=true)
    @async Console.console("COM7", "9600", serialread, serialwrite)
    foreach(x -> Reactive.push!(serialwrite, x), Main.App.appsignal)
end

export serialread, serialwrite, serialjson, serialall

end