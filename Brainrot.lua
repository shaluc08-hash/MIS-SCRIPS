local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Be a Brainrot Script",
    SubTitle = "by Phemonaz & Lucas Edit",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "dollar-sign" }),
    Upgrades = Window:AddTab({ Title = "Upgrades", Icon = "arrow-up" }),
    Automation = Window:AddTab({ Title = "Automation", Icon = "bot" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "folder-cog" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "cog" })
}
local Options = Fluent.Options

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerState = require(ReplicatedStorage.Libraries.PlayerState.PlayerStateClient)
local BrainrotsData = require(ReplicatedStorage.Database.BrainrotsData)
local RaritiesData = require(ReplicatedStorage.Database.RaritiesData)
local MutationsData = require(ReplicatedStorage.Database.MutationsData)

repeat task.wait() until PlayerState.IsReady()

local function GetData(path) return PlayerState.GetPath(path) end

-- Variables de Estado
local autoCollect, autoRebirth, autoSpeedUpgrade = false, false, false
local autoEquipBest, autoClaimGifts, autoUpgradeBase, autoSell = false, false, false, false
local collectInterval, rebirthInterval, speedUpgradeInterval = 1, 1, 1
local equipBestInterval, claimGiftsInterval, upgradeBaseInterval, sellInterval = 4, 1, 3, 3
local speedUpgradeAmount = 1
local sellMode = "Exclude"
local excludedRarities, excludedMutations, excludedNames = {}, {}, {}

-- Funciones Base
local function CollectCash()
    for slot = 1, 20 do
        task.spawn(function() Remotes.CollectCash:Fire(slot) end)
    end
end

local function Rebirth() Remotes.RequestRebirth:Fire() end
local function SpeedUpgrade(amount) Remotes.SpeedUpgrade:Fire(amount) end
local function EquipBestBrainrots() Remotes.EquipBestBrainrots:Fire() end
local function UpgradeBase() Remotes.UpgradeBase:Fire() end

local function ClaimGifts()
    for i = 1, 9 do
        task.spawn(function() Remotes.ClaimGift:Fire(i) end)
        task.wait(0.1)
    end
end

-- Lógica de Farm (La parte que querías arreglar)
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local VIP_GAMEPASS_ID = 1760093100
local hasVIP = false

pcall(function() hasVIP = MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, VIP_GAMEPASS_ID) end)

LocalPlayer.CharacterAdded:Connect(function(c)
    character = c
    rootPart = c:WaitForChild("HumanoidRootPart")
end)

local function getSelected(optValue)
    local t = {}
    for v, state in next, optValue do if state then table.insert(t, v) end end
    return t
end

local function modelMatchesFilters(model)
    local slotRef = model:GetAttribute("SlotRef")
    if slotRef then
        local slotNum = tonumber(slotRef:match("Slot(%d+)$"))
        if slotNum and slotNum >= 9 and not hasVIP then return false end
    end

    local selectedRarities = getSelected(Options.RarityDropdown.Value)
    local selectedMutations = getSelected(Options.MutationDropdown.Value)
    
    if #selectedRarities == 0 and #selectedMutations == 0 then return true end

    local rarity = model:GetAttribute("Rarity")
    local mutation = model:GetAttribute("Mutation") or "Normal"

    local matchesRarity = #selectedRarities == 0
    for _, r in ipairs(selectedRarities) do if rarity == r then matchesRarity = true break end end

    local matchesMutation = #selectedMutations == 0
    for _, m in ipairs(selectedMutations) do if mutation == m then matchesMutation = true break end end

    return matchesRarity and matchesMutation
end

-- BUSCADOR DE BOTÓN MEJORADO (Más flexible que el original)
local function findCarryPrompt(model)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            -- Si es el bicho correcto, cualquier prompt adentro debería servir
            return desc
        end
    end
    return nil
end

local function getValidModels()
    local valid = {}
    for _, model in ipairs(workspace.Brainrots:GetChildren()) do
        if model:IsA("Model") and modelMatchesFilters(model) then
            table.insert(valid, model)
        end
    end
    return valid
end

local loopToken = 0
local function runLoop(token)
    while loopToken == token do
        local validModels = getValidModels()
        
        -- Si no hay objetivos, se queda quieto
        if #validModels == 0 then
            task.wait(1)
            continue
        end

        local target = validModels[math.random(1, #validModels)]
        if not target or not target.Parent then continue end

        -- Teleport al centro para "despistar" o resetear posición
        rootPart.CFrame = CFrame.new(708, 39, -2123)
        task.wait(0.4)
        if loopToken ~= token then break end

        -- Teleport al bicho
        local pivot = target:GetPivot()
        rootPart.CFrame = pivot * CFrame.new(0, 2, 0) -- Un poco más cerca que antes
        task.wait(0.3)

        -- Intento de AGARRE con Plan B
        local prompt = findCarryPrompt(target)
        if prompt then
            fireproximityprompt(prompt)
            -- Forzado por si acaso
            task.spawn(function()
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end

        task.wait(0.4)
        if loopToken ~= token then break end

        -- Volver a base
        rootPart.CFrame = CFrame.new(739, 39, -2122)
        task.wait(0.8)
    end
end

-- Seccion Farm en la UI
Tabs.Farm:AddSection("Brainrots")
local RarityDropdown = Tabs.Farm:AddDropdown("RarityDropdown", {
    Title = "Rarity Filter",
    Values = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God", "Secret", "Divine", "MEME", "OG", "Los"},
    Multi = true, Default = {},
})

local MutationDropdown = Tabs.Farm:AddDropdown("MutationDropdown", {
    Title = "Mutation Filter",
    Values = {"Normal", "Gold", "Diamond", "Rainbow", "Hacker", "Candy"},
    Multi = true, Default = {},
})

local FarmToggle = Tabs.Farm:AddToggle("BrainrotFarmToggle", {Title = "Farm Selected Brainrots", Default = false})
FarmToggle:OnChanged(function()
    if Options.BrainrotFarmToggle.Value then
        loopToken = loopToken + 1
        task.spawn(runLoop, loopToken)
    else
        loopToken = loopToken + 1
    end
end)

-- El resto de tus funciones (AutoCollect, Sell, Upgrades, etc)
-- [Aquí irían todas las tareas automáticas que ya tenías configuradas]
-- Para no hacer el mensaje infinito, asumo que las mantienes tal cual las pasaste arriba.

-- Finalización del Script
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
