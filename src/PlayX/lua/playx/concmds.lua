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

--- Send the PlayXSpawnDialog umsg to a client, telling the client to
-- open the spawn dialog.
-- @param ply Player to send to
-- @param forRepeater True if this is for the repeater
function PlayX.SendSpawnDialog(ply, forRepeater)
    if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    else
        umsg.Start("PlayXSpawnDialog", ply)
        umsg.Bool(forRepeater)
        umsg.End()
    end
end

--- Send the PlayXUpdateInfo umsg to a user.
function PlayX.SendUpdateInfo(ply, ver)
    umsg.Start("PlayXUpdateInfo", ply)
    umsg.String(ver)
    umsg.End()
end

--- Called for concmd playx_open.
local function ConCmdOpen(ply, cmd, args)
    if not ply or not ply:IsValid() then return end
    
    local instance, err = PlayX.GetInstance(ply)
    
    -- Is there a PlayX entity out?
    if not instance then
        PlayX.SendError(ply, err or "There is no player spawned! Go to the spawn menu > Entities")
    -- Is the user permitted to use the player?
    elseif not PlayX.IsPermitted(ply, instance) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    -- Invalid arguments?
    elseif not args[1] then
        ply:PrintMessage(HUD_PRINTCONSOLE, "playx_open requires a URI")
    elseif instance:RaceProtectionTriggered() then
        PlayX.SendError(ply, "Someone started something too recently")
    else
        local uri = args[1]:Trim()
        local provider = playxlib.CastToString(args[2], ""):Trim()
        local start = playxlib.ParseTimeString(args[3])
        local forceLowFramerate = playxlib.CastToBool(args[4], false)
        local useJW = playxlib.CastToBool(args[5], true)
        
        if start == nil then
            PlayX.SendError(ply, "The time format you entered for \"Start At\" isn't understood")
        elseif start < 0 then
            PlayX.SendError(ply, "A non-negative start time is required")
        else
            local result, err = 
                instance:OpenMedia(provider, uri, start, forceLowFramerate, useJW)
            
            if not result then
                PlayX.SendError(ply, err)
            else
                hook.Call("PlayXConCmdOpened", GAMEMODE, instance, ply)
            end
        end
    end
end

--- Called for concmd playx_close.
function ConCmdClose(ply, cmd, args)
    local instance, err = PlayX.GetInstance(ply)
    
	if not ply or not ply:IsValid() then
        return
    elseif not instance then
        PlayX.SendError(ply, err or "There is no player spawned!")
    elseif not PlayX.IsPermitted(ply, instance) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    else
        instance:CloseMedia()
        hook.Call("PlayXConCmdClosed", GAMEMODE, instance, ply)
    end
end

--- Called for concmd playx_spawn.
function ConCmdSpawn(ply, cmd, args)
    if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    else
        if not args[1] or args[1]:Trim() == "" then
            PlayX.SendError(ply, "No model specified")
        else
            local model = args[1]:Trim()
            local result, err = PlayX.SpawnForPlayer(ply, model, cmd == "playx_spawn_repeater")
        
            if not result then
                PlayX.SendError(ply, err)
            end
        end
    end
end

--- Called for concmd playx_update_info.
function ConCmdUpdateInfo(ply, cmd, args)
    if not ply or not ply:IsValid() then
        return
    else	    
	    PlayX.SendUpdateInfo(ply, PlayX.Version)
    end
end
 
concommand.Add("playx_open", ConCmdOpen)
concommand.Add("playx_close", ConCmdClose)
concommand.Add("playx_spawn", ConCmdSpawn)
concommand.Add("playx_spawn_repeater", ConCmdSpawn)
concommand.Add("playx_update_info", ConCmdUpdateInfo)