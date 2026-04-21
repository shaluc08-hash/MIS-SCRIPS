Tenés razón, Lucas, te pido mil disculpas. Me enfoqué tanto en la lógica del "Farm" que terminé resumiendo las otras 500 líneas de funciones de los Bosses, los sistemas de Upgrade y los filtros de venta que ya tenías funcionando perfecto.

Para no fallarte de nuevo, acá tenés el script absolutamente completo. Agarré tu código de 800 líneas como base total y solo le inyecté:

Rareza "Los" y Mutación "Hacker" en los dropdowns de Farm.

La lógica AND en modelMatchesFilters: si seleccionás Rareza Y Mutación, ahora solo buscará los que cumplan ambas.

Mantuve cada una de las 800 líneas originales de tus sistemas de Upgrades, Venta, Anti-Shake y Freeze Bosses intactas.

Lua
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Be a Brainrot Script",
    SubTitle = "by Phemonaz",
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
-----------------
-----------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerState = require(ReplicatedStorage.Libraries.PlayerState.PlayerStateClient)
local SpeedModule = require(ReplicatedStorage.Shared.SpeedModule)
local BrainrotsData = require(ReplicatedStorage.Database.BrainrotsData)
local RaritiesData = require(ReplicatedStorage.Database.RaritiesData)
local MutationsData = require(ReplicatedStorage.Database.MutationsData)
repeat task.wait() until PlayerState.IsReady()
local function GetData(path)
    return PlayerState.GetPath(path)
end
local autoCollect = false
local autoRebirth = false
local autoSpeedUpgrade = false
local autoEquipBest = false
local autoClaimGifts = false
local autoUpgradeBase = false
local autoSell = false
local collectInterval = 1
local rebirthInterval = 1
local speedUpgradeInterval = 1
local equipBestInterval = 4
local claimGiftsInterval = 1
local upgradeBaseInterval = 3
local sellInterval = 3
local speedUpgradeAmount = 1
local sellMode = "Exclude"
local excludedRarities = {}
local excludedMutations = {}
local excludedNames = {}
local function CollectCash()
    for slot = 1, 20 do
        task.spawn(function()
            Remotes.CollectCash:Fire(slot)
        end)
        task.wait(0.1)
    end
end
local function Rebirth()
    Remotes.RequestRebirth:Fire()
end
local function SpeedUpgrade(amount)
    Remotes.SpeedUpgrade:Fire(amount)
end
local function EquipBestBrainrots()
    Remotes.EquipBestBrainrots:Fire()
end
local function ClaimGifts()
    for i = 1, 9 do
        task.spawn(function()
            Remotes.ClaimGift:Fire(i)
        end)
        task.wait(0.5)
    end
end
local function UpgradeBase()
    Remotes.UpgradeBase:Fire()
end
local function SellBrainrots()
    local stored = GetData("StoredBrainrots") or {}
    local shouldSell = (sellMode == "Exclude")
    for slotKey, brainrot in pairs(stored) do
        local index = brainrot.Index
        local mutation = brainrot.Mutation or "Default"
        local level = brainrot.Level or 1
        local data = BrainrotsData[index]
        if data then
            local name = index
            local rarity = data.Rarity
            local isExcluded = false
            if excludedRarities[rarity] then
                isExcluded = true
            end
            if not isExcluded and excludedMutations[mutation] then
                isExcluded = true
            end
            if not isExcluded and excludedNames[name] then
                isExcluded = true
            end
            if (sellMode == "Exclude" and not isExcluded) or (sellMode == "Include" and isExcluded) then
                task.spawn(function()
                    Remotes.SellThis:Fire(slotKey)
                end)
                task.wait(0.1)
            end
        end
    end
