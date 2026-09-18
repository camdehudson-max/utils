if not game:IsLoaded() then game.Loaded:Wait() end

if not getgenv().MTAPIMutex then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/camdehudson-max/utils/refs/heads/main/core.lua", true))()
end

local Library    = loadstring(game:HttpGet("https://raw.githubusercontent.com/RectangularObject/LinoriaLib/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/RectangularObject/LinoriaLib/main/addons/SaveManager.lua"))()
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("HBE")

local Teams      = game:GetService("Teams")
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local lPlayer    = Players.LocalPlayer
local players    = {}
local defaultProps = {}

-- ─── helpers ────────────────────────────────────────────────────────────────

local function updateList(list)
    list:SetValues()
    list:Display()
end

local function isTeammate(player, playerChar)
    local placeId = game.PlaceId
    local gameId  = game.GameId
    if gameId == 718936923 then
        if not lPlayer.Character or not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return true end
        return lPlayer.Character.HumanoidRootPart.Color == playerChar.HumanoidRootPart.Color
    elseif placeId == 633284182 then
        if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("TeamValue") then return true end
        return lPlayer.PlayerData.TeamValue.Value == player.PlayerData.TeamValue.Value
    elseif placeId == 2029250188 then
        if not lPlayer.Character or not playerChar then return true end
        return lPlayer.Character.Parent == playerChar.Parent
    elseif placeId == 2978450615 then
        return getrenv()._G.PlayerProfiles.Data[lPlayer.Name].Team == getrenv()._G.PlayerProfiles.Data[player.Name].Team
    elseif placeId == 8770868695 then
        if not lPlayer.Character or not playerChar or not player.Team then return true end
        if player.Team.Name == "Dead" or player.Team.Name == "Inactive" then return true end
        return lPlayer.Character.Parent == playerChar.Parent
    elseif placeId == 5884786982 then
        if not lPlayer.Character or not playerChar then return true end
        return lPlayer.Character.Name ~= "Killer" and playerChar.Name ~= "Killer"
    elseif gameId == 2162282815 then
        if not player:FindFirstChild("SelectedTeam") then return true end
        return player.SelectedTeam.Value == lPlayer.SelectedTeam.Value
    elseif placeId == 1240644540 then
        local tm = require(game:GetService("ReplicatedStorage").Scripts.Modules.PlayerModule)
        if not tm or not tm.IsPlayerSurvivor then return true end
        return tm.IsPlayerSurvivor(nil, player) == true and tm.IsPlayerSurvivor(nil, lPlayer) == true
    elseif placeId == 10236714118 then
        if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("Team") then return true end
        return lPlayer.PlayerData.Team.Value == player.PlayerData.Team.Value
    elseif placeId == 2622527242 then
        if not player.Team then return true end
        local function getAlignment(name)
            if name == "Class-D Personnel" or name == "Chaos Insurgency" then return "Chads"
            elseif name == "Facility Personnel" or name == "Security Department" or name == "Mobile Task Force" then return "Crayon Eaters"
            elseif name == "SCPs" or name == "Serpent's Hand" then return "Menaces"
            elseif name == "Global Occult Coalition" then return "GOC"
            elseif name == "Unusual Incidents Unit" then return "UIU"
            end
            return nil
        end
        local s = getAlignment(lPlayer.Team and lPlayer.Team.Name or "")
        local p = getAlignment(player.Team.Name)
        if s == "UIU" or p == "UIU" then
            if s == "Crayon Eaters" or p == "Crayon Eaters" or s == "GOC" or p == "GOC" then return true end
        end
        if lPlayer.Team == player.Team then return true end
        return s ~= nil and s == p
    elseif gameId == 1934496708 then
        local ff = Workspace:FindFirstChild("FriendlyFire")
        if ff and ff.Value then return false end
        if not player.Team or player.Team.Name == "LOBBY" or lPlayer.Team.Name == "LOBBY" then return true end
        local tm = require(Workspace:WaitForChild("Teams"))
        return lPlayer.Team == player.Team
            or tm[lPlayer.Team.Name] == tm[player.Team.Name]
            or (tm[lPlayer.Team.Name] == "CI" and tm[player.Team.Name] == "CD")
            or (tm[player.Team.Name] == "CI" and tm[lPlayer.Team.Name] == "CD")
    end
    return lPlayer.Team == player.Team
