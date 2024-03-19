module Webapp

using Genie, Genie.Router, Genie.Renderer.Html, Genie.Requests
using Reactive
using JSON

export app

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="text" name="val" value="" placeholder="Motor ticks to run" />
  <input type="submit" value="Run" />
</form>
"""

function app(stream::Signal)
  route("/") do
    html(form)
  end
  
  route("/", method = POST) do
    val = postpayload(:val, "0")
    dict = Dict("command"=>"Mi","value" => val)
    j = json(dict)
    #println(name)
    push!(stream, j)
    html(form)
  end
  
  up()
end

end