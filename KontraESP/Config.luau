-- KontraESP / Config
-- All the knobs for your player tracker live here.
-- Edit these instead of touching the main module.

local Config = {}

-- ==== Who gets tracked =====================================================
Config.ShowEnemies = true    -- players on the other team
Config.ShowTeammates = false -- set true if you want teammate outlines too
Config.ShowSelf = false      -- track your own character (usually false)
Config.TreatTeamlessAsEnemy = true -- players with no Team: enemy or ignored?

-- ==== Highlight (the through-wall outline) ================================
Config.EnemyFillColor = Color3.fromRGB(255, 45, 45)
Config.EnemyOutlineColor = Color3.fromRGB(255, 0, 0)
Config.TeammateFillColor = Color3.fromRGB(60, 255, 90)
Config.TeammateOutlineColor = Color3.fromRGB(0, 220, 60)

Config.FillTransparency = 0.65    -- 0 = solid, 1 = invisible fill
Config.OutlineTransparency = 0    -- keep low so the outline pops

-- AlwaysOnTop = visible through walls. Occluded = only when in view.
Config.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

-- ==== Nameplate ============================================================
Config.ShowNameplates = true
Config.ShowHealth = true
Config.ShowDistance = true
Config.NameplateAlwaysOnTop = true -- false = nameplate hides behind walls
Config.DistanceUnit = "m"

-- ==== Range / visibility ===================================================
Config.MaxDistance = 300 -- studs; nil = unlimited
-- Optional fair-play check: only show enemies you can actually see.
-- Raycasts are throttled, so this is cheap, but it removes the wall hack.
Config.RequireLineOfSight = false
Config.LineOfSightInterval = 0.1 -- seconds between raycasts per player

return Config