end

local function isDead(player, playerChar)
    if not playerChar then return true end
    local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")
    if game.PlaceId == 6172932937 then
        local rd = player:FindFirstChild("ragdolled")
        return rd and rd.Value or false
    elseif game.GameId == 718936923 then
        return playerChar:FindFirstChild("Dead") ~= nil
    end
    return humanoid and humanoid:GetState() == Enum.HumanoidStateType.Dead or false
end

local function isSitting(playerChar)
    if not playerChar then return false end
    local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")
    return Toggles.extenderSitCheck.Value and humanoid ~= nil and humanoid.Sit == true
end

local function isFFed(playerChar)
    if not playerChar then return false end
    if game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then
        local head = playerChar:FindFirstChild("Head")
        return head and head.Material == Enum.Material.ForceField or false
    end
    local ff = playerChar:FindFirstChildWhichIsA("ForceField")
    return Toggles.extenderFFCheck.Value and ff ~= nil and ff.Visible == true
end

-- ─── UI ─────────────────────────────────────────────────────────────────────

local mainWindow      = Library:CreateWindow("Hitbox Extender")
local mainTab         = mainWindow:AddTab("Main")
local mainGroupbox    = mainTab:AddLeftGroupbox("Hitbox Extender")
local ignoresGroupbox = mainTab:AddRightGroupbox("Ignores")
local collGroupbox    = mainTab:AddRightGroupbox("Collisions")
local miscGroupbox    = mainTab:AddLeftGroupbox("Keybinds")

mainGroupbox:AddToggle("extenderToggled",      { Text = "Toggle" })
mainGroupbox:AddSlider("extenderSize",         { Text = "Size",         Min = 2, Max = 100, Default = 10,  Rounding = 1 })
mainGroupbox:AddSlider("extenderTransparency", { Text = "Transparency", Min = 0, Max = 1,   Default = 1,   Rounding = 2 })
mainGroupbox:AddInput("customPartName",        { Text = "Custom Part Name", Default = "HeadHB" })
mainGroupbox:AddDropdown("extenderPartList",   { Text = "Body Parts", AllowNull = true, Multi = true,
    Values = { "Custom Part", "Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
    Default = "HumanoidRootPart" })

ignoresGroupbox:AddToggle("extenderSitCheck",            { Text = "Ignore Sitting Players" })
ignoresGroupbox:AddToggle("extenderFFCheck",             { Text = "Ignore Forcefielded Players" })
ignoresGroupbox:AddToggle("ignoreSelectedPlayersToggled",{ Text = "Ignore Selected Players" })
ignoresGroupbox:AddDropdown("ignorePlayerList",          { Text = "Players", AllowNull = true, Multi = true, Values = {} })
ignoresGroupbox:AddToggle("ignoreOwnTeamToggled",        { Text = "Ignore Own Team" })
ignoresGroupbox:AddToggle("ignoreSelectedTeamsToggled",  { Text = "Ignore Selected Teams" })
ignoresGroupbox:AddDropdown("ignoreTeamList",            { Text = "Teams", AllowNull = true, Multi = true, Values = {} })

collGroupbox:AddToggle("collisionsToggled", { Text = "Enable Collisions" })

miscGroupbox:AddLabel("Toggle UI"):AddKeyPicker("menuKeybind",       { Default = "End",  NoUI = true, Text = "Menu Keybind" })
miscGroupbox:AddLabel("Force Update"):AddKeyPicker("forceUpdateKeybind", { Default = "Home", NoUI = true, Text = "Force Update Keybind" })
Library.ToggleKeybind = Options.menuKeybind

SaveManager:BuildConfigSection(mainTab)
SaveManager:LoadAutoloadConfig()

-- ─── local player collision fix (lets you walk inside hitboxes) ──────────────

local function disableLocalCollisions()
    local char = lPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = false end)
        end
    end
end

local function enableLocalCollisions()
    local char = lPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = true end)
        end
    end
end

