module GUI
using Mousetrap
import Reactive as Rx
import JSON

appsignal = Rx.Signal("")
foreach(x -> println(x), appsignal)

const scaleSize = 300
scaler = 120

main() do app::Application
    set_current_theme!(app, THEME_DEFAULT_DARK)
    window = Window(app)
    paned = Paned(ORIENTATION_HORIZONTAL)
    grid = Grid()
    box = Box(ORIENTATION_VERTICAL)
    dropdown = DropDown()

    set_start_child!(paned, box)
    set_end_child!(paned, grid)

    push_back!(box, dropdown)

    push_back!(dropdown, "PID") do self::DropDown
        global scaler = 120
        return nothing
        
    end
    push_back!(dropdown, "Manual") do self::DropDown
        global scaler = 2.55
        return nothing
    end

    mix = Scale(0, 100, 1)
    set_size_request!(mix,Vector2f(scaleSize, 0))
    mix_label = Label("Motor Index")
    connect_signal_value_changed!(mix) do self::Scale
        value = floor(Int,scaler*get_value(self))
        dict = Dict("action"=>"setval","data" => Dict("mix"=>value))
        push!(appsignal, JSON.json(dict))
        return nothing
    end

    mmd = Scale(0, 100, 1)
    set_size_request!(mmd,Vector2f(scaleSize, 0))
    mmd_label = Label("Motor Middle")
    connect_signal_value_changed!(mmd) do self::Scale
        value = floor(Int,scaler*get_value(self))
        dict = Dict("action"=>"setval","data" => Dict("mmd"=>value))
        push!(appsignal, JSON.json(dict))
        return nothing
    end

    six = Switch()
    six_label = Label("Solenoid Index")
    set_alignment!(six, ALIGNMENT_CENTER)
    connect_signal_switched!(six) do self::Switch
        println("Six: $( get_is_active(self)) ")
    end

    insert_at!(grid, mix_label, 1, 1, 1, 1)
    insert_at!(grid, mix, 2, 1, 20, 1)
    insert_at!(grid, mmd_label, 1, 2, 1, 1)
    insert_at!(grid, mmd, 2, 2, 20, 1)
    
    insert_at!(grid, six_label, 1, 6, 1, 1)
    insert_at!(grid, six, 2, 6, 1, 1)

    set_margin!(grid, 10)
    set_child!(window, paned)
    present!(window)
end

end