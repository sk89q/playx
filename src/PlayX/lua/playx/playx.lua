-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- $Id$

require("datastream")
include("playxlib.lua")

local defaultJWURL = "http://playx.googlecode.com/svn/jwplayer/player.swf"
local defaultHostURL = "http://sk89q.github.com/playx/host/host.html"
CreateConVar("playx_jw_url", defaultJWURL, { FCVAR_ARCHIVE, FCVAR_GAMEDLL })
CreateConVar("playx_host_url", defaultHostURL, { FCVAR_ARCHIVE, FCVAR_GAMEDLL })
CreateConVar("playx_jw_youtube", "1", { FCVAR_ARCHIVE })
CreateConVar("playx_race_protection", "1", { FCVAR_ARCHIVE })
CreateConVar("playx_wire_input", "0", { FCVAR_ARCHIVE })
CreateConVar("playx_wire_input_delay", "2", { FCVAR_ARCHIVE })

PlayX = {}

include("playx/concmds.lua")

--- Checks whether the JW player is enabled.
-- @return Whether the JW player is enabled
function PlayX.IsUsingJW()
    local v = GetConVar("playx_jw_url"):GetString()
    return v:Trim():gmatch("^https?://.+") and true or false
end

--- Gets the URL of the JW player.
-- @return
function PlayX.GetJWURL()
    return GetConVar("playx_jw_url"):GetString():Trim()
end

--- Returns whether the JW player supports YouTube.
-- @return
function PlayX.JWPlayerSupportsYouTube()
    return GetConVar("playx_jw_youtube"):GetBool()
end

--- Gets the URL of the host file.
-- @return
function PlayX.GetHostURL()
    return GetConVar("playx_host_url"):GetString():Trim()
end

--- Returns whether a player is permitted to use the player. The
-- PlayXIsPermitted hook allows this function to be overrided.
-- @param ply Player
-- @param instance Instance to check against (may be nil)
-- @return
function PlayX.IsPermitted(ply, instance)
    local result = hook.Call("PlayXIsPermitted", GAMEMODE, ply, instance)
    
    if result ~= nil then
        return result
    else
        return ply:IsAdmin() or ply:IsSuperAdmin()
    end
end

--- Checks if a player instance exists in the game.
-- @return Whether a player exists
function PlayX.PlayerExists()
    return #ents.FindByClass("gmod_playx") > 0
end

--- Gets the player instance entity. When there are multiple instances out,
-- the behavior is undefined. A hook named PlayXSelectInstance can be
-- defined to return a specific entity. This function may return nil.
-- @param ply Player that can be passed to specify a user
-- @return Entity or nil
function PlayX.GetInstance(ply)
    -- First try the hook
    local result = hook.Call("PlayXSelectInstance", GAMEMODE, ply)
    if result then return result end
    
    local props = ents.FindByClass("gmod_playx")
    return props[1]
end

--- Gets a list of instances.
-- @return List of entities
function PlayX.GetInstances()
    return ents.FindByClass("gmod_playx")
end

--- Gets a list of instances that a player has subscribed to.
-- @return List of entities
function PlayX.GetSubscribed(ply)
    local subscribed = {}
    for _, instance in pairs(PlayX.GetInstances()) do
        if instance:IsSubscribed(ply) then
            table.insert(subscribed, instance)
        end
    end
    return subscribed
end

--- Returns true if the user should be automatically subscribed to the
-- instance. By default this returns true, but you can override the behavior
-- by defining a hook called PlayXShouldSubscribe. You can manually
-- subscribe and unsubscribe users without having this function matching.
-- This function is only called when a PlayX entity is created and when a
-- player joins but it is never called to "check" subscriptions.
-- @param ply Player
-- @param instance Entity instance to check against
function PlayX.ShouldSubscribe(ply, instance)
    local result = hook.Call("PlayXShouldSubscribe", GAMEMODE, ply, instance)
    if result ~= nil then return result end
    return true
end

