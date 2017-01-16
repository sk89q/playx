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

local TwitchTV = {}

function TwitchTV.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^http[s]?://twitch.tv/([a-zA-Z0-9]+)",
		"^http[s]?://www.twitch.tv/([a-zA-Z0-9]+)",	
		"^twitch.tv/([a-zA-Z0-9]+)$"
    })

    if m then
        return m[1]
    end
end

function TwitchTV.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

function TwitchTV.GetPlayer(uri, useJW)
    if uri then
        return {
            ["Handler"] = "TwitchTV-New",            
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
			["MetadataFunc"] = function(callback, failCallback)
				TwitchTV.QueryMetadata(uri, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["Channel"] = uri
            }
    }
    end
end

list.Set("PlayXProviders", "twitch.tv", TwitchTV)
list.Set("PlayXProvidersList", "twitch.tv", {"twitch.tv"})
