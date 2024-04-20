local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "TH Hub", HidePremium = false, SaveConfig = true, ConfigFolder = "Touhou"})

local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = nil,
    PremiumOnly = false
})

local WebhookURL = "Enter Webhook"
local EggNumber = 187 -- Egg Number
local Enable3DRender = true 
local AutoLootToggle = false
local OpenEggsToggle = false

MainTab:AddToggle({
    Name = "Open Eggs",
    Default = OpenEggsToggle,
    Callback = function(Value)
        OpenEggsToggle = Value
    end
})
MainTab:AddTextbox({
    Name = "Egg Number",
    Default = "187",
    TextDisappear = true,
    Callback = function(Value)
        EggNumber = tonumber(Value)
    end
})
MainTab:AddToggle({
    Name = "Auto Pick Up Orbs",
    Default = AutoLootToggle,
    Callback = function(Value)
        AutoLootToggle = Value
    end
})
MainTab:AddToggle({
    Name = "3DRendering",
    Default = Enable3DRender,
    Callback = function(Value)
        Enable3DRender = Value
        game:GetService("RunService"):Set3dRenderingEnabled(Enable3DRender)
    end
})
MainTab:AddTextbox({
    Name = "Webhook",
    Default = WebhookURL,
    TextDisappear = true,
    Callback = function(Value)
        WebhookURL = Value
    end
})

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local EggsUtilMod = require(ReplicatedStorage.Library.Util.EggsUtil)
local EggAnim = getsenv(Players.LocalPlayer.PlayerScripts.Scripts.Game["Egg Opening Frontend"])
local Network = game:GetService("ReplicatedStorage"):WaitForChild("Network")
game:GetService("RunService"):Set3dRenderingEnabled(Enable3DRender)


local function GetThumbnailID(petName)
    local PetInventory = require(ReplicatedStorage.Library).Directory.Pets
    for _, petData in pairs(PetInventory) do
        if petData.name == petName then
            local thumbnailID = string.gsub(petData.thumbnail, "rbxassetid://", "")
            return thumbnailID
        end
    end
end

local function SendWebhook(playerName, petName, petUID)
    local thumbnailURL = HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds=" .. GetThumbnailID(petName) .. "&size=250x250&format=Png&isCircular=false")).data[1].imageUrl
    local WebhookMessage = HttpService:JSONEncode({
        content = "@everyone",
        embeds = {{
            title = playerName .. " Obtained a " .. petName,
            color = 0x00FF00,
            timestamp = DateTime.now():ToIsoDate(),
            thumbnail = {
                url = thumbnailURL
            },
            fields = {
                {
                    name = "Pet UID",
                    value = petUID
                },
            },
            footer = {
                text = "🦛 Made By LordHippo"
            }
        }}
    })

    local success, response = pcall(function()
        return request({
            Url = WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = WebhookMessage
        })
    end)

    if not success then
        warn("Webhook request failed:", response)
    end
end

local function CurrentHugePets()
    local PetInventory = require(ReplicatedStorage.Library).Save.Get().Inventory.Pet
    local HugePets = {}

    for uid, pet in pairs(PetInventory) do
        if string.find(pet.id, "Huge") then
            table.insert(HugePets, {id = pet.id, uid = uid})
        end
    end

    for _, petData in ipairs(HugePets) do

    end

    return HugePets
end

local currentHugePets = CurrentHugePets()

local function CheckForNewHuge()
    local NewHuge = {}
    local PetInventory = require(ReplicatedStorage.Library).Save.Get().Inventory.Pet

    for uid, pet in pairs(PetInventory) do
        if string.find(pet.id, "Huge") then
            local isNew = true

            for _, existingPetData in ipairs(currentHugePets) do
                if existingPetData.uid == uid then
                    isNew = false
                    break
                end
            end

            if isNew then
                table.insert(NewHuge, {id = pet.id, uid = uid})
            end
        end
    end

    if #NewHuge > 0 then
        for _, petData in ipairs(NewHuge) do
            SendWebhook(game.Players.LocalPlayer.Name, petData.id, petData.uid)
        end
    end

    currentHugePets = CurrentHugePets()
end


local function OpenEgg()
    if OpenEggsToggle then
        while OpenEggsToggle do
            local PlayerInfo = require(ReplicatedStorage.Library).Save.Get()
            local EggName = EggsUtilMod.GetIdByNumber(EggNumber)
            local Egg = Workspace.__THINGS.Eggs:FindFirstChild("World2")[EggNumber .. " - Egg Capsule"]
            local Teleport = Egg.Tier.CFrame
    
            EggAnim.PlayEggAnimation = function() end
            Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Teleport
            ReplicatedStorage.Network.Eggs_RequestPurchase:InvokeServer(EggName, PlayerInfo.EggHatchCount)
        end
    end
end

local autoLootExecuted = false
local autoOrbConnection = nil
local autoLootBagConnection = nil

local function AutoLoot()
    if AutoLootToggle and not autoLootExecuted then
        autoLootExecuted = true

        for i, v in ipairs(workspace.__THINGS.Orbs:GetChildren()) do
            Network["Orbs: Collect"]:FireServer({ tonumber(v.Name) })
            Network["Orbs_ClaimMultiple"]:FireServer({ { v.Name } })
            v:Destroy()
        end

        for i, v in ipairs(workspace.__THINGS.Lootbags:GetChildren()) do
            Network.Lootbags_Claim:FireServer({ v.Name })
            v:Destroy()
        end

        autoOrbConnection = workspace.__THINGS.Orbs.ChildAdded:Connect(function(v)
            task.wait()
            Network["Orbs: Collect"]:FireServer({ tonumber(v.Name) })
            Network["Orbs_ClaimMultiple"]:FireServer({ { v.Name } })
            v:Destroy()
        end)

        autoLootBagConnection = workspace.__THINGS.Lootbags.ChildAdded:Connect(function(v)
            task.wait()
            Network.Lootbags_Claim:FireServer({ v.Name })
            v:Destroy()
        end)
    elseif not AutoLootToggle and autoLootExecuted then
        autoLootExecuted = false

        if autoOrbConnection then
            autoOrbConnection:Disconnect()
            autoOrbConnection = nil
        end

        if autoLootBagConnection then
            autoLootBagConnection:Disconnect()
            autoLootBagConnection = nil
        end
    end
end

while wait() do
    CheckForNewHuge()
    OpenEgg()
    AutoLoot()
end

OrionLib:Init()
