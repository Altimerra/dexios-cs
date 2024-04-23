module App
import Reactive as Rx
import JSON
using GenieFramework
@genietools

appsignal = Rx.Signal("")

function update(data)
    dict = Dict("action"=>"setval","data" => Dict("mix"=>data))
    push!(appsignal, JSON.json(dict))
    data = 0
end

@app begin
    @in refresh = false
    @in mix::Union{Int64,Nothing} = nothing
    @in mmd::Union{Int64,Nothing} = nothing
    @in mrl::Union{Int64,Nothing} = nothing
    @in mtf::Union{Int64,Nothing} = nothing
    @in mto::Union{Int64,Nothing} = nothing
    @in six::Union{Bool,Nothing} = nothing
    @in smd::Union{Bool,Nothing} = nothing
    @onchange refresh begin
        dict = Dict("action"=>"setval","data" => Dict())
        dict["data"]["mix"] = mix 
        mix = nothing
        dict["data"]["mmd"] = mmd 
        mmd = nothing
        dict["data"]["mrl"] = mrl 
        mrl = nothing
        dict["data"]["mtf"] = mtf 
        mtf = nothing
        dict["data"]["mto"] = mto 
        mto = nothing
        dict["data"]["six"] = six 
        six = nothing
        dict["data"]["smd"] = smd 
        smd = nothing

        push!(appsignal, JSON.json(dict))
    end
end

function manual()
    [
        cell([
            textfield("Motor index", :mix),
            textfield("Motor middle", :mmd),
            textfield("Motor ring+little", :mrl),
            textfield("Motor thumb flex", :mtf),
            textfield("Motor thumb opp", :mto),
            textfield("Solenoid index", :six),
            textfield("Solenoid middle", :smd),
            btn("Update", color = "primary", @click("refresh = !refresh"))
        ])
    ]
end

@page("/manual", manual)

export appsignal
end