--- Spawns the player at the location that a player is looking at. This
-- function will check whether there is already a player or not.
-- @param ply Player
-- @param model Model path
-- @param repeater Spawn repeater
-- @return Success, and error message
function PlayX.SpawnForPlayer(ply, model, repeater)
    if not util.IsValidModel(model) then
        return false, "The server doesn't have the selected model"
    end
    
    local cls = "gmod_playx" .. (repeater and "_repeater" or "")
    local pos, ang = hook.Call("PlayXSpawnPlayX", GAMEMODE, ply, model, repeater)
    local ent
    
    -- No hook?
    if pos == nil or pos == true then
	    if pos ~= true and not repeater and PlayX.PlayerExists() then
	        return false, "There is already a PlayX player somewhere on the map"
	    end
	    
	    local tr = ply.GetEyeTraceNoCursor and ply:GetEyeTraceNoCursor() or
	        ply:GetEyeTrace()
	        
		ent = ents.Create(cls)
	    ent:SetModel(model)
	    
		local info = PlayXScreens[model:lower()]
	    
		if not info or not info.IsProjector or 
		   not ((info.Up == 0 and info.Forward == 0) or
		        (info.Forward == 0 and info.Right == 0) or
		        (info.Right == 0 and info.Up == 0)) then
	        ent:SetAngles(Angle(0, (ply:GetPos() - tr.HitPos):Angle().y, 0))
		    ent:SetPos(tr.HitPos - ent:OBBCenter() + 
		       ((ent:OBBMaxs().z - ent:OBBMins().z) + 10) * tr.HitNormal)
	        ent:DropToFloor()
	    else
	        local ang = Angle(0, 0, 0)
	        
	        if info.Forward > 0 then
	            ang = ang + Angle(180, 0, 180)
	        elseif info.Forward < 0 then
	            ang = ang + Angle(0, 0, 0)
	        elseif info.Right > 0 then
	            ang = ang + Angle(90, 0, 90)
	        elseif info.Right < 0 then
	            ang = ang + Angle(-90, 0, 90)
	        elseif info.Up > 0 then
	            ang = ang + Angle(-90, 0, 0)
	        elseif info.Up < 0 then
	            ang = ang + Angle(90, 0, 0)
	        end
	        
	        local tryDist = math.min(ply:GetPos():Distance(tr.HitPos), 4000)
	        local data = {}
	        data.start = tr.HitPos + tr.HitNormal * (ent:OBBMaxs() - ent:OBBMins()):Length()
	        data.endpos = tr.HitPos + tr.HitNormal * tryDist
	        data.filter = player.GetAll()
	        local dist = util.TraceLine(data).Fraction * tryDist - 
	            (ent:OBBMaxs() - ent:OBBMins()):Length() / 2
	        
	        ent:SetAngles(ang + tr.HitNormal:Angle())
	        ent:SetPos(tr.HitPos - ent:OBBCenter() + dist * tr.HitNormal)
	    end
    -- Error?
    elseif pos == false then
        return false, ang
    -- Custom spawn location
    else
        ent = ents.Create("gmod_playx")
        ent:SetModel(model)
        ent:SetAngles(ang)
        ent:SetPos(pos)
    end
    
    ent:Spawn()
    ent:Activate()
    
    local phys = ent:GetPhysicsObject()
    if phys:IsValid() then
        phys:EnableMotion(false)
        phys:Sleep()
    end
    
    if ply.AddCleanup then
        ply:AddCleanup(cls, ent)
        
        undo.Create("#" .. cls)
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
        undo.Finish()
    end
    
    return true
end

