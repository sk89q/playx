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

local defHostURL = "http://sk89q.github.com/playx/host/host.html"
local defJWURL = "http://playx.googlecode.com/svn/jwplayer/player.swf"

-- FCVAR_GAMEDLL makes cvar change detection work
CreateConVar("playx_jw_url", defJWURL, {FCVAR_ARCHIVE, FCVAR_GAMEDLL})
CreateConVar("playx_host_url", defHostURL, {FCVAR_ARCHIVE, FCVAR_GAMEDLL})
CreateConVar("playx_jw_youtube", "1", {FCVAR_ARCHIVE})
CreateConVar("playx_admin_timeout", "120", {FCVAR_ARCHIVE})
CreateConVar("playx_expire", "-1", {FCVAR_ARCHIVE})
CreateConVar("playx_race_protection", "1", {FCVAR_ARCHIVE})

PlayX = {}

include("playx/functions.lua")
include("playx/providers.lua")
include("playx/concmds.lua")

--- Checks if a player instance exists in the game.
-- @return Whether a player exists
function PlayX.PlayerExists()
    return table.Count(ents.FindByClass("gmod_playx")) > 0
end

--- Gets the player instance entity.
-- Note that, as of v3.x, there can be multiple PlayX instances, reducing the
-- effectiveness of this function. However, a Player can be passed to help
-- choose the best instance, and that is what some of the PlayX functions
-- that use this function do. A hook named "PlayXGetInstance" taking one
-- argument, the Player, can return a specific PlayX instance. That hook can
-- be useful if you are using multiple PlayX players but you wish to retain the
-- console commands, and want the console commands to affect the 'right' player.
-- @param ply Optional player argument
-- @return Entity or nil
function PlayX.GetInstance(ply)
    local instance = hook.Call("PlayXGetInstance", false, ply)
    
    if ValidEntity(instance) then
        return instance
    end
    
    local props = ents.FindByClass("gmod_playx")
    return props[1]
end

--- Get all the PlayX entities.
-- @return
function PlayX.GetInstances()
    return ents.FindByClass("gmod_playx")
end

--- Checks whether the JW player is enabled.
-- @return Whether the JW player is enabled
function PlayX.IsUsingJW()
    return GetConVar("playx_jw_url"):GetString():Trim():gmatch("^https?://.+") and true or false
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

--- Checks whether the host URL is valid.
-- @return Whether the host URL is valid
function PlayX.HasValidHost()
    return PlayX.GetHostURL():Trim():gmatch("^https?://.+") and true or false
end

--- Returns whether a user is permitted to use the player.
-- You can override this by creating a hook named PlayXPermitPlayer, taking in
-- two argments, a Player and the PlayX entity, and returning true or false.
-- Not that the entity argument may be optional.
-- @param ply Player
-- @param ent Ent
-- @return
function PlayX.IsPermitted(ply, ent)
    local r = hook.Call("PlayXPermitPlayer", ply)
    
    if r ~= nil then
        return r
    else
        return ply:IsAdmin() or ply:IsSuperAdmin()
    end
end

--- Spawns the player at the location that a player is looking at. This
-- function will check whether there is already a player or not. If you are
-- using this, you can override its behavior with a hook named PlayXSpawnPlayX.
-- @param ply Player
-- @param model Model path
-- @return Success, and error message
function PlayX.SpawnForPlayer(ply, model)
    if not util.IsValidModel(model) then
        return false, "The server doesn't have the selected model"
    end
    
    local pos, ang = hook.Call("PlayXSpawnPlayX", ply, model)
    local ent
    
    -- No hook?
    if pos == nil or pos == true then
        if PlayX.PlayerExists() then
            return false, "There is already a PlayX player somewhere on the map"
        end
        
        local tr = ply.GetEyeTraceNoCursor and ply:GetEyeTraceNoCursor() or
            ply:GetEyeTrace()

        ent = ents.Create("gmod_playx")
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
    
    ply:AddCleanup("gmod_playx", ent)
    
    undo.Create("gmod_playx")
    undo.AddEntity(ent)
    undo.SetPlayer(ply)
    undo.Finish()
    
    return true
end

--- Attempts to resolve a provider and URI into an handler arguments.
-- @param provider
-- @param uri
-- @param useJW
-- @return Result
function PlayX.ResolveProvider(provider, uri, useJW)
    -- See if there is a hook for resolving providers
    local result = hook.Call("PlayXResolveProvider", false, provider, uri, useJW)
    
    if result then
        return result
    end
    
     -- Provider specified
    if provider ~= "" then
        local p = PlayX.GetProvider(provider)
        if not p then
            return false, "No provider by name of '" .. provider .. "'"
        end
        
        local resolvedURI = p.Detect(uri)
        result = p.GetPlayer(resolvedURI and resolvedURI or uri, useJW)
        
        if not result then
            return false, "Provider '" .. provider .. "' did not recognize the media URI"
        end
    -- Auto-detect provider
    else
        for id, p in pairs(list.Get("PlayXProviders")) do
            local resolvedURI = p.Detect(uri)
            
            if resolvedURI then
                provider = id
                result = p.GetPlayer(resolvedURI, useJW)
                break
            end
        end
        
        if not result then
            return false, "No provider was auto-detected"
        end
    end
    
    return result
end

function PlayX.GetAutoSubscribers()
    return player.GetAll()
    -- @TODO: Change
end

--- Sends an error to the client.
-- @param ply
-- @param err Error message
function PlayX.SendError(ply, err)
    umsg.Start("PlayXError", ply)
	umsg.String(err)
    umsg.End()
end

--- Send the PlayXSpawnDialog umsg to a client, telling the client to
-- open the spawn dialog. This checks to see whether the user is able
-- to spawn the PlayX entity before sending the dialog.
-- @param ply Player to send to
function PlayX.SendSpawnDialog(ply)
	if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player.")
    else
        umsg.Start("PlayXSpawnDialog", ply)
        umsg.End()
    end
end

--- Used to replicate a cvar using a custom method (that doesn't cause
-- overflow issues).
local function ReplicateVar(cvar, old, new, ply)
    new = new or GetConVar(cvar):GetString()
    SendUserMessage("PlayXReplicate", ply, cvar, new)
end

--- Called on game mode hook PlayerInitialSpawn.
function PlayerInitialSpawn(ply)
    ReplicateVar("playx_jw_url", nil, nil, ply)
    ReplicateVar("playx_host_url", nil, nil, ply)
    
    datastream.StreamToClients(ply, "PlayXProvidersList", {
        List = list.Get("PlayXProvidersList"),
    })
    
    local instances = PlayX.GetInstances()
    
    for _, instance in pairs(instances) do
        if hook.Call("PlayXShouldSubscribe", false, ply, instance) then
            instance:Subscribe(ply)
        end
    end
end

hook.Add("PlayerInitialSpawn", "PlayXPlayerInitialSpawn", PlayerInitialSpawn)

cvars.AddChangeCallback("playx_jw_url", ReplicateVar)
cvars.AddChangeCallback("playx_host_url", ReplicateVar)