if not game:IsLoaded() then game.Loaded:Wait() end

if not getgenv().MTAPIMutex then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/camdehudson-max/utils/refs/heads/main/core.lua", true))()
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams            = game:GetService("Teams")
local Workspace        = game:GetService("Workspace")
local lPlayer          = Players.LocalPlayer

local enabled     = false
local hitboxSize  = 10
local showUI      = true
local connections = {}
local players     = {}
local defaultProps = {}

-- ─── settings (edit these) ───────────────────────────────────────────────────
local TRANSPARENCY  = 1    -- 1 = invisible, 0 = solid
local IGNORE_TEAM   = true -- ignore own team
local IGNORE_DEAD   = true -- ignore dead players
local IGNORE_SIT    = true -- ignore sitting players
local IGNORE_FF     = true -- ignore forcefielded players

-- ─── Drawing UI ──────────────────────────────────────────────────────────────

local BG = Drawing.new("Square")
BG.Filled      = true
BG.Color       = Color3.fromRGB(15, 15, 15)
BG.Transparency = 0.45
BG.Size        = Vector2.new(130, 70)

local Border = Drawing.new("Square")
Border.Filled      = false
Border.Color       = Color3.fromRGB(60, 60, 60)
Border.Transparency = 1
Border.Thickness   = 1
Border.Size        = Vector2.new(130, 70)

local TitleText = Drawing.new("Text")
TitleText.Size  = 14
TitleText.Font  = Drawing.Fonts.UI
TitleText.Color = Color3.fromRGB(180, 180, 180)
TitleText.Outline = true
TitleText.Text  = "HITBOX EXTENDER"

local Divider = Drawing.new("Line")
Divider.Color       = Color3.fromRGB(60, 60, 60)
Divider.Transparency = 1
Divider.Thickness   = 1

local StatusText = Drawing.new("Text")
StatusText.Size   = 13
StatusText.Font   = Drawing.Fonts.UI
StatusText.Color  = Color3.fromRGB(255, 80, 80)
StatusText.Outline = false
StatusText.Text   = "HB * OFF"

local SizeText = Drawing.new("Text")
SizeText.Size   = 13
SizeText.Font   = Drawing.Fonts.UI
SizeText.Color  = Color3.fromRGB(150, 150, 150)
SizeText.Outline = false
SizeText.Text   = "SIZE: " .. hitboxSize

local TransText = Drawing.new("Text")
TransText.Size   = 13
TransText.Font   = Drawing.Fonts.UI
TransText.Color  = Color3.fromRGB(150, 150, 150)
TransText.Outline = false
TransText.Text   = "TRANS: " .. TRANSPARENCY

local function updateUI()
    if enabled then
        StatusText.Text  = "HB * ON"
        StatusText.Color = Color3.fromRGB(80, 255, 80)
        Border.Color     = Color3.fromRGB(80, 255, 80)
    else
        StatusText.Text  = "HB * OFF"
        StatusText.Color = Color3.fromRGB(255, 80, 80)
        Border.Color     = Color3.fromRGB(60, 60, 60)
    end
    SizeText.Text  = "SIZE: " .. hitboxSize
    TransText.Text = "TRANS: " .. string.format("%.1f", TRANSPARENCY)
end

local function setUIVisible(v)
    BG.Visible      = v
    Border.Visible  = v
    TitleText.Visible = v
    Divider.Visible = v
    StatusText.Visible = v
    SizeText.Visible = v
    TransText.Visible = v
end

table.insert(connections, RunService.RenderStepped:Connect(function()
    local vp = Workspace.CurrentCamera.ViewportSize
    local w, h = 130, 70
    local x = vp.X - w - 10
    local y = vp.Y - h - 10

    BG.Size     = Vector2.new(w, h)
    Border.Size = Vector2.new(w, h)
    BG.Position     = Vector2.new(x, y)
    Border.Position = Vector2.new(x, y)

    local tw = TitleText.TextBounds.X
    TitleText.Position = Vector2.new(x + (w - tw) / 2, y + 6)

    Divider.From = Vector2.new(x + 1,   y + 22)
    Divider.To   = Vector2.new(x + w - 1, y + 22)

    StatusText.Position = Vector2.new(x + 8, y + 27)
    SizeText.Position   = Vector2.new(x + 8, y + 43)
    TransText.Position  = Vector2.new(x + 8, y + 57)

    setUIVisible(showUI)
end))

-- ─── team / state checks ─────────────────────────────────────────────────────