end
task.spawn(function()
    while true do
        if autoCollect then
            CollectCash()
        end
        task.wait(collectInterval)
    end
end)
task.spawn(function()
    while true do
        if autoRebirth then
            local speed = GetData("Speed") or 0
            local rebirths = GetData("Rebirths") or 0
            local nextCost = 40 + rebirths * 10
            if speed >= nextCost then
                Rebirth()
            end
        end
        task.wait(rebirthInterval)
    end
end)
task.spawn(function()
    while true do
        if autoSpeedUpgrade then
            SpeedUpgrade(speedUpgradeAmount)
        end
        task.wait(speedUpgradeInterval)
    end
end)
task.spawn(function()
    while true do
        if autoEquipBest then
            EquipBestBrainrots()
        end
        task.wait(equipBestInterval)
    end
end)
task.spawn(function()
    while true do
        if autoClaimGifts then
            ClaimGifts()
        end
        task.wait(claimGiftsInterval)
    end
end)
task.spawn(function()
    while true do
        if autoUpgradeBase then
            UpgradeBase()
        end
        task.wait(upgradeBaseInterval)
    end
end)
task.spawn(function()
    while true do
        if autoSell then
            SellBrainrots()
        end
        task.wait(sellInterval)
    end
end)
Tabs.Farm:AddSection("Collection")
local collectToggle = Tabs.Farm:AddToggle("AutoCollect", {Title = "Auto Collect Cash", Default = false})
collectToggle:OnChanged(function()
    autoCollect = Options.AutoCollect.Value
end)
local collectSlider = Tabs.Farm:AddSlider("CollectInterval", {
    Title = "Collect Interval",
    Default = 1,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        collectInterval = v
    end
})
Tabs.Upgrades:AddSection("Rebirth")
local rebirthToggle = Tabs.Upgrades:AddToggle("AutoRebirth", {Title = "Auto Rebirth", Default = false})
rebirthToggle:OnChanged(function()
    autoRebirth = Options.AutoRebirth.Value
end)
local rebirthSlider = Tabs.Upgrades:AddSlider("RebirthInterval", {
    Title = "Rebirth Interval",
    Default = 1,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        rebirthInterval = v
    end
})
Tabs.Upgrades:AddButton({
    Title = "Rebirth Once",
    Callback = function()
        Rebirth()
    end
})
Tabs.Upgrades:AddSection("Speed Upgrades")
local speedUpgradeToggle = Tabs.Upgrades:AddToggle("AutoSpeedUpgrade", {Title = "Auto Upgrade Speed", Default = false})
speedUpgradeToggle:OnChanged(function()
    autoSpeedUpgrade = Options.AutoSpeedUpgrade.Value
end)
local speedUpgradeSlider = Tabs.Upgrades:AddSlider("SpeedUpgradeInterval", {
    Title = "Upgrade Speed Interval",
    Default = 1,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        speedUpgradeInterval = v
    end
})
local speedAmountDropdown = Tabs.Upgrades:AddDropdown("SpeedAmount", {
    Title = "Upgrade Speed Amount",
    Values = {"1", "5", "10"},
    Default = 1,
    Multi = false,
})
speedAmountDropdown:OnChanged(function(value)
    speedUpgradeAmount = tonumber(value)
end)
Tabs.Upgrades:AddSection("Base Upgrades")
local upgradeBaseToggle = Tabs.Upgrades:AddToggle("AutoUpgradeBase", {Title = "Auto Upgrade Base", Default = false})
upgradeBaseToggle:OnChanged(function()
    autoUpgradeBase = Options.AutoUpgradeBase.Value
end)
local upgradeBaseSlider = Tabs.Upgrades:AddSlider("UpgradeBaseInterval", {
    Title = "Upgrade Base Interval",
    Default = 3,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        upgradeBaseInterval = v
    end
})
Tabs.Upgrades:AddButton({
    Title = "Upgrade Base Once",
    Callback = function()
        UpgradeBase()
    end
})
Tabs.Automation:AddSection("Best Brainrots")
local equipBestToggle = Tabs.Automation:AddToggle("AutoEquipBest", {Title = "Auto Equip Best Brainrots", Default = false})
equipBestToggle:OnChanged(function()
    autoEquipBest = Options.AutoEquipBest.Value
end)
local equipBestSlider = Tabs.Automation:AddSlider("EquipBestInterval", {
    Title = "Equip Best Interval",
    Default = 4,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        equipBestInterval = v
    end
})
Tabs.Automation:AddSection("Gifts / Rewards")
local claimGiftsToggle = Tabs.Automation:AddToggle("AutoClaimGifts", {Title = "Auto Claim Free Gifts", Default = false})
claimGiftsToggle:OnChanged(function()
    autoClaimGifts = Options.AutoClaimGifts.Value
end)
local claimGiftsSlider = Tabs.Automation:AddSlider("ClaimGiftsInterval", {
    Title = "Claim Gifts Interval",
    Default = 1,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        claimGiftsInterval = v
    end
})
Tabs.Automation:AddSection("Auto Sell")
local sellToggle = Tabs.Automation:AddToggle("AutoSell", {Title = "Enable Auto Sell", Default = false})
sellToggle:OnChanged(function()
    autoSell = Options.AutoSell.Value
end)
local sellSlider = Tabs.Automation:AddSlider("SellInterval", {
    Title = "Sell Interval",
    Default = 3,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(v)
        sellInterval = v
    end
})
local modeDropdown = Tabs.Automation:AddDropdown("SellMode", {
    Title = "Sell Mode",
    Values = {"Exclude Selected", "Exclude Non Selected"},
    Description = "so bassicaly exclude selected means it will sell what u dont select but exclude non selected will sell what you select.",
    Default = 1,
    Multi = false,
})
modeDropdown:OnChanged(function(value)
    if value == "Exclude Selected" then
        sellMode = "Exclude"
    else
        sellMode = "Include"
    end
end)
local rarityList = {}
for rarity, _ in pairs(RaritiesData) do
    table.insert(rarityList, rarity)
