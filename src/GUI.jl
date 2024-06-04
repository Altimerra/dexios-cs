module GUI
using Mousetrap
using Mosquitto
import Reactive as Rx
import JSON

client = Client("localhost", 1883) 
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
)

function pubmsg(topic,message)
    publish(client, topic, message)
    loop(client)
end

const scaleSize = 300

function setspeed(value)
    return floor(Int, 5.1 * (value - 50)) |> string
end

function setsetpoint(value)
    return floor(Int, 120 * (value)) |> string
end

scalerfunc = setsetpoint


main() do app::Application
    set_current_theme!(app, THEME_DEFAULT_DARK)
    window = Window(app)
    paned = Paned(ORIENTATION_HORIZONTAL)
    grid = Grid()
    box = Box(ORIENTATION_VERTICAL)

    dropdown = DropDown()
    set_margin!(dropdown, 10)
    graspselect = DropDown()
    set_margin!(graspselect, 10)
    set_is_visible!(graspselect, false)

    set_start_child!(paned, box)
    set_end_child!(paned, grid)

    push_back!(box, dropdown)
    push_back!(box, graspselect)

    push_back!(dropdown, "Reset") do self::DropDown
        set_is_visible!(mix, true)
        set_is_visible!(mmd, true)
        set_is_visible!(mrl, true)
        set_is_visible!(mtf, true)
        set_is_visible!(mto, true)
        set_is_visible!(six, true)
        set_is_visible!(smd, true)
        set_is_visible!(graspselect, false)
        return nothing
    end
    push_back!(dropdown, "PID") do self::DropDown
        global scalerfunc = setsetpoint
        set_value!(mix, 0)
        set_value!(mmd, 0)
        set_value!(mrl, 0)
        set_value!(mtf, 0)
        set_value!(mto, 0)
        pubmsg(topic["mode"], "pid")
        return nothing
    end
    push_back!(dropdown, "Manual") do self::DropDown
        global scalerfunc = setspeed
        set_value!(mix, 50)
        set_value!(mmd, 50)
        set_value!(mrl, 50)
        set_value!(mtf, 50)
        set_value!(mto, 50)
        pubmsg(topic["mode"], "manual")
        return nothing
    end
    push_back!(dropdown, "Grasp") do self::DropDown
        set_is_visible!(mix, false)
        set_is_visible!(mmd, false)
        set_is_visible!(mrl, false)
        set_is_visible!(mtf, false)
        set_is_visible!(mto, false)
        set_is_visible!(six, false)
        set_is_visible!(smd, false)
        set_is_visible!(graspselect, true)
        pubmsg(topic["mode"], "grasp")
        return nothing
    end

    push_back!(graspselect, "None") do self::DropDown
        return nothing
    end
    push_back!(graspselect, "Pinch") do self::DropDown
        #dict = Dict("action" => "graspsel", "data" => "pinch")
        #put!(channel, JSON.json(dict))
        pubmsg(topic["grasp"], "pinch")
        return nothing
    end
    push_back!(graspselect, "Spherical") do self::DropDown
        #dict = Dict("action" => "graspsel", "data" => "spherical")
        #put!(channel, JSON.json(dict))
        pubmsg(topic["grasp"], "spherical")
        return nothing
    end

    mix = Scale(0, 100, 1)
    set_margin!(mix, 10)
    set_expand_horizontally!(mix, true)
    set_size_request!(mix, Vector2f(scaleSize, 0))
    mix_label = Label("Motor Index")
    connect_signal_value_changed!(mix) do self::Scale
        value = scalerfunc(get_value(self))
        #dict = Dict("action" => commandString, "data" => Dict("mix" => value))
        #put!(channel, JSON.json(dict))
        pubmsg(topic["mix"], value)
        return nothing
    end
    mix_reset = # TODO add button to reset to zero level
        mmd = Scale(0, 100, 1)
    set_margin!(mmd, 10)
    set_size_request!(mmd, Vector2f(scaleSize, 0))
    mmd_label = Label("Motor Middle")
    connect_signal_value_changed!(mmd) do self::Scale
        value = scalerfunc(get_value(self))
        #dict = Dict("action" => commandString, "data" => Dict("mmd" => value))
        #put!(channel, JSON.json(dict))
        pubmsg(topic["mmd"], value)
        return nothing
    end

    mtf = Scale(0, 100, 1)
    set_margin!(mtf, 10)
    set_size_request!(mtf, Vector2f(scaleSize, 0))
    mtf_label = Label("Motor Thumb Flex")
    connect_signal_value_changed!(mtf) do self::Scale
        value = scalerfunc(get_value(self))
        #dict = Dict("action" => commandString, "data" => Dict("mtf" => value))
        #put!(channel, JSON.json(dict))
        pubmsg(topic["mtf"], value)
        return nothing
    end

    mto = Scale(0, 100, 1)
    set_margin!(mto, 10)
    set_size_request!(mto, Vector2f(scaleSize, 0))
    mto_label = Label("Motor Thumb Opp")
    connect_signal_value_changed!(mto) do self::Scale
        value = scalerfunc(get_value(self))
        #dict = Dict("action" => commandString, "data" => Dict("mto" => value))
        #put!(channel, JSON.json(dict))
        pubmsg(topic["mto"], value)
        return nothing
    end

    mrl = Scale(0, 100, 1)
    set_margin!(mrl, 10)
    set_size_request!(mrl, Vector2f(scaleSize, 0))
    mrl_label = Label("Motor Ring/Little")
    connect_signal_value_changed!(mrl) do self::Scale
        value = scalerfunc(get_value(self))
        #dict = Dict("action" => commandString, "data" => Dict("mrl" => value))
        #put!(channel, JSON.json(dict))
        pubmsg(topic["mrl"], value)
        return nothing
    end

    six = Switch()
    set_margin!(six, 10)
    six_label = Label("Solenoid Index")
    set_alignment!(six, ALIGNMENT_CENTER)
    connect_signal_switched!(six) do self::Switch
        value = get_is_active(self) |> string
        #dict = Dict("action" => "setval", "data" => Dict("six" => value)) # TODO setval nolonger available
        #put!(channel, JSON.json(dict))
        pubmsg(topic["six"], value)
        return nothing
    end

    smd = Switch()
    set_margin!(smd, 10)
    smd_label = Label("Solenoid Index")
    set_alignment!(smd, ALIGNMENT_CENTER)
    connect_signal_switched!(smd) do self::Switch
        value = get_is_active(self) |> string
        #dict = Dict("action" => "setval", "data" => Dict("smd" => value))
        #put!(channel, JSON.json(dict))
        pubmsg(topic["smd"], value)
        return nothing
    end

    insert_at!(grid, mix_label, 1, 1, 1, 1)
    insert_at!(grid, mix, 2, 1, 20, 1)
    insert_at!(grid, mmd_label, 1, 2, 1, 1)
    insert_at!(grid, mmd, 2, 2, 20, 1)
    insert_at!(grid, mrl_label, 1, 5, 1, 1)
    insert_at!(grid, mrl, 2, 5, 20, 1)
    insert_at!(grid, mtf_label, 1, 3, 1, 1)
    insert_at!(grid, mtf, 2, 3, 20, 1)
    insert_at!(grid, mto_label, 1, 4, 1, 1)
    insert_at!(grid, mto, 2, 4, 20, 1)
    insert_at!(grid, six_label, 1, 6, 1, 1)
    insert_at!(grid, six, 2, 6, 1, 1)
    insert_at!(grid, smd_label, 1, 7, 1, 1)
    insert_at!(grid, smd, 2, 7, 1, 1)

    set_margin!(grid, 10)
    set_child!(window, paned)
    present!(window)
end
disconnect(client)
end