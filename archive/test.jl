using Reactive
using GenieFramework; Genie.loadapp(); Server.isrunning() || up(async=true)
foreach(x -> println(x), Main.App.appsignal)