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
    local m = PlayX.FindMatch(uri:gsub("%?.*$", ""), {
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
        local vars = {
            ["channel"] = uri,
            ["layout"] = "playerEmbedDefault",
            ["backgroundColor"] = "0x000000",
            ["backgroundAlpha"] = "1",
            ["backgroundGradientStrength"] = "0",
            ["chromeColor"] = "0x000000",
            ["headerBarGlossEnabled"] = "false",
            ["controlBarGlossEnabled"] = "false",
            ["chatInputGlossEnabled"] = "false",
            ["uiWhite"] = "true",
            ["uiAlpha"] = "0.5",
            ["uiSelectedAlpha"] = "1",
            ["dropShadowEnabled"] = "false",
            ["dropShadowHorizontalDistance"] = "10",
            ["dropShadowVerticalDistance"] = "10",
            ["paddingLeft"] = "0",
            ["paddingRight"] = "0",
            ["paddingTop"] = "0",
            ["paddingBottom"] = "0",
            ["cornerRadius"] = "0",
            ["backToDirectoryURL"] = "null",
            ["bannerURL"] = "null",
            ["bannerText"] = "null",
            ["bannerWidth"] = "320",
            ["bannerHeight"] = "50",
            ["showViewers"] = "true",
            ["embedEnabled"] = "false",
            ["chatEnabled"] = "false",
            ["onDemandEnabled"] = "true",
            ["programGuideEnabled"] = "false",
            ["fullScreenEnabled"] = "false",
            ["reportAbuseEnabled"] = "false",
            ["gridEnabled"] = "false",
            ["initialIsOn"] = "true",
            ["initialIsMute"] = "false",
            ["initialVolume"] = "__volume__",
            ["contentId"] = "null",
            ["initThumbUrl"] = "null",
            ["playeraspectwidth"] = "4",
            ["playeraspectheight"] = "3",
            ["mogulusLogoEnabled"] = "true",
            ["width"] = "__width__",
            ["height"] = "__height__",
            ["wmode"] = "window",
        }
        
        local url = "http://cdn.livestream.com/grid/PlayerV2.swf?" .. PlayX.URLEncodeTable(vars)
        
        return {
            ["Handler"] = "FlashAPI",
            ["Arguments"] = {
                URL = url,
                VolumeMul = 0.1,
            },
            ["Resumable"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Livestream.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function Livestream.QueryMetadata(uri, callback, failCallback)
    local url = Format("http://x%sx.channel-api.livestream-api.com/2.0/info", uri:gsub("_", "-"))

    http.Get(url, "", function(result, size)
        if size == 0 then
            failCallback("HTTP request failed (size = 0)")
            return
        end
        
        local title = PlayX.HTMLUnescape(string.match(result, "<title>([^<]+)</title>"))
        local desc = PlayX.HTMLUnescape(string.match(result, "<description>([^<]+)</description>"))
        local isLive = string.match(result, "<ls:isLive>([^<]+)</ls:isLive>") == "true"
        local viewerCount = tonumber(string.match(result, "<ls:currentViewerCount>([^<]+)</ls:currentViewerCount>"))
        local tags = PlayX.ParseTags(PlayX.HTMLUnescape(string.match(result, "<ls:tags>([^<]+)</ls:tags>")), ",")
        
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