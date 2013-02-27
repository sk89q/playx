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

local Livestream = {}

function Livestream.Detect(uri, useJW)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^http://www%.livestream%.com/([a-zA-Z0-9_]+)$",
        "^http://livestream%.com/([a-zA-Z0-9_]+)$",
        "^http://www%.mogulus%.com/([a-zA-Z0-9_]+)$",
        "^http://mogulus%.com/([a-zA-Z0-9_]+)$",
    })
    
    if m then
        return m[1]
    end
end

function Livestream.GetPlayer(uri, useJW)
    if uri:lower():find("^[a-zA-Z0-9_]+$") then        
        return {
            ["Handler"] = "IFrame",
            ["URI"] = "http://cdn.livestream.com/embed/"..uri.."?layout=4&color=0x000000&autoPlay=true&mute=false&iconColorOver=0xe7e7e7&iconColor=0xcccccc&allowchat=true&height=385&width=640",
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Livestream.QueryMetadata(uri, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["VolumeMul"] = 0.1,
            },
        }
    end
end

function Livestream.QueryMetadata(uri, callback, failCallback)
    local url = Format("http://x%sx.channel-api.livestream-api.com/2.0/info", uri:gsub("_", "-"))

    http.Fetch(url, function(result, size)
        if size == 0 then
            failCallback("HTTP request failed (size = 0)")
            return
        end
        
        local title = playxlib.HTMLUnescape(string.match(result, "<title>([^<]+)</title>"))
        local desc = playxlib.HTMLUnescape(string.match(result, "<description>([^<]+)</description>"))
        local isLive = string.match(result, "<ls:isLive>([^<]+)</ls:isLive>") == "true"
        local viewerCount = tonumber(string.match(result, "<ls:currentViewerCount>([^<]+)</ls:currentViewerCount>"))
        local tags = playxlib.ParseTags(playxlib.HTMLUnescape(string.match(result, "<ls:tags>([^<]+)</ls:tags>")), ",")
        
        if title then
            callback({
                ["URL"] = "http://livestream.com/" .. uri,
                ["Title"] = title,
                ["Description"] = desc,
                ["Tags"] = tags,
                ["IsLive"] = isLive,
                ["ViewerCount"] = viewerCount,
            })
        else
            callback({
                ["URL"] = "http://livestream.com/" .. uri,
            })
        end
    end)
end

list.Set("PlayXProviders", "Livestream", Livestream)
list.Set("PlayXProvidersList", "Livestream", {"Livestream"})