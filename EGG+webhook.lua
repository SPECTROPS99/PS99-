local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Home", HidePremium = false, SaveConfig = true, ConfigFolder = "OrionTest"})
local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = nil,
    PremiumOnly = false
})
local Section = MainTab:AddSection({
    Name = "Section"
})
MainTab:AddToggle({
    Name = "Open Eggs",
    Default = false,
    Callback = function(Value)
        print(Value)
    end
})
MainTab:AddToggle({
    Name = "Auto Pick Up Orbs",
    Default = false,
    Callback = function(Value)
        print(Value)
    end
})
MainTab:AddToggle({
    Name = "3DRendering",
    Default = false,
    Callback = function(Value)
        print(Value)
    end
})
MainTab:AddTextbox({
    Name = "Webhook",
    Default = "default box input",
    TextDisappear = true,
    Callback = function(Value)
        print(Value)
    end
})
