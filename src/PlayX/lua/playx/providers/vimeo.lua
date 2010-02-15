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

local Vimeo = {}

function Vimeo.Detect(uri, useJW)
    local m = PlayX.FindMatch(uri:gsub("%?.*$", ""), {
        "^http://[A-Za-z0-9%.%-]*%.vimeo%.com/([0-9]+)",
        "^http://vimeo%.com/([0-9]+)",
    })
    
    if m then
        return m[1]
    end
end

function Vimeo.GetPlayer(uri, useJW)
    if uri:lower():find("^[0-9]+$") then
        return {
            ["Handler"] = "FlashAPI",
            ["URI"] = "http://vimeo.com/moogaloop.swf?clip_id=" .. uri .. "&autoplay=1&js_api=1",
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["HandlerArgs"] = {
                ["JSInitFunc"] = "vimeo_player_loaded",
                ["JSVolumeFunc"] = "api_setVolume",
                ["JSStartFunc"] = "api_seekTo",
            },
        }
    end
end

list.Set("PlayXProviders", "Vimeo", Vimeo)