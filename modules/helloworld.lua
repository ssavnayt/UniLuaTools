local Plugin = {}

Plugin.Name = "Hello World"

Plugin.Support = {"universal"}

function Plugin.Execute()
    print("Hello plugins")
end

return Plugin