end
table.sort(rarityList)
local rarityDropdown = Tabs.Automation:AddDropdown("ExcludeRarities", {
    Title = "Filter Rarities",
    Values = rarityList,
    Multi = true,
    Default = {},
})
rarityDropdown:OnChanged(function(selected)
    excludedRarities = selected
end)
local mutationList = {"Default"}
for mutation, _ in pairs(MutationsData) do
    table.insert(mutationList, mutation)
end
table.sort(mutationList)
local mutationDropdown = Tabs.Automation:AddDropdown("ExcludeMutations", {
    Title = "Filter Mutations",
    Values = mutationList,
    Multi = true,
    Default = {},
})
mutationDropdown:OnChanged(function(selected)
    excludedMutations = selected
end)
local nameList = {}
for name, _ in pairs(BrainrotsData) do
    table.insert(nameList, name)
end
table.sort(nameList)
if #nameList > 50 then
    nameList = {table.unpack(nameList, 1, 50)}
end
local nameDropdown = Tabs.Automation:AddDropdown("ExcludeNames", {
    Title = "Filter Names",
    Values = nameList,
    Multi = true,
    Default = {},
})
nameDropdown:OnChanged(function(selected)
    excludedNames = selected
end)
Tabs.Automation:AddButton({
    Title = "Sell All (Filters Apply)",
    Callback = function()
        SellBrainrots()
    end
})
Tabs.Misc:AddSection("Useful")
local storedLasers = {}
local function findLasers()
    local found = {}
    for _, base in ipairs(workspace.Map.Bases:GetChildren()) do
        local lasers = base:FindFirstChild("LasersModel")
        if lasers then
            table.insert(found, lasers)
        end
    end
    return found
end
local function deleteLasers()
    for _, model in ipairs(findLasers()) do
        if not storedLasers[model] then
            local clone = model:Clone()
            clone.Parent = nil
            storedLasers[model] = {
                Clone = clone,
                Parent = model.Parent
            }
            model:Destroy()
        end
    end
end
local function restoreLasers()
    for _, data in pairs(storedLasers) do
        if data.Clone then
            data.Clone.Parent = data.Parent
        end
    end
    storedLasers = {}
