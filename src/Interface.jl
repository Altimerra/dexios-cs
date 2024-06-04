module Interface
using LibSerialPort
using Reactive
using JSON
using Mosquitto
using Match

topic = Dict(
    "mix" => "dexioscs/value/mix",
    "mmd" => "dexioscs/value/mmd",
    "mrl" => "dexioscs/value/mrl",
    "mtf" => "dexioscs/value/mtf",
    "mto" => "dexioscs/value/mto",
    "six" => "dexioscs/value/six",
    "smd" => "dexioscs/value/smd",
    "mode" => "dexioscs/mode",
    "grasp" => "dexioscs/grasp",
    "exit" => "dexioscs/exit",
)

serialread = Signal("")
serialwrite = Signal("")
#serialjson = map(parseJSON, serialread, typ=Dict)
#serialall = foldp(push!, [], serialjson)

exit = true

function serial_loop(sp::SerialPort, instream::Signal{String}, outstream::Signal{String})
    user_input = ""
    mcu_message = ""

    println("Starting I/O loop. Press ESC [return] to quit")

    foreach(x->write(sp, x), outstream)

    while true
        # Poll for new data without blocking
        #@async user_input = readline(keep=true)
        @async mcu_message *= String(nonblocking_read(sp))

        occursin("\e", user_input) && exit()  # escape

        # Send user input to device with ENTER
        #if endswith(user_input, '\n')
        #    write(sp, "$user_input")
        #    user_input = ""
        #end

        
        #foreach(x->println(x), outstream)

        # Print response from device as a line
        if occursin("\n", mcu_message)
            lines = split(mcu_message, "\n")
            while length(lines) > 1
                #println(popfirst!(lines))
                push!(instream, popfirst!(lines))
            end
            mcu_message = lines[1]
        end

        # Give the queued tasks a chance to run
        sleep(0.001)
    end
end

function console(args...)

    if length(args) < 2
        println("Usage: $(basename(@__FILE__)) port baudrate")
        println("Available ports:")
        list_ports()
        return
    end

    # Open a serial connection to the microcontroller
    mcu = open(args[1], parse(Int, args[2]))

    serial_loop(mcu, args[3], args[4])
end

function onconnect(client)
    # Check if something happened, else return 0
    nmessages = Base.n_avail(get_connect_channel(client))
    nmessages == 0 && return 0

    # At this point, a connection or disconnection happened
    for _ = 1:nmessages
        conncb = take!(get_connect_channel(client))
        if conncb.val == 1
            println("Connection of client $(client.id) successfull (return code $(conncb.returncode))")
            map(t->subscribe(client, t), values(topic))
        elseif conncb.val == 0
            println("Client $(client.id) disconnected")
        end
    end
    return nmessages
end

function onmessage(client)
    # Check if something happened, else return 0
    nmessages = Base.n_avail(get_messages_channel(client))
    nmessages == 0 && return 0

    # At this point, a message was received, lets process it
    for i = 1:nmessages
        temp = take!(get_messages_channel(client))
        if (temp.topic == topic["exit"] && String(temp.payload) == "yes")
            global exit = false
        end
        
        handlemsg(temp)
    end
    return nmessages
end

function parseJSON(jsonString::String)
    try
        o = parse(jsonString)
        return o
    catch e
        println(e)
    end
    return Dict()
end

function actstring(actuator, value)
    dict = Dict("action" => "setval", "val" => value, "actuator" => actuator)
    return json(dict)
end

function modestring(value)
    dict = Dict("action" => "modesel", "val" => value)
    return json(dict)
end

function graspstring(value)
    dict = Dict("action" => "graspsel", "val" => value)
    return json(dict)
end

function nothingstring()
    dict = Dict("action" => "none")
    return json(dict)
end

function handlemsg(msg)
    str = @match msg.topic begin
        "dexioscs/value/mix" => actstring("mix", parse(Int64, String(msg.payload)))
        "dexioscs/value/mmd" => actstring("mmd", parse(Int64, String(msg.payload)))
        "dexioscs/value/mrl" => actstring("mrl", parse(Int64, String(msg.payload)))
        "dexioscs/value/mtf" => actstring("mtf", parse(Int64, String(msg.payload)))
        "dexioscs/value/mto"=> actstring("mto", parse(Int64, String(msg.payload)))
        "dexioscs/value/six" => actstring("six", parse(Bool, String(msg.payload)))
        "dexioscs/value/smd" => actstring("smd", parse(Bool, String(msg.payload)))
        "dexioscs/mode" => modestring(String(msg.payload))
        "dexioscs/grasp" => graspstring(String(msg.payload))
        _ => nothingstring()
    end
    #push!(serialwrite, str)
    push!(serialwrite, str)
end

function main()
    # Connect to a broker
    client = Client("localhost", 1883)   
    @async console("COM10", "115200", serialread, serialwrite)
    # Messages will be put as a tuple in
    # the channel Mosquitto.messages_channel.
    

    @async while exit
        loop(client) # network loop
        onconnect(client) # check for connection/disconnection
        onmessage(client) # check for messages
        sleep(0.001)
    end

    # Close everything
    #disconnect(client)
    #loop(client)
    foreach(x -> println(x), serialread)
end

export main
end

Interface.main()
# TODO write new loop incorporating serial, ditch Reactive