Toggles.extenderToggled:GetPropertyChangedSignal and nil
-- applied every frame below instead

-- ─── hitbox logic ────────────────────────────────────────────────────────────

local function storeDefaults(player, char)
    defaultProps[player] = {}
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            defaultProps[player][part.Name] = {
                Size         = part.Size,
                Transparency = part.Transparency,
                CanCollide   = part.CanCollide,
                Massless     = part.Massless,
            }
        end
    end
end

local function isPartActive(partName)
    for _, v in pairs(Options.extenderPartList:GetActiveValues()) do
        if partName == v then return true end
        if v == "Custom Part" and string.match(partName, Options.customPartName.Value) then return true end
        if v == "Left Arm"  and string.match(partName,"Left")  and (string.match(partName,"Arm")  or string.match(partName,"Hand")) then return true end
        if v == "Right Arm" and string.match(partName,"Right") and (string.match(partName,"Arm")  or string.match(partName,"Hand")) then return true end
        if v == "Left Leg"  and string.match(partName,"Left")  and (string.match(partName,"Leg")  or string.match(partName,"Foot")) then return true end
        if v == "Right Leg" and string.match(partName,"Right") and (string.match(partName,"Leg")  or string.match(partName,"Foot")) then return true end
    end
    return false
end

local function applyToChar(player, char)
    if not char or not defaultProps[player] then return end
    local ignored = (Toggles.ignoreOwnTeamToggled.Value and isTeammate(player, char))
        or (Toggles.ignoreSelectedTeamsToggled.Value and table.find(Options.ignoreTeamList:GetActiveValues(), tostring(player.Team)))
        or (Toggles.ignoreSelectedPlayersToggled.Value and table.find(Options.ignorePlayerList:GetActiveValues(), player.Name))
    local shouldApply = Toggles.extenderToggled.Value
        and not ignored
        and not isSitting(char)
        and not isFFed(char)
        and not isDead(player, char)

    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local stored = defaultProps[player][part.Name]
            if not stored then
                stored = { Size = part.Size, Transparency = part.Transparency, CanCollide = part.CanCollide, Massless = part.Massless }
                defaultProps[player][part.Name] = stored
            end
            if shouldApply and isPartActive(part.Name) then
                local s = Options.extenderSize.Value
                pcall(function()
                    part.Size         = Vector3.new(s, s, s)
                    part.Transparency = Options.extenderTransparency.Value
                    part.CanCollide   = false
                    part.Massless     = part.Name ~= "HumanoidRootPart" and true or part.Massless
                    if part.Name == "Head" then
                        local face = part:FindFirstChild("face")
                        if face then face.Transparency = Options.extenderTransparency.Value end
                    end
                end)
            else
                pcall(function()
                    part.Size         = stored.Size
                    part.Transparency = stored.Transparency
                    part.CanCollide   = stored.CanCollide
                    part.Massless     = stored.Massless
                    if part.Name == "Head" then
                        local face = part:FindFirstChild("face")
                        if face then face.Transparency = stored.Transparency end
                    end
                end)
            end
        end
    end
end

local function resetChar(player, char)
    if not char or not defaultProps[player] then return end
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local stored = defaultProps[player][part.Name]
            if stored then
                pcall(function()
                    part.Size         = stored.Size
                    part.Transparency = stored.Transparency
                    part.CanCollide   = stored.CanCollide
                    part.Massless     = stored.Massless
                end)
            end
        end
    end
end

-- ─── player tracking ────────────────────────────────────────────────────────

