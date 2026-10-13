# KontraESP

A team-aware player highlight / tracker for your Kontra game. Client-side only,
built entirely from official Roblox Studio APIs (`Highlight`, `BillboardGui`,
`RunService`). No executor, no injection.

## What it does

- **Enemy highlights** through walls with a red outline (teammates optional, green).
- **Nameplates** above each visible enemy: name, health bar and live distance.
- **Team filtering** — uses each player's `Team`/`TeamColor`, so it only ever shows
  what you tell it to.
- **Distance culling** — stops tracking past `MaxDistance`.
- **Optional line-of-sight** (`RequireLineOfSight = true`) if you want a fair-play
  mode instead of a through-wall wallhack.

## Install (Roblox Studio)

1. In `ReplicatedStorage`, add a **ModuleScript** named `KontraESP` and paste
   `KontraESP/init.luau` into it.
2. Add a child **ModuleScript** named `Config` and paste `KontraESP/Config.luau`.
3. In `StarterPlayer > StarterPlayerScripts`, add a **LocalScript** named
   `KontraClient` and paste `KontraClient.client.luau`.

Your tree should look like:

```
ReplicatedStorage
└── KontraESP (ModuleScript)      <- init.luau
    └── Config  (ModuleScript)    <- Config.luau
StarterPlayer
└── StarterPlayerScripts
    └── KontraClient (LocalScript)
```

## Usage

```lua
local KontraESP = require(ReplicatedStorage.KontraESP)
local tracker = KontraESP.new():Start()

tracker:SetEnabled(false) -- hide everything
tracker:SetEnabled(true)  -- show again
tracker:Destroy()         -- remove everything + disconnect
```

## Notes

- Everyone is on a `Team` in a Counter-Blox-style round. Players with no `Team`
  are treated as enemies by default (`TreatTeamlessAsEnemy` in `Config`).
- Highlights only render on the client that runs the script. Nothing is
  replicated to other players.
- `Highlight.DepthMode = AlwaysOnTop` is the actual "see through walls" bit.
  Set it to `Occluded` (or flip `RequireLineOfSight` to `true`) to make it fair.