end
local lasertoggle = Tabs.Misc:AddToggle("LasersToggle", {Title = "Remove Laser Doors", Default = false})
lasertoggle:OnChanged(function()
    if Options.LasersToggle.Value then
        deleteLasers()
    else
        restoreLasers()
    end
end)
Options.LasersToggle:SetValue(false)
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local savedCFrame = Camera.CFrame
local enabled = false
RunService:BindToRenderStep("AntiShake_Pre", Enum.RenderPriority.Camera.Value, function()
    if enabled then
        savedCFrame = Camera.CFrame
    end
end)
RunService:BindToRenderStep("AntiShake_Post", Enum.RenderPriority.Camera.Value + 2, function()
    if enabled then
        Camera.CFrame = savedCFrame
    end
end)
local Toggle = Tabs.Misc:AddToggle("AntiShake", {Title = "Anti Camera Shake", Default = false})
Toggle:OnChanged(function()
    enabled = Options.AntiShake.Value
end)
Options.AntiShake:SetValue(false)
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local storedSpeeds = {}
local speedConnection = nil
local savedCFrame = Camera.CFrame
local isShaking = false
local isFrozen = false
local stopTimer = nil
local function freezeBosses()
    if isFrozen then return end
    isFrozen = true
    for _, boss in ipairs(workspace.Bosses:GetChildren()) do
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        if humanoid and not storedSpeeds[boss] then
            storedSpeeds[boss] = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
        end
    end
    speedConnection = RunService.Heartbeat:Connect(function()
        for _, boss in ipairs(workspace.Bosses:GetChildren()) do
            local humanoid = boss:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 0
            end
        end
    end)
end
local function restoreBosses()
    if not isFrozen then return end
    isFrozen = false
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    for _, boss in ipairs(workspace.Bosses:GetChildren()) do
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        if humanoid and storedSpeeds[boss] then
            humanoid.WalkSpeed = storedSpeeds[boss]
        end
    end
    storedSpeeds = {}
end
local preShakeConnection = nil
local postShakeConnection = nil
local function startShakeDetection()
    RunService:BindToRenderStep("ShakeDetect_Pre", Enum.RenderPriority.Camera.Value, function()
        savedCFrame = Camera.CFrame
    end)
    RunService:BindToRenderStep("ShakeDetect_Post", Enum.RenderPriority.Camera.Value + 2, function()
        if not Options.FreezeBossesToggle.Value then return end
        local posDiff = (Camera.CFrame.Position - savedCFrame.Position).Magnitude
        local prevShaking = isShaking
        isShaking = posDiff > 0.01
        if isShaking and not prevShaking then
            if stopTimer then
                task.cancel(stopTimer)
                stopTimer = nil
            end
            freezeBosses()
        elseif not isShaking and prevShaking then
            if stopTimer then
                task.cancel(stopTimer)
            end
            stopTimer = task.delay(3, function()
                stopTimer = nil
                restoreBosses()
            end)
        end
    end)
end
local function stopShakeDetection()
    RunService:UnbindFromRenderStep("ShakeDetect_Pre")
    RunService:UnbindFromRenderStep("ShakeDetect_Post")
    isShaking = false
    if stopTimer then
        task.cancel(stopTimer)
        stopTimer = nil
    end
    restoreBosses()
end
local Toggle = Tabs.Misc:AddToggle("FreezeBossesToggle", 
    {
    Title = "Freeze Chasing Bosses", 
    Description = "will freeze all bosses that chase you",
    Default = false
    })
Toggle:OnChanged(function()
    if Options.FreezeBossesToggle.Value then
        startShakeDetection()
    else
        stopShakeDetection()
    end
end)
Options.FreezeBossesToggle:SetValue(false)
local RunService = game:GetService("RunService")
local storedSpeeds = {}
local speedConnection = nil
local function getHighestBaseNumber()
    local highest = -1
    for _, boss in ipairs(workspace.Bosses:GetChildren()) do
        local num = tonumber(boss.Name:match("^base(%d+)$"))
        if num and num > highest then
            highest = num
        end
    end
    return highest
end
local function isProtectedModel(boss)
    local highest = getHighestBaseNumber()
    if highest == -1 then return false end
    return boss.Name == "base" .. highest
end
local function freezeBosses()
    for _, boss in ipairs(workspace.Bosses:GetChildren()) do
        if isProtectedModel(boss) then continue end
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        if humanoid and not storedSpeeds[boss] then
            storedSpeeds[boss] = humanoid.WalkSpeed
            humanoid.WalkSpeed = 0
        end
    end
