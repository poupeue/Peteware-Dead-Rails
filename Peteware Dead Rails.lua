-- Required locals



-- Aimbot Function
local RunService = game:GetService("RunService")
local Cam = workspace.CurrentCamera
local Player = game:GetService("Players").LocalPlayer

local validNPCs = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local function isNPC(obj)
    return obj:IsA("Model") 
        and obj:FindFirstChild("Humanoid")
        and obj.Humanoid.Health > 0
        and obj:FindFirstChild("Head")
        and obj:FindFirstChild("HumanoidRootPart")
        and not game:GetService("Players"):GetPlayerFromCharacter(obj)
end

local function updateNPCs()
    local tempTable = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isNPC(obj) then
            tempTable[obj] = true
        end
    end
    for i = #validNPCs, 1, -1 do
        if not tempTable[validNPCs[i]] then
            table.remove(validNPCs, i)
        end
    end
    for obj in pairs(tempTable) do
        if not table.find(validNPCs, obj) then
            table.insert(validNPCs, obj)
        end
    end
end

local function handleDescendant(descendant)
    if isNPC(descendant) then
        table.insert(validNPCs, descendant)
        local humanoid = descendant:WaitForChild("Humanoid")
        humanoid.Destroying:Connect(function()
            for i = #validNPCs, 1, -1 do
                if validNPCs[i] == descendant then
                    table.remove(validNPCs, i)
                    break
                end
            end
        end)
    end
end

workspace.DescendantAdded:Connect(handleDescendant)

local function predictPos(target)
    local rootPart = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not rootPart or not head then
        return head and head.Position or rootPart and rootPart.Position
    end
    local velocity = rootPart.Velocity
    local predictionTime = 0.02
    local basePosition = rootPart.Position + velocity * predictionTime
    local headOffset = head.Position - rootPart.Position
    return basePosition + headOffset
end

local function getTarget()
    local nearest = nil
    local minDistance = math.huge
    local viewportCenter = Cam.ViewportSize / 2
    raycastParams.FilterDescendantsInstances = {Player.Character}
    for _, npc in ipairs(validNPCs) do
        local predictedPos = predictPos(npc)
        local screenPos, visible = Cam:WorldToViewportPoint(predictedPos)
        if visible and screenPos.Z > 0 then
            local ray = workspace:Raycast(
                Cam.CFrame.Position,
                (predictedPos - Cam.CFrame.Position).Unit * 1000,
                raycastParams
            )
            if ray and ray.Instance:IsDescendantOf(npc) then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearest = npc
                end
            end
        end
    end
    return nearest
end

local function aim(targetPosition)
    local currentCF = Cam.CFrame
    local targetDirection = (targetPosition - currentCF.Position).Unit
    local smoothFactor = 0.581
    local newLookVector = currentCF.LookVector:Lerp(targetDirection, smoothFactor)
    Cam.CFrame = CFrame.new(currentCF.Position, currentCF.Position + newLookVector)
end

local heartbeat = RunService.Heartbeat
local lastUpdate = 0
local UPDATE_INTERVAL = 0.4

local aimbotEnabled = false

heartbeat:Connect(function(dt)
    lastUpdate = lastUpdate + dt
    if lastUpdate >= UPDATE_INTERVAL then
        updateNPCs()
        lastUpdate = 0
    end
    if aimbotEnabled then
        local target = getTarget()
        if target then
            local predictedPosition = predictPos(target)
            aim(predictedPosition)
        end
    end
end)

-- npc remove
workspace.DescendantRemoving:Connect(function(descendant)
    if isNPC(descendant) then
        for i = #validNPCs, 1, -1 do
            if validNPCs[i] == descendant then
                table.remove(validNPCs, i)
                break
            end
        end
    end
end)
-- Aimbot Function


-- ESP Function
local ESPHandles = {}
local ESPItemEnabled = false
local ESPMobEnabled = false

local function CreateESP(object, color)
    if not object or not object.PrimaryPart then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.Parent = object

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = object.PrimaryPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = object

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = object.Name
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.TextColor3 = color
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = 7
    textLabel.Parent = billboard

    ESPHandles[object] = {Highlight = highlight, Billboard = billboard}
