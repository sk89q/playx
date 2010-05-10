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

local timers = {}

local function AdminTimeoutTimer(instances, uniqueId)
    timers[uniqueId] = nil
    
    local valid = {}
    
    for _, instance in pairs(instances) do
        if ValidEntity(instance) and
            not PlayX.IgnoresAdminTimeout(instance) and
            instance:HasMedia() then
                  
            local hasOthers = false
            
            for _, v in pairs(player.GetAll()) do
                if v ~= ply and PlayX.IsPermitted(v, ent) then
                    hasOthers = true
                    break
                end
            end
            
            if not hasOthers then
                table.insert(valid, instance)
                instance:CloseMedia()
            end
       end
    end
    
    if #valid > 0 then
        MsgN(string.format("PlayX: No administrators of %d instance(s); timing out media",
                           #valid))
        
        hook.Call("PlayXAdminTimeout", GAMEMODE, instances)
    end
end

--- Called on game mode hook PlayerAuthed.
local function PlayerAuthed(ply, steamID, uniqueID)
    timer.Remove("PlayXAdminTimeout" .. ply:UniqueID())
    timers[ply:UniqueID()] = nil
    
    -- Timers may not run when there are no players connected, so let's
    -- go through the list of timers and see if any are supposed to be expired
    for u, t in pairs(timers) do
        if t[1] < os.time() then
	        AdminTimeoutTimer(t[2], u)
        end
    end
end

--- Called on game mode hook PlayerDisconnected.
local function PlayerDisconnected(ply)
    if not PlayX.HasMedia() then return end
    
    local timeout = hook.Call("PlayXGetAdminTimeout", GAMEMODE) or
        GetConVar("playx_admin_timeout"):GetFloat()
    
    -- No timer, no admin, no soup for you
    if timeout < 0 then
        return
    end
    
    local hasAccess = {}
    
    for _, instance in pairs(PlayX.GetInstances()) do
        if PlayX:IsPermitted(ply, instance) then
            table.insert(hasAccess, instance)
        end
    end
    
    if #hasAccess == 0 then
        return
    end
    
    for _, instance in pairs(hasAccess) do
        if hook.Call("PlayXShouldAdminTimeout", GAMEMODE, instance) ~= false
        for _, v in pairs(player.GetAll()) do
            -- Does someone else have permission to use this player? If so,
            -- then it doesn't matter if this user has left
            if v ~= ply and PlayX.IsPermitted(v, ent) then
                table.remove(hasAccess, instance)
            end
        end
    end
    
    if #hasAccess == 0 then
        return
    end
    
    print(string.format("PlayX: No admin for %d instances(s) on server; setting timeout for %fs",
                        #hasAccess, timeout))
    
    local timerId = "PlayXAdminTimeout" .. ply:UniqueID()
    
    timer.Create(timerId, timeout, 1, AdminTimeoutTimer, hasAccess, ply:UniqueID())
    timers[ply:UniqueID()] = {os.time() + timeout, hasAccess}
end

hook.Add("PlayerAuthed", "PlayXPlayerPlayerAuthed", PlayerAuthed)
hook.Add("PlayerDisconnected", "PlayXPlayerDisconnected", PlayerDisconnected)