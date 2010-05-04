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

--- Called for concmd playx_open.
local function ConCmdOpen(ply, cmd, args)
	if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    elseif not PlayX.PlayerExists() then
        PlayX.SendError(ply, "There is no player spawned! Go to the spawn menu > Entities")
    elseif not args[1] then
        ply:PrintMessage(HUD_PRINTCONSOLE, "playx_open requires a URI")
    else
        local uri = args[1]:Trim()
        local provider = PlayX.ConCmdToString(args[2], ""):Trim()
        local start = PlayX.ParseTimeString(args[3])
        local forceLowFramerate = PlayX.ConCmdToBool(args[4], false)
        local useJW = PlayX.ConCmdToBool(args[5], true)
        local ignoreLength = PlayX.ConCmdToBool(args[6], false)
        
        if start == nil then
            PlayX.SendError(ply, "The time format you entered for \"Start At\" isn't understood")
        elseif start < 0 then
            PlayX.SendError(ply, "A non-negative start time is required")
        else
            local result, err = PlayX:GetInstance(ply)
                :OpenMedia(provider, uri, start, forceLowFramerate,
                           useJW, ignoreLength)
            
            if not result then
                PlayX.SendError(ply, err)
            end
        end
    end
end

--- Called for concmd playx_close.
function ConCmdClose(ply, cmd, args)
	if not ply or not ply:IsValid() then
        return
    elseif not PlayX.IsPermitted(ply) then
        PlayX.SendError(ply, "You do not have permission to use the player")
    else
        PlayX.EndMedia()
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
            local result, err = PlayX.SpawnForPlayer(ply, model)
        
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
        Msg(Format("PlayX: %s asked for update info; ver=%s\n", ply:GetName(), _version))
	    
	    PlayX.SendUpdateInfoUMsg(ply, _version)
    end
end
 
concommand.Add("playx_open", ConCmdOpen)
concommand.Add("playx_close", ConCmdClose)
concommand.Add("playx_spawn", ConCmdSpawn)
concommand.Add("playx_update_info", ConCmdUpdateInfo)