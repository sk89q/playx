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
            ["URI"] = url,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["HandlerArgs"] = {
                ["VolumeMul"] = 0.1,
            },
        }
    end
end

list.Set("PlayXProviders", "Livestream", Livestream)