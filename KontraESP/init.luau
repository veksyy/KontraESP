--!nonstrict
-- KontraESP
-- Team-aware player highlight / tracker for Kontra.
--
-- Setup:
--   Put this ModuleScript in ReplicatedStorage as "KontraESP"
--   Keep "Config" as a child ModuleScript of it.
--   Run KontraClient from StarterPlayerScripts (or any LocalScript).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Config = require(script:WaitForChild("Config"))

local ESP = {}
ESP.__index = ESP

-- Shared raycast params (reused every check)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function isTeammate(player, cfg)
	if not LocalPlayer.Team then
		return false
	end
	return player.Team == LocalPlayer.Team
end

local function shouldTrack(player, cfg)
	if player == LocalPlayer then
		return cfg.ShowSelf
	end

	local teammate = isTeammate(player, cfg)
	if teammate then
		return cfg.ShowTeammates
	end

	if player.Team == nil then
		return cfg.TreatTeamlessAsEnemy and cfg.ShowEnemies
	end

	return cfg.ShowEnemies
end

function ESP.new(cfg)
	local self = setmetatable({}, ESP)
	self._config = cfg or Config
	self._entries = {} -- [Player] = entry
	self._connections = {}
	self._running = false
	return self
end

-- ==== Entry lifecycle ======================================================

function ESP:_track(player)
	if self._entries[player] then
		return
	end

	local entry = {
		player = player,
		connections = {},
		highlight = nil,
		billboard = nil,
		nameLabel = nil,
		healthFill = nil,
		distanceLabel = nil,
		humanoid = nil,
		root = nil,
		lastLOS = true,
		lastLOSCheck = 0,
	}
	self._entries[player] = entry

	table.insert(
		entry.connections,
		player.CharacterAdded:Connect(function(character)
			self:_buildCharacter(player, character)
		end)
	)
	table.insert(
		entry.connections,
		player.CharacterRemoving:Connect(function()
			self:_clearCharacter(entry)
		end)
	)

	if player.Character then
		self:_buildCharacter(player, player.Character)
	end
end

function ESP:_untrack(player)
	local entry = self._entries[player]
	if not entry then
		return
	end
	for _, conn in entry.connections do
		conn:Disconnect()
	end
	self:_clearCharacter(entry)
	self._entries[player] = nil
end

function ESP:_clearCharacter(entry)
	if entry.highlight then
		entry.highlight:Destroy()
		entry.highlight = nil
	end
	if entry.billboard then
		entry.billboard:Destroy()
		entry.billboard = nil
	end
	entry.nameLabel = nil
	entry.healthFill = nil
	entry.distanceLabel = nil
	entry.humanoid = nil
	entry.root = nil
end

-- ==== Build visuals for a character =======================================