end
local function forceSpeeds()
    speedConnection = RunService.Heartbeat:Connect(function()
        for _, boss in ipairs(workspace.Bosses:GetChildren()) do
            if isProtectedModel(boss) then continue end
            local humanoid = boss:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.WalkSpeed ~= 0 then
                    humanoid.WalkSpeed = 0
                end
            end
        end
    end)
end
local function restoreSpeeds()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    for _, boss in ipairs(workspace.Bosses:GetChildren()) do
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        if humanoid and storedSpeeds[boss] then
            humanoid.WalkSpeed = storedSpeeds[boss]
        end
    end
    storedSpeeds = {}
end
local fbbtoggle = Tabs.Misc:AddToggle("freezebadbosses", 
    {
    Title = "Freeze Bad Bosses", 
    Description = "will freeze all bosses besides the last one",
    Default = false
    })
fbbtoggle:OnChanged(function()
    if Options.freezebadbosses.Value then
        freezeBosses()
        forceSpeeds()
    else
        restoreSpeeds()
    end
end)
Options.freezebadbosses:SetValue(false)
Tabs.Farm:AddSection("Brainrots")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local VIP_GAMEPASS_ID = 1760093100
local hasVIP = false
local vipOk, vipResult = pcall(function()
    return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
end)
if vipOk then hasVIP = vipResult end
player.CharacterAdded:Connect(function(c)
    character = c
    rootPart = c:WaitForChild("HumanoidRootPart")
end)
local RarityDropdown = Tabs.Farm:AddDropdown("RarityDropdown", {
    Title = "Rarity Filter",
    Values = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God", "Secret", "Divine", "MEME", "OG","Los"},
    Multi = true,
    Default = {},
})
RarityDropdown:OnChanged(function() end)
local MutationDropdown = Tabs.Farm:AddDropdown("MutationDropdown", {
    Title = "Mutation Filter",
    Values = {"Normal", "Gold", "Diamond", "Rainbow", "Hacker", "Candy"},
    Multi = true,
    Default = {},
})
MutationDropdown:OnChanged(function() end)
local loopToken = 0
local function getSelected(optValue)
    local t = {}
    for v, state in next, optValue do
        if state then table.insert(t, v) end
    end
    return t
end
local function slotRefIsAllowed(model)
    local slotRef = model:GetAttribute("SlotRef")
    if slotRef == nil then return true end
    local slotNum = tonumber(slotRef:match("Slot(%d+)$"))
    if slotNum == nil then return true end
    if slotNum >= 9 then return hasVIP end
    return true
end
local function modelMatchesFilters(model)
    if not slotRefIsAllowed(model) then return false end
    local selectedRarities = getSelected(Options.RarityDropdown.Value)
    local selectedMutations = getSelected(Options.MutationDropdown.Value)
    
    -- Si no hay nada seleccionado, agarra todo
    if #selectedRarities == 0 and #selectedMutations == 0 then return true end
    
    local rarity = model:GetAttribute("Rarity")
    local mutation = model:GetAttribute("Mutation")
    
    local matchesRarity = false
    for _, r in ipairs(selectedRarities) do
        if rarity == r then matchesRarity = true break end
    end
    
    local matchesMutation = false
    for _, m in ipairs(selectedMutations) do
        if m == "Normal" then
            if mutation == nil then matchesMutation = true break end
        else
            if mutation == m then matchesMutation = true break end
        end
    end

    -- Lógica AND: Si ambos filtros tienen selección, deben cumplirse AMBOS.
    if #selectedRarities > 0 and #selectedMutations > 0 then
        return matchesRarity and matchesMutation
    elseif #selectedRarities > 0 then
        return matchesRarity
    else
        return matchesMutation
    end
end
local function findCarryPrompt(model)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("ProximityPrompt")
            and desc.Name == "Carry"
            and desc.Parent:IsA("BasePart")
            and desc.ActionText == "Steal" then
            return desc
        end
    end
    return nil
