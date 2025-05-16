local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local PlaceID = game.PlaceId
local Player = Players.LocalPlayer
local HopInterval = 6 -- Sekunden zwischen Hops
local MinPlayers = 15 -- Mindestspieleranzahl

-- Manuelle Serverliste als Fallback
local BackupServers = {
    "b00bd089-0968-4430-92a8-eb7dfd9f562a",
    "fa5772df-9ea7-4f00-b999-f85121b1bb41",
    "8442b5dc-6bb1-497b-8cc9-0f31b79bfa40"
}

local function GetServerList()
    local success, result = pcall(function()
        local response = game:HttpGet(
            "https://games.roblox.com/v1/games/"..PlaceID.."/servers/Public?sortOrder=Asc&limit=100",
            true
        )
        return HttpService:JSONDecode(response)
    end)
    
    return success and result.data or nil
end

local function FilterServers(servers)
    local valid = {}
    local current = game.JobId
    
    for _, server in ipairs(servers) do
        if server.id ~= current and (server.playing or 0) >= MinPlayers then
            table.insert(valid, server)
        end
    end
    
    table.sort(valid, function(a,b) return a.playing < b.playing end)
    return valid
end

local function HopToServer()
    -- Versuche API-Server zuerst
    local servers = GetServerList()
    if servers then
        local filtered = FilterServers(servers)
        if #filtered > 0 then
            local target = filtered[math.random(1, math.min(5, #filtered))].id
            print("🌐 Server-Hop zu:", target)
            TeleportService:TeleportToPlaceInstance(PlaceID, target)
            return
        end
    end
    
    -- Fallback auf manuelle Liste
    if #BackupServers > 0 then
        local target = BackupServers[math.random(1, #BackupServers)]
        if target ~= game.JobId then
            print("🔄 Fallback-Hop zu bekanntem Server:", target)
            TeleportService:TeleportToPlaceInstance(PlaceID, target)
            return
        end
    end
    
    warn("⚠️ Keine Server verfügbar. Warte "..HopInterval.." Sekunden...")
end

-- Haupt-Loop mit automatischer Re-Injection
local function AutoHop()
    while true do
        HopToServer()
        local start = tick()
        
        -- Warte bis zum nächsten Hop
        repeat task.wait() until tick() - start >= HopInterval
    end
end

-- Nach Teleport neu starten
local function OnTeleport(teleportState)
    if teleportState == Enum.TeleportState.Started then
        queue_on_teleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/WeshkyB/Javascript-Test/refs/heads/main/test.lua"))()
        ]])
    end
end

Player.OnTeleport:Connect(OnTeleport)

-- Skript starten
if not game:IsLoaded() then game.Loaded:Wait() end
AutoHop()