local function addPlayer(player)
    if players[player] or player == lPlayer then return end
    table.insert(Options.ignorePlayerList.Values, player.Name)
    updateList(Options.ignorePlayerList)

    local entry = { char = player.Character }
    players[player] = entry

    local function onCharAdded(char)
        entry.char = char
        defaultProps[player] = nil
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait()
        storeDefaults(player, char)
        applyToChar(player, char)

        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if humanoid.Health <= 0 then applyToChar(player, char) end
            end)
            humanoid.StateChanged:Connect(function(_, state)
                if state == Enum.HumanoidStateType.Dead then applyToChar(player, char) end
            end)
        end
        char.ChildAdded:Connect(function(child)
            if game.GameId == 718936923 and child.Name == "Dead" then applyToChar(player, char) return end
            if child:IsA("ForceField") then applyToChar(player, char) end
        end)
        char.ChildRemoved:Connect(function(child)
            if child:IsA("ForceField") then applyToChar(player, char) end
        end)
        if game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then
            local head = char:FindFirstChild("Head")
            if head then
                head:GetPropertyChangedSignal("Material"):Connect(function() applyToChar(player, char) end)
            end
        end
    end

    player.CharacterAdded:Connect(onCharAdded)
    player.CharacterRemoving:Connect(function()
        defaultProps[player] = nil
        entry.char = nil
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        applyToChar(player, entry.char)
    end)

    if game.PlaceId == 6172932937 then
        local rd = player:WaitForChild("ragdolled")
        rd.Changed:Connect(function() applyToChar(player, entry.char) end)
    end
    if game.GameId == 1934496708 then
        local ff = Workspace:WaitForChild("FriendlyFire")
        ff.Changed:Connect(function() applyToChar(player, entry.char) end)
    end

    if player.Character then task.spawn(onCharAdded, player.Character) end
end

local function removePlayer(player)
    if not players[player] then return end
    resetChar(player, players[player].char)
    defaultProps[player] = nil
    local idx = table.find(Options.ignorePlayerList.Values, player.Name)
    if idx then table.remove(Options.ignorePlayerList.Values, idx) end
    updateList(Options.ignorePlayerList)
    players[player] = nil
end

-- ─── update all ─────────────────────────────────────────────────────────────

local function updateAll()
    for player, entry in pairs(players) do
        applyToChar(player, entry.char)
    end
end

-- ─── render loop — every frame, no throttle ──────────────────────────────────

RunService:BindToRenderStep("HBE", Enum.RenderPriority.Camera.Value - 1, function()
    if not Toggles.extenderToggled.Value then
        enableLocalCollisions()
        return
    end
    disableLocalCollisions()
    for player, entry in pairs(players) do
        if entry.char then
            applyToChar(player, entry.char)
        end
    end
end)

-- ─── UI callbacks ────────────────────────────────────────────────────────────

Options.forceUpdateKeybind:OnClick(updateAll)
Toggles.extenderToggled:OnChanged(updateAll)
Options.extenderSize:OnChanged(updateAll)
Options.extenderTransparency:OnChanged(updateAll)
Options.customPartName:OnChanged(updateAll)
Options.extenderPartList:OnChanged(updateAll)
Toggles.extenderSitCheck:OnChanged(updateAll)
Toggles.extenderFFCheck:OnChanged(updateAll)
Toggles.ignoreSelectedPlayersToggled:OnChanged(updateAll)
Options.ignorePlayerList:OnChanged(updateAll)
Toggles.ignoreOwnTeamToggled:OnChanged(updateAll)
Toggles.ignoreSelectedTeamsToggled:OnChanged(updateAll)
Options.ignoreTeamList:OnChanged(updateAll)
Toggles.collisionsToggled:OnChanged(updateAll)

-- ─── population ─────────────────────────────────────────────────────────────

for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end

for _, team in pairs(Teams:GetTeams()) do
    if team:IsA("Team") then
        table.insert(Options.ignoreTeamList.Values, team.Name)
        updateList(Options.ignoreTeamList)
    end
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

Teams.ChildAdded:Connect(function(team)
    if team:IsA("Team") then
        table.insert(Options.ignoreTeamList.Values, team.Name)
        updateList(Options.ignoreTeamList)
    end
end)
Teams.ChildRemoved:Connect(function(team)
    if team:IsA("Team") then
        local idx = table.find(Options.ignoreTeamList.Values, team.Name)
        if idx then table.remove(Options.ignoreTeamList.Values, idx) end
        updateList(Options.ignoreTeamList)
    end
end)

lPlayer:GetAttributeChangedSignal("Team"):Connect(updateAll)
lPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateAll()
end)

updateAll()
Library:Notify("Hitbox Extender loaded")
Library:Notify("Press " .. Library.ToggleKeybind.Value .. " to toggle menu")
