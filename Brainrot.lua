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

-- --- FUNCIONES BASE ---

local function CollectCash()
    for slot = 1, 20 do task.spawn(function() Remotes.CollectCash:Fire(slot) end) end
end

local function Rebirth()
    local speed = GetData("Speed") or 0
    local rebirths = GetData("Rebirths") or 0
    local nextCost = 40 + rebirths * 10
    if speed >= nextCost then Remotes.RequestRebirth:Fire() end
end

local function SellBrainrots()
    local stored = GetData("StoredBrainrots") or {}
    for slotKey, brainrot in pairs(stored) do
        local data = BrainrotsData[brainrot.Index]
        if data then
            local rarity = data.Rarity
            local mutation = brainrot.Mutation or "Default"
            local isExcluded = excludedRarities[rarity] or excludedMutations[mutation] or excludedNames[brainrot.Index]
            if (sellMode == "Exclude" and not isExcluded) or (sellMode == "Include" and isExcluded) then
                task.spawn(function() Remotes.SellThis:Fire(slotKey) end)
            end
        end
    end
end

-- --- LÓGICA DE FARM (LA MEJORA) ---

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local VIP_GAMEPASS_ID = 1760093100
local hasVIP = false
pcall(function() hasVIP = MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, VIP_GAMEPASS_ID) end)

local function getSelected(optValue)
    local t = {}
    if not optValue then return t end
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
    local mRarity = false
    for _, r in ipairs(selectedRarities) do if rarity == r then mRarity = true break end end
    local mMutation = false
    for _, m in ipairs(selectedMutations) do 
        if (m == "Normal" and (mutation == "Normal" or mutation == "Default")) or mutation == m then 
            mMutation = true break 
        end 
    end
    return mRarity or mMutation
end

task.spawn(function()
    while true do
        if Options.BrainrotFarmToggle and Options.BrainrotFarmToggle.Value then
            local valid = {}
            for _, m in ipairs(workspace.Brainrots:GetChildren()) do
                if m:IsA("Model") and modelMatchesFilters(m) then table.insert(valid, m) end
            end
            if #valid > 0 then
                local target = valid[math.random(1, #valid)]
                rootPart.CFrame = CFrame.new(708, 39, -2123)
                task.wait(0.4)
                if not (Options.BrainrotFarmToggle and Options.BrainrotFarmToggle.Value) then continue end
                rootPart.CFrame = target:GetPivot() * CFrame.new(0, 3, 0)
                task.wait(0.3)
                local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then fireproximityprompt(prompt) end
                task.wait(0.3)
                rootPart.CFrame = CFrame.new(739, 39, -2122)
                task.wait(0.8)
            else
                task.wait(1)
            end
        end
        task.wait(0.1)
    end
end)

-- --- MISC FUNCTIONS (FREEZE / ANTI-SHAKE) ---

local storedLasers = {}
local function toggleLasers(val)
    if val then
        for _, base in ipairs(workspace.Map.Bases:GetChildren()) do
            local l = base:FindFirstChild("LasersModel")
            if l then storedLasers[l] = l.Parent; l.Parent = nil end
        end
    else
        for l, p in pairs(storedLasers) do l.Parent = p end
        storedLasers = {}
    end
end

local camera = workspace.CurrentCamera
local savedCF = camera.CFrame
local antiShakeEnabled = false
RunService:BindToRenderStep("AS_Pre", 200, function() if antiShakeEnabled then savedCF = camera.CFrame end end)
RunService:BindToRenderStep("AS_Post", 202, function() if antiShakeEnabled then camera.CFrame = savedCF end end)

-- --- TAREAS EN BUCLE (LOOPS) ---

task.spawn(function()
    while task.wait(0.5) do
        if autoCollect then CollectCash() end
        if autoRebirth then Rebirth() end
        if autoClaimGifts then 
            for i=1,9 do Remotes.ClaimGift:Fire(i) task.wait(0.1) end
        end
        if autoSell then SellBrainrots() end
        if autoEquipBest then Remotes.EquipBestBrainrots:Fire() end
        if autoUpgradeBase then Remotes.UpgradeBase:Fire() end
    end
end)

-- --- CONSTRUCCIÓN DE LA INTERFAZ (UI) ---

-- Farm Tab
Tabs.Farm:AddSection("Collection")
Tabs.Farm:AddToggle("AutoCollect", {Title = "Auto Collect Cash", Default = false}):OnChanged(function() autoCollect = Options.AutoCollect.Value end)
Tabs.Farm:AddSection("Brainrot Farming")
Tabs.Farm:AddDropdown("RarityDropdown", { Title = "Rarity Filter", Values = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God", "Secret", "Divine", "MEME", "OG", "Los"}, Multi = true, Default = {} })
Tabs.Farm:AddDropdown("MutationDropdown", { Title = "Mutation Filter", Values = {"Normal", "Gold", "Diamond", "Rainbow", "Hacker", "Candy"}, Multi = true, Default = {} })
Tabs.Farm:AddToggle("BrainrotFarmToggle", {Title = "Start Farming", Default = false})

-- Upgrades Tab
Tabs.Upgrades:AddToggle("AutoRebirth", {Title = "Auto Rebirth", Default = false}):OnChanged(function() autoRebirth = Options.AutoRebirth.Value end)
Tabs.Upgrades:AddToggle("AutoUpgradeBase", {Title = "Auto Upgrade Base", Default = false}):OnChanged(function() autoUpgradeBase = Options.AutoUpgradeBase.Value end)

-- Automation Tab
Tabs.Automation:AddToggle("AutoEquipBest", {Title = "Auto Equip Best", Default = false}):OnChanged(function() autoEquipBest = Options.AutoEquipBest.Value end)
Tabs.Automation:AddToggle("AutoClaimGifts", {Title = "Auto Claim Gifts", Default = false}):OnChanged(function() autoClaimGifts = Options.AutoClaimGifts.Value end)
Tabs.Automation:AddToggle("AutoSell", {Title = "Enable Auto Sell", Default = false}):OnChanged(function() autoSell = Options.AutoSell.Value end)

-- Misc Tab
Tabs.Misc:AddToggle("LasersToggle", {Title = "Remove Laser Doors", Default = false}):OnChanged(function() toggleLasers(Options.LasersToggle.Value) end)
Tabs.Misc:AddToggle("AntiShake", {Title = "Anti Camera Shake", Default = false}):OnChanged(function() antiShakeEnabled = Options.AntiShake.Value end)

-- Footer
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("BrainrotScript")
SaveManager:SetFolder("BrainrotScript")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