end

local function ClearESP()
    for obj, handles in pairs(ESPHandles) do
        if handles.Highlight then handles.Highlight:Destroy() end
        if handles.Billboard then handles.Billboard:Destroy() end
    end
    ESPHandles = {}
end

local function UpdateESP()
    ClearESP()

    -- ESP for Items 
    local runtimeItems = workspace:FindFirstChild("RuntimeItems")
    if runtimeItems then
        for _, item in ipairs(runtimeItems:GetDescendants()) do
            if item:IsA("Model") then
                CreateESP(item, Color3.new(154, 156, 143)) -- Light Grey for Items
            end
        end
    end

local function AutoUpdateESP()
    while ESPItemEnabled do
        UpdateESP()
        wait() 
    end
end

    -- ESP mobs
    local nightEnemies = workspace:FindFirstChild("NightEnemies")
    if nightEnemies then
        for _, enemy in ipairs(nightEnemies:GetDescendants()) do
            if enemy:IsA("Model") then
                CreateESP(enemy, Color3.new(1, 0, 0)) -- Red for Night Enemies
            end
        end
    end

    local destroyedHouse = workspace:FindFirstChild("RandomBuildings") and workspace.RandomBuildings:FindFirstChild("DestroyedHouse")
    local zombiePart = destroyedHouse and destroyedHouse:FindFirstChild("StandaloneZombiePart")
    local zombies = zombiePart and zombiePart:FindFirstChild("Zombies")
    if zombies then
        for _, zombie in ipairs(zombies:GetChildren()) do
            if zombie:IsA("Model") then
                CreateESP(zombie, Color3.new(1, 0, 0)) -- Red for Zombies
            end
        end
    end
end

local function AutoUpdateESP2()
    while ESPMobEnabled do
        UpdateESP()
        wait() 
    end
end
-- ESP Function


-- Whitelist Authentication System


local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
local hwidPaste = loadstring(game:HttpGet("https://raw.githubusercontent.com/poupeue/Peteware-Whitelist/main/Whitelist%20Check"))()
print("HWID Paste:", hwidPaste)
print("Client HWID:", hwid)
wait(0.5)        

local StarterGui = game:GetService("StarterGui")
local function openDevConsole()
    StarterGui:SetCore("DevConsoleVisible", true)
end
openDevConsole()

print("[Peteware]: [1/3] Starting authentication")
wait(1.5)
print("[Peteware]: [2/3] Authentication in progress")
wait(2)

local isWhitelisted = false
for i, v in pairs(hwidPaste) do
    if v == hwid then
        isWhitelisted = true
        break
    end
end