--- Resolves a provider.
-- @param provider Name of provider, leave blank to auto-detect
-- @param uri URI to play
-- @param useJW True to allow the use of the JW player, false for otherwise, nil to default true
-- @return Provider name (detected) or nil
-- @return Result or error message
function PlayX.ResolveProvider(provider, uri, useJW)
    -- See if there is a hook for resolving providers
    local result = hook.Call("PlayXResolveProvider", GAMEMODE, provider, uri, useJW)
    
    if result then
        return result
    end
    
    if provider ~= "" then -- Provider detected
        if not list.Get("PlayXProviders")[provider] then
            return nil, "Unknown provider specified"
        end
        
        local newURI = list.Get("PlayXProviders")[provider].Detect(uri)
        result = list.Get("PlayXProviders")[provider].GetPlayer(newURI and newURI or uri, useJW)
        
        if not result then
            return nil, "The provider did not recognize the media URI"
        end
    else -- Time to detect the provider
        for id, p in pairs(list.Get("PlayXProviders")) do
            local newURI = p.Detect(uri)
            
            if newURI then
                provider = id
                result = p.GetPlayer(newURI, useJW)
                break
            end
        end
        
        if not result then
            return nil, "No provider was auto-detected"
        end
    end
    
    return provider, result
end

--- Gets a provider by name.
-- @param id ID of provider
-- @return Provider function or nil
function PlayX.GetProvider(id)
    return list.Get("PlayXProviders")[id]
end

--- Send the PlayXEnd umsg to clients. You should not have much of a
-- a reason to call this method.
function PlayX.SendError(ply, err)
    umsg.Start("PlayXError", ply)
	umsg.String(err)
    umsg.End()
end

--- Attempt to detect the PlayX version and put it in PlayX.Version.
function PlayX.DetectVersion()
    local version = ""
    local folderName = string.match(debug.getinfo(1, "S").short_src, "addons[/\\]([^/\\]+)")
    if not file.Exists("../addons/" .. folderName .. "/info.txt") then folderName = "PlayX" end
    -- Get version
    if file.Exists("../addons/" .. folderName .. "/info.txt") then
        local contents = file.Read("../addons/" .. folderName .. "/info.txt")
        version = string.match(contents, "\"version\"[ \t]*\"([^\"]+)\"")
        if version == nil then
            version = ""
        end
    end
    PlayX.Version = version
end

--- Load the providers.
function PlayX.LoadProviders()
    local p = file.FindInLua("playx/providers/*.lua")
    for _, file in pairs(p) do
        local status, err = pcall(function() include("playx/providers/" .. file) end)
        if not status then
            ErrorNoHalt("Failed to load provider(s) in " .. file .. ": " .. err)
        end
    end
end

--- Used to replicate a cvar using a custom method (that doesn't cause
-- overflow issues).
function PlayX.ReplicateVar(cvar, old, new, ply)
    new = new or GetConVar(cvar):GetString()
    SendUserMessage("PlayXReplicate", ply, cvar, new)
end

-- Must replicate vars and auto-subscribe
hook.Add("PlayerInitialSpawn", "PlayXPlayerInitialSpawn", function(ply)
    PlayX.ReplicateVar("playx_jw_url", nil, nil, ply)
    PlayX.ReplicateVar("playx_host_url", nil, nil, ply)
    
    -- Send providers list.
    datastream.StreamToClients(ply, "PlayXProvidersList", {
        List = list.Get("PlayXProvidersList"),
    })
    
    -- Tell the user the playing media in three seconds
    timer.Simple(3, function()
        if not ValidEntity(ply) then return end
        
        ply.PlayXReady = true
        
        for _, instance in pairs(PlayX.GetInstances()) do
            if PlayX.ShouldSubscribe(ply, instance) then
                instance:Subscribe(ply)
            end
        end
    end)
end)

-- Must remove subscriptions on disconnect.
hook.Add("PlayerDisconnected", "PlayXPlayerDisconnected", function(ply)
    for _, instance in pairs(PlayX.GetSubscribed(ply)) do
        instance:Unsubscribe(instance)
    end
end)

cvars.AddChangeCallback("playx_jw_url", PlayX.ReplicateVar)
cvars.AddChangeCallback("playx_host_url", PlayX.ReplicateVar)

PlayX.DetectVersion()
PlayX.LoadProviders()