local function isTeammate(player, playerChar)
    if not IGNORE_TEAM then return false end
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
    if not IGNORE_DEAD then return false end
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
    if not IGNORE_SIT or not playerChar then return false end
    local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")
    return humanoid ~= nil and humanoid.Sit == true
end

local function isFFed(playerChar)
    if not IGNORE_FF or not playerChar then return false end
    if game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then
        local head = playerChar:FindFirstChild("Head")
        return head and head.Material == Enum.Material.ForceField or false
    end
    local ff = playerChar:FindFirstChildWhichIsA("ForceField")
    return ff ~= nil and ff.Visible == true
end

-- ─── local collision fix (walk inside hitboxes) ──────────────────────────────

local function setLocalCollisions(state)
    local char = lPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CanCollide = state end)
        end
    end
end

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

local function applyToChar(player, char)
    if not char or not defaultProps[player] then return end
    local shouldApply = enabled
        and not isTeammate(player, char)
        and not isSitting(char)
        and not isFFed(char)
        and not isDead(player, char)

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local stored = defaultProps[player]["HumanoidRootPart"]
    if not stored then
        stored = { Size = hrp.Size, Transparency = hrp.Transparency, CanCollide = hrp.CanCollide, Massless = hrp.Massless }
        defaultProps[player]["HumanoidRootPart"] = stored
    end

    if shouldApply then
        pcall(function()
            hrp.Size         = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            hrp.Transparency = TRANSPARENCY
            hrp.CanCollide   = false
        end)
    else
        pcall(function()
            hrp.Size         = stored.Size
            hrp.Transparency = stored.Transparency
            hrp.CanCollide   = stored.CanCollide
        end)
    end
end

local function resetChar(player, char)
    if not char or not defaultProps[player] then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local stored = defaultProps[player]["HumanoidRootPart"]
    if stored then
        pcall(function()
            hrp.Size         = stored.Size
            hrp.Transparency = stored.Transparency
            hrp.CanCollide   = stored.CanCollide
        end)
    end
end

-- ─── player tracking ─────────────────────────────────────────────────────────

local function addPlayer(player)
    if players[player] or player == lPlayer then return end
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
    players[player] = nil
end

local function updateAll()
    for player, entry in pairs(players) do
        applyToChar(player, entry.char)
    end
end

-- ─── render loop ─────────────────────────────────────────────────────────────

table.insert(connections, RunService.RenderStepped:Connect(function()
    if not enabled then
        setLocalCollisions(true)
        return
    end
    setLocalCollisions(false)
    for player, entry in pairs(players) do
        if entry.char then applyToChar(player, entry.char) end
    end
end))

-- ─── keybinds ────────────────────────────────────────────────────────────────

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.X then
        enabled = not enabled
        if not enabled then updateAll() end
        updateUI()

    elseif input.KeyCode == Enum.KeyCode.LeftAlt then
        showUI = not showUI

    elseif input.KeyCode == Enum.KeyCode.RightBracket then
        hitboxSize = hitboxSize + 2
        updateUI()

    elseif input.KeyCode == Enum.KeyCode.Minus then
        hitboxSize = math.max(2, hitboxSize - 2)
        updateUI()

    elseif input.KeyCode == Enum.KeyCode.Equals then
        TRANSPARENCY = math.max(0, TRANSPARENCY - 0.1)
        updateUI()

    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        TRANSPARENCY = math.min(1, TRANSPARENCY + 0.1)
        updateUI()

    elseif input.KeyCode == Enum.KeyCode.RightShift then
        enabled = false
        updateAll()
        setLocalCollisions(true)
        for _, c in ipairs(connections) do c:Disconnect() end
        BG:Remove(); Border:Remove(); TitleText:Remove()
        Divider:Remove(); StatusText:Remove(); SizeText:Remove(); TransText:Remove()
    end
end))

-- middle mouse suppress
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton3 then
        enabled = false
        updateAll()
        updateUI()
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton3 then
        enabled = true
        updateUI()
    end
end))

-- FOV binds
local fovBinds = {
    [Enum.KeyCode.End]      = 120,
    [Enum.KeyCode.Delete]   = 60,
    [Enum.KeyCode.PageUp]   = 72,
    [Enum.KeyCode.PageDown] = 92,
}
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and fovBinds[input.KeyCode] then
        Workspace.CurrentCamera.FieldOfView = fovBinds[input.KeyCode]
    end
end))

-- ─── population ──────────────────────────────────────────────────────────────

for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

lPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateAll()
end)

updateAll()
updateUI()