if isWhitelisted then
    print("[Peteware]: [3/3] Whitelisted, Loading Peteware")
    print([[ 
 _______  _______ _________ _______           _______  _______  _______ 
(  ____ )(  ____ \\__   __/(  ____ \|\     /|(  ___  )(  ____ )(  ____ \
| (    )|| (    \/   ) (   | (    \/| )   ( || (   ) || (    )|| (    \/
| (____)|| (__       | |   | (__    | | _ | || (___) || (____)|| (__    
|  _____)|  __)      | |   |  __)   | |( )| ||  ___  ||     __)|  __)   
| (      | (         | |   | (      | || || || (   ) || (\ (   | (      
| )      | (____/\   | |   | (____/\| () () || )   ( || ) \ \__| (____/\
|/       (_______/   )_(   (_______/(_______)|/     \||/   \__/(_______/
                                                                        
    ]])
    wait(2)

    local function closeDevConsole()
        StarterGui:SetCore("DevConsoleVisible", false)
    end
    closeDevConsole()
    
    
-- Whitelist Authentication System
    
    
-- Main GUI    
    
    
local OrionLib = loadstring(game:HttpGet(('https://pastebin.com/raw/WRUyYTdY')))()

local Player = game.Players.LocalPlayer

local Window = OrionLib:MakeWindow({Name = "Peteware Dead Rails", HidePremium = false, SaveConfig = true, IntroText = "☠️Dead Rails☠️"})
   
local Tab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

Tab:AddToggle({
    Name = "Bring Nearby Items",
    Default = false,
    Callback = function(Value)
      local runtimeItems = workspace:FindFirstChild("RuntimeItems")
       if not runtimeItems then
           warn("There are no nearby items at the moment.")
           return
       end

       local ps = game:GetService("Players").LocalPlayer
       local ch = ps.Character or ps.CharacterAdded:Wait()
       local HumanoidRootPart = ch:WaitForChild("HumanoidRootPart")

       for _, item in ipairs(runtimeItems:GetDescendants()) do
           if item:IsA("Model") then
               if item.PrimaryPart then
                   local offset = HumanoidRootPart.CFrame.LookVector * 5
                   item:SetPrimaryPartCFrame(HumanoidRootPart.CFrame + offset)
               else
                   warn(item.Name .. " has no PrimaryPart .")
                end
            end
        end
    end
})

Tab:AddToggle({
    Name = "Refuel Train",
    Default = false,
    Callback = function(Value)
      local runtimeItems = workspace:FindFirstChild("RuntimeItems")
       if not runtimeItems then
           warn("Cannot Refuel Train at the moment.")
           warn("Please Try again when there are items nearby.")
           return
       end

       local ps = game:GetService("Players").LocalPlayer
       local ch = ps.Character or ps.CharacterAdded:Wait()
       local HumanoidRootPart = ch:WaitForChild("HumanoidRootPart")
       local fuelPos =  game.Workspace.Train:FindFirstChild("FireBase")

       for _, item in ipairs(runtimeItems:GetDescendants()) do
           if item:IsA("Model") then
               if item.PrimaryPart then
                   if item:GetAttribute("Fuel") ~= nil then
                   local offset = fuelPos.CFrame.Vector3 * 0
                   item:SetPrimaryPartCFrame(fuelPos.CFrame + offset)
               else
                   warn(item.Name .. " has no PrimaryPart .")
                end
            end
        end
    end
})
 
local Tab = Window:MakeTab({
	Name = "Combat",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})
  
Tab:AddToggle({
    Name = "Mob Aimbot",
    Default = false,
    Callback = function(Value)
      aimbotEnabled = Value
      end
})
  
local Tab = Window:MakeTab({
	Name = "ESP",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})  
  
Tab:AddToggle({
    Name = "Mob ESP",
    Default = false,
    Callback = function(Value)
      ESPMobEnabled = Value
      if Value then
            UpdateESP()
            coroutine.wrap(AutoUpdateESP)()
        else
            ClearESP()
        end
    end
})  

Tab:AddToggle({
    Name = "Item ESP",
    Default = false,
    Callback = function(Value)
      ESPItemEnabled = Value
      if Value then
            UpdateESP()
            coroutine.wrap(AutoUpdateESP)()
        else
            ClearESP()
        end
    end
})  
  
local Tab = Window:MakeTab({
	Name = "Other",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})
    
Tab:AddButton({
	Name = "Infinite Yield Admin",
	Callback = function()
      		loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Infinite-Yield-28221"))()
  	end    
})     
    
Tab:AddButton({
	Name = "AntiAFK",
	Callback = function()
	    openDevConsole()
	    print("[AntiAFK]: Anti AFK/Idle Enabled.")
      		            local VirtualUser = game:GetService('VirtualUser')
 
game:GetService('Players').LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
	    wait(1)
	    closeDevConsole()
  	end    
})         
    
Tab:AddButton({
	Name = "Hydroxide",
	Callback = function()
      		local owner = "Hosvile"
local branch = "revision"

local function webImport(file)
    return loadstring(game:HttpGetAsync(("https://raw.githubusercontent.com/%s/MC-Hydroxide/%s/%s.lua"):format(owner, branch, file)), file .. '.lua')()
end

webImport("init")
webImport("ui/main")
  	end    
})              
    
Tab:AddButton({
	Name = "FPS Unlocker",
	Callback = function()
local Players = game:GetService("Players")
local player = Players.LocalPlayer
	        print("[FPSUnlock]: FPS Unlocked")
    openDevConsole()
	    wait(1)
	    closeDevConsole()
local UserInputService = game:GetService("UserInputService")
	    setfpscap(360)
	end
})
    
Tab:AddButton({
	Name = "FPS Booster",
	Callback = function()
	    _G.SendNotifications = false
	    _G.Settings = {
    Players = {
        ["Ignore Me"] = true, -- Ignore your Character
        ["Ignore Others"] = true-- Ignore other Characters
    },
    Meshes = {
        Destroy = false, -- Destroy Meshes
        LowDetail = true -- Low detail meshes (NOT SURE IT DOES ANYTHING)
    },
    Images = {
        Invisible = true, -- Invisible Images
        LowDetail = false, -- Low detail images (NOT SURE IT DOES ANYTHING)
        Destroy = false, -- Destroy Images
    },
	    Other = {
	        ["FPS Cap"] = 120, true
	        
	    },        
    ["No Particles"] = true, -- Disables all ParticleEmitter, Trail, Smoke, Fire and Sparkles
    ["No Camera Effects"] = true, -- Disables all PostEffect's (Camera/Lighting Effects)
    ["No Explosions"] = true, -- Makes Explosion's invisible
    ["No Clothes"] = true, -- Removes Clothing from the game
    ["Low Water Graphics"] = true, -- Removes Water Quality
    ["No Shadows"] = true, -- Remove Shadows
    ["Low Rendering"] = true, -- Lower Rendering
    ["Low Quality Parts"] = true -- Lower quality parts
}
	    loadstring(game:HttpGet("https://raw.githubusercontent.com/CasperFlyModz/discord.gg-rips/main/FPSBooster.lua"))()
	    
	    game.Players.LocalPlayer.CharacterAdded:Connect(function()
	        _G.SendNotifications = false
    _G.Settings = {
    Players = {
        ["Ignore Me"] = true, -- Ignore your Character
        ["Ignore Others"] = true-- Ignore other Characters
    },
    Meshes = {
        Destroy = false, -- Destroy Meshes
        LowDetail = true -- Low detail meshes (NOT SURE IT DOES ANYTHING)
    },
    Images = {
        Invisible = true, -- Invisible Images
        LowDetail = false, -- Low detail images (NOT SURE IT DOES ANYTHING)
        Destroy = false, -- Destroy Images
    },
    Other = {
	    ["FPS Cap"] = 120, true
    },   
    ["No Particles"] = true, -- Disables all ParticleEmitter, Trail, Smoke, Fire and Sparkles
    ["No Camera Effects"] = true, -- Disables all PostEffect's (Camera/Lighting Effects)
    ["No Explosions"] = true, -- Makes Explosion's invisible
    ["No Clothes"] = true, -- Removes Clothing from the game
    ["Low Water Graphics"] = true, -- Removes Water Quality
    ["No Shadows"] = true, -- Remove Shadows
    ["Low Rendering"] = true, -- Lower Rendering
    ["Low Quality Parts"] = true -- Lower quality parts
}
	        loadstring(game:HttpGet("https://raw.githubusercontent.com/CasperFlyModz/discord.gg-rips/main/FPSBooster.lua"))()
end)
  	end    
})      
    
local Tab = Window:MakeTab({
	Name = "Settings",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})
    
Tab:AddButton({
	Name = "Open Console",
	Callback = function()
      		pcall(function() keypress(Enum.KeyCode[string.upper("F9")]) end)
  	end    
})

Tab:AddButton({
	Name = "Destroy UI",
	Callback = function()
      		OrionLib:Destroy()
aimbotEnabled = false
ESPItemEnabled = false
ESPMobEnabled = false
  	end    
})

OrionLib:Init()
    
else
    openDevConsole()
    warn("[Peteware]: [3/3] Authentication Failed, Please try and reset your HWID")
    
    wait(1.5)
    
    LocalPlayer:Kick("You are not whitelisted. You have not purchased the script or there is an error with it. Please contact the owner of the script (PouPeuu_V2) for support.")
end



-- Main GUI  