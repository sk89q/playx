-- PlayX Faves
-- Copyright (c) 2009 sk89q <http://www.sk89q.com>
-- Licensed under the GNU General Public License v2
--
-- playx_faves.lua allows you to provide a "favorites" list that can be
-- accessed via chat. For example, you could do !fav brightside to play
-- a certain video.
--
-- To install, drop this file into your lua/autorun/server folder.
-- 
-- $Id$

local faves = {

-- Change this list to change the favorites
--

["brightside"] = "http://www.youtube.com/watch?v=_RM6qsq-JPY",
["failedme"] = "http://www.youtube.com/watch?v=VuK-aLSZtNo",
["theinternet"] = "http://www.youtube.com/watch?v=iDbyYGrswtg",
["verymelon"] = "http://www.youtube.com/watch?v=T5Q8Gs-w-z8",

--
-- END

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