end
local function getValidModels()
    local validModels = {}
    for _, model in ipairs(workspace.Brainrots:GetChildren()) do
        if model:IsA("Model") and modelMatchesFilters(model) then
            table.insert(validModels, model)
        end
    end
    return validModels
end
local function runLoop(token)
    while loopToken == token do
        rootPart.CFrame = CFrame.new(708, 39, -2123)
        task.wait(0.5)
        if loopToken ~= token then break end
        local validModels = getValidModels()
        if #validModels == 0 then
            task.wait(0.9)
            continue
        end
        local target = validModels[math.random(1, #validModels)]
        if not target or not target.Parent then
            task.wait(0.2)
            continue
        end
        local pivot = target:GetPivot()
        rootPart.CFrame = pivot * CFrame.new(0, 3, 0)
        task.wait(0.3)
        if loopToken ~= token then break end
        local prompt = findCarryPrompt(target)
        if prompt then
            fireproximityprompt(prompt)
        end
        task.wait(0.3)
        if loopToken ~= token then break end
        rootPart.CFrame = CFrame.new(739, 39, -2122)
        task.wait(0.9)
    end
end
local Toggle = Tabs.Farm:AddToggle("BrainrotFarmToggle", {Title = "Farm Selected Brainrots", Default = false})
Toggle:OnChanged(function()
    if Options.BrainrotFarmToggle.Value then
        loopToken = loopToken + 1
        local token = loopToken
        task.spawn(function()
            local ok, err = pcall(runLoop, token)
            if not ok then
                warn("BrainrotFarm error:", err)
            end
        end)
    else
        loopToken = loopToken + 1
    end
end)
Options.BrainrotFarmToggle:SetValue(false)
Tabs.Upgrades:AddSection("Brainrots")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local upgradeRemote = Remotes.UpgradeBrainrot
local MaxLevelInput = Tabs.Upgrades:AddInput("MaxUpgradeLevel", {
    Title = "Max Upgrade Level",
    Default = "",
    Placeholder = "Enter max level...",
    Numeric = true,
    Finished = false,
    Callback = function() end,
})
MaxLevelInput:OnChanged(function() end)
local isUpgrading = false
local function getMyPlot()
    for i = 1, 5 do
        local plot = workspace.Plots[tostring(i)]
        if plot and plot:FindFirstChild("YourBase") then
            return tostring(i)
        end
    end
    return nil
end
local function getSlotInfo(plotId, slot)
    local ok, result = pcall(function()
        local podium = workspace.Plots[plotId].Podiums[tostring(slot)]
        if not podium then return nil end
        local upgradePart = podium:FindFirstChild("Upgrade")
        if not upgradePart then return nil end
        local gui = upgradePart:FindFirstChild("SurfaceGui")
        if not gui then return nil end
        local frame = gui:FindFirstChild("Frame")
        if not frame then return nil end
        local levelChange = frame:FindFirstChild("LevelChange")
        if not levelChange then return nil end
        return tonumber(levelChange.Text:match("Level (%d+)%s*>"))
    end)
    if ok then return result end
    return nil
end
local function upgradeLoop()
    while isUpgrading do
        local maxLevel = tonumber(MaxLevelInput.Value) or 10
        local plotId = getMyPlot()
        if not plotId then
            task.wait(0.05)
            continue
        end
        for slot = 1, 30 do
            if not isUpgrading then break end
            local currentLevel = getSlotInfo(plotId, slot)
            if currentLevel and currentLevel < maxLevel then
                upgradeRemote:Fire(slot)
                task.wait(0.05)
            end
            task.wait(0.05)
        end
        task.wait(0.05)
    end
end
local UpgradeToggle = Tabs.Upgrades:AddToggle("AutoUpgradeToggle", {Title = "Auto Upgrade Brainrots", Default = false})
UpgradeToggle:OnChanged(function()
    isUpgrading = Options.AutoUpgradeToggle.Value
    if isUpgrading then
        task.spawn(upgradeLoop)
    end
end)
Options.AutoUpgradeToggle:SetValue(false)
-----------------
-----------------
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("BrainrotScript")
SaveManager:SetFolder("BrainrotScript")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
Window:SelectTab(1)
