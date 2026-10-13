--!nonstrict
-- KontraClient  -> StarterPlayer > StarterPlayerScripts (LocalScript)
-- Starts the ESP and gives you a toggle key.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KontraESP = require(ReplicatedStorage:WaitForChild("KontraESP"))

local tracker = KontraESP.new():Start()

-- Toggle the whole overlay with the E key (change as you like).
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		tracker:SetEnabled(not tracker._enabled)
	end
end)
