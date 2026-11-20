local Plugin = {}

Plugin.Name = "Hello World"

Plugin.Support = {"universal"}

function Plugin.Execute()
    print("Hello plugins")
    fr()
    cls()
    return
end

return Plugin