function ESP:_buildCharacter(player, character)
	local entry = self._entries[player]
	if not entry then
		return
	end

	self:_clearCharacter(entry)

	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then
		return
	end

	entry.humanoid = humanoid
	entry.root = root

	local cfg = self._config

	-- Through-wall highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "KontraESP_Highlight"
	highlight.Adornee = character
	highlight.DepthMode = cfg.DepthMode
	highlight.FillTransparency = cfg.FillTransparency
	highlight.OutlineTransparency = cfg.OutlineTransparency
	highlight.FillColor = cfg.EnemyFillColor
	highlight.OutlineColor = cfg.EnemyOutlineColor
	highlight.Enabled = false
	highlight.Parent = character
	entry.highlight = highlight

	-- Nameplate with health + distance
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "KontraESP_Nameplate"
	billboard.Size = UDim2.fromOffset(200, 46)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = cfg.NameplateAlwaysOnTop
	billboard.MaxDistance = cfg.MaxDistance or 1000
	billboard.LightInfluence = 0
	billboard.Enabled = false
	billboard.Adornee = root

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 17
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Text = player.Name
	nameLabel.Visible = cfg.ShowNameplates
	nameLabel.Parent = frame
	entry.nameLabel = nameLabel

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.7, 0, 0.18, 0)
	barBg.Position = UDim2.fromScale(0.15, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	barBg.BorderSizePixel = 0
	barBg.Visible = cfg.ShowHealth
	barBg.Parent = frame

	local healthFill = Instance.new("Frame")
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = barBg
	entry.healthFill = healthFill

	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Size = UDim2.new(1, 0, 0.24, 0)
	distanceLabel.Position = UDim2.fromScale(0, 0.74)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Font = Enum.Font.Gotham
	distanceLabel.TextSize = 14
	distanceLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
	distanceLabel.TextStrokeTransparency = 0.5
	distanceLabel.Text = ""
	distanceLabel.Visible = cfg.ShowDistance
	distanceLabel.Parent = frame
	entry.distanceLabel = distanceLabel

	billboard.Parent = root
	entry.billboard = billboard
end

-- ==== Per-frame update =====================================================

function ESP:_hasLineOfSight(fromPos, toPos, targetChar)
	local delta = toPos - fromPos
	rayParams.FilterDescendantsInstances = {
		LocalPlayer.Character,
		targetChar,
	}
	local result = workspace:Raycast(fromPos, delta, rayParams)
	return result == nil
end

function ESP:_setVisible(entry, visible)
	if entry.highlight then
		entry.highlight.Enabled = visible
	end
	if entry.billboard then
		entry.billboard.Enabled = visible
	end
end

function ESP:_update()
	local cfg = self._config
	local localChar = LocalPlayer.Character
	local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

	for player, entry in pairs(self._entries) do
		if not shouldTrack(player, cfg) then
			self:_setVisible(entry, false)
			continue
		end

		local humanoid = entry.humanoid
		local root = entry.root
		if not (localRoot and humanoid and root) or humanoid.Health <= 0 then
			self:_setVisible(entry, false)
			continue
		end

		local dist = (root.Position - localRoot.Position).Magnitude
		if cfg.MaxDistance and dist > cfg.MaxDistance then
			self:_setVisible(entry, false)
			continue
		end

		if cfg.RequireLineOfSight then
			local now = os.clock()
			if now - entry.lastLOSCheck >= cfg.LineOfSightInterval then
				entry.lastLOSCheck = now
				entry.lastLOS = self:_hasLineOfSight(localRoot.Position, root.Position, player.Character)
			end
			if not entry.lastLOS then
				self:_setVisible(entry, false)
				continue
			end
		end

		local teammate = isTeammate(player, cfg)
		local fill = teammate and cfg.TeammateFillColor or cfg.EnemyFillColor
		local outline = teammate and cfg.TeammateOutlineColor or cfg.EnemyOutlineColor

		if entry.highlight then
			entry.highlight.FillColor = fill
			entry.highlight.OutlineColor = outline
		end

		if entry.nameLabel then
			entry.nameLabel.Text = player.Name
			entry.nameLabel.TextColor3 = outline
		end

		if entry.healthFill then
			local pct = 0
			if humanoid.MaxHealth > 0 then
				pct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
			end
			entry.healthFill.Size = UDim2.fromScale(pct, 1)
			entry.healthFill.BackgroundColor3 = Color3.fromHSV(0.33 * pct, 0.85, 0.9)
		end

		if entry.distanceLabel then
			entry.distanceLabel.Text = string.format("%d%s", math.floor(dist), cfg.DistanceUnit)
		end

		self:_setVisible(entry, true)
	end
end

-- ==== Public API ===========================================================

function ESP:SetEnabled(enabled)
	self._enabled = enabled
	if not enabled then
		for _, entry in pairs(self._entries) do
			self:_setVisible(entry, false)
		end
	end
end

function ESP:Start()
	if self._running then
		return self
	end
	self._running = true
	self._enabled = true

	for _, player in Players:GetPlayers() do
		if player ~= LocalPlayer then
			self:_track(player)
		end
	end

	table.insert(
		self._connections,
		Players.PlayerAdded:Connect(function(player)
			if player ~= LocalPlayer then
				self:_track(player)
			end
		end)
	)
	table.insert(
		self._connections,
		Players.PlayerRemoving:Connect(function(player)
			self:_untrack(player)
		end)
	)

	table.insert(
		self._connections,
		RunService.RenderStepped:Connect(function()
			if self._enabled then
				self:_update()
			end
		end)
	)

	return self
end

function ESP:Destroy()
	for _, conn in self._connections do
		conn:Disconnect()
	end
	self._connections = {}
	for player in pairs(self._entries) do
		self:_untrack(player)
	end
	self._entries = {}
	self._running = false
end

return ESP
