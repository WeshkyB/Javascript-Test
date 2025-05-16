
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Universelle queue_on_teleport Implementierung
local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport) or function() end

-- Universelle Dateifunktionen
local filesafe = {
    write = (syn and syn.writefile) or writefile,
    read = (syn and syn.readfile) or readfile,
    list = (syn and syn.listfiles) or listfiles,
    makefolder = (syn and syn.makefolder) or makefolder,
    isfolder = (syn and syn.isfolder) or isfolder
}

-- Server-Hopping mit Build-Saving
local function AutoBuildSaver()
    -- Konfiguration
    local MIN_BLOCKS = 50
    local SCAN_INTERVAL = 6
    local TELEPORT_DELAY = 3
    
    -- Team-Definitionen
    local Teams = {
        ["magenta"] = workspace["MagentaZone"],
        ["yellow"] = workspace["New YellerZone"],
        ["black"] = workspace["BlackZone"],
        ["white"] = workspace["WhiteZone"],
        ["green"] = workspace["CamoZone"],
        ["blue"] = workspace["Really blueZone"],
        ["red"] = workspace["Really redZone"]
    }

    -- Hilfsfunktionen
    local function GetStringAngles(cframe)
        local X, Y, Z = cframe:ToEulerAnglesXYZ()
        return string.format("%.5f,%.5f,%.5f", math.deg(X), math.deg(Y), math.deg(Z))
    end

    local function SavePlayerBuild(playerName, teamName)
        local playerFolder = workspace.Blocks:FindFirstChild(playerName)
        if not playerFolder then return false end
        
        local teamBase = Teams[teamName]
        if not teamBase then return false end

        local blocks = {}
        for _, block in ipairs(playerFolder:GetChildren()) do
            local part = block:FindFirstChild("PPart")
            if part then
                table.insert(blocks, {
                    Type = block.Name,
                    Position = part.Position,
                    Rotation = part.CFrame - part.Position,
                    Size = part.Size,
                    Color = part.Color,
                    Transparency = part.Transparency
                })
            end
        end

        if #blocks < MIN_BLOCKS then return false end

        local buildData = {
            Player = playerName,
            Team = teamName,
            Blocks = blocks,
            Timestamp = os.time(),
            Server = game.JobId
        }

        local fileName = "BuildSave_"..playerName.."_"..os.date("%Y%m%d_%H%M%S")..".json"
        local success, err = pcall(function()
            filesafe.write("BuildSaves/"..fileName, HttpService:JSONEncode(buildData))
        end)

        return success
    end

    -- Hauptfunktion
    local function ScanAndSave()
        if not filesafe.isfolder("BuildSaves") then
            filesafe.makefolder("BuildSaves")
        end

        print("Scanning server for builds...")
        local saved = 0
        
        for _, player in ipairs(Players:GetPlayers()) do
            if SavePlayerBuild(player.Name, tostring(player.Team)) then
                saved = saved + 1
                print("Saved build for:", player.Name)
            end
        end

        return saved
    end

    local function FindNewServer()
        local servers = {}
        local success, response = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
        end)

        if success then
            for _, server in ipairs(HttpService:JSONDecode(response).data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(servers, server.id)
                end
            end
        end

        return servers
    end

    -- Teleport-Sicherung
    queueteleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/WeshkyB/Javascript-Test/refs/heads/main/test.lua"))()
    ]])

    -- Hauptloop
    while true do
        local saved = ScanAndSave()
        print("Saved", saved, "builds in this server")
        
        wait(TELEPORT_DELAY)
        
        local servers = FindNewServer()
        if #servers > 0 then
            print("Teleporting to new server...")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)])
            break
        else
            print("No available servers found, retrying...")
            wait(SCAN_INTERVAL)
        end
    end
end

-- Starter
if not _G.BuildSaverRunning then
    _G.BuildSaverRunning = true
    AutoBuildSaver()
end
