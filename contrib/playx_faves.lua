-- PlayX Faves
-- Copyright (c) 2009 sk89q <http://www.sk89q.com>
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

local faves = {
    ["brightside"] = "http://www.youtube.com/watch?v=_RM6qsq-JPY",
    ["failedme"] = "http://www.youtube.com/watch?v=VuK-aLSZtNo",
    ["theinternet"] = "http://www.youtube.com/watch?v=iDbyYGrswtg",
    ["verymelon"] = "http://www.youtube.com/watch?v=T5Q8Gs-w-z8",
}

hook.Add("PlayerSay", "PlayXFavesPlayerSay", function(ply, text, all, death)
    if not PlayX then return end
    if not all then return end
    
    local q = text:lower():match("^!fav (.+)$")
    
    if q and faves[q] then
        if not PlayX.IsPermitted(ply) then
            ply:ChatPrint("You don't have permission to start videos")
        elseif not PlayX.PlayerExists() then
            ply:ChatPrint("No PlayX player is spawned")
        else
            PlayX.OpenMedia("YouTube", faves[q])
        end
    elseif q then
        ply:ChatPrint("Unrecognized video name!")
    end
    
    return nil
end)