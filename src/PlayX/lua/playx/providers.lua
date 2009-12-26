-- PlayX
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

--- Percent encodes a value.
-- @param s String
-- @return Encoded
local function URLEncode(s)
    s = tostring(s)
    local new = ""
    
    for i = 1, #s do
        local c = s:sub(i, i)
        local b = c:byte()
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
            (b >= 48 and b <= 57) or
            c == "_" or c == "." or c == "~" then
            new = new .. c
        else
            new = new .. string.format("%%%X", b)
        end
    end
    
    return new
end

--- Percent encodes a table for the query part of a URL.
-- @param vars Table of keys and values
-- @return Encoded string
local function URLEncodeTable(vars)
    local str = ""
    
    for k, v in pairs(vars) do
        str = str .. URLEncode(k) .. "=" .. URLEncode(v) .. "&"
    end
    
    return str:sub(1, -2)
end

--- Attempts to match a list of patterns against a string, and returns
-- the matches, or nil if there were no matches.
-- @param str The string
-- @param patterns Table of patterns
-- @return Table of results, or bil
local function FindMatch(str, patterns)
    for _, pattern in pairs(patterns) do
        local m = {str:match(pattern)}
        if m[1] then return m end
    end
    
    return nil
end

--- Gets the length of a YouTube video, for the YouTube provider.
-- @param id Video ID
-- @param callback Callback to call with length
local function GetYouTubeLength(id, callback)
    local vars = URLEncodeTable({
        ["alt"] = "atom",
    })
    local url = "http://gdata.youtube.com/feeds/api/videos/" .. id .."?" .. vars

    http.Get(url, "", function(result, size)
        if size > 0 then
            local length = string.match(result, "<yt:duration seconds='([0-9]+)'")
            
            if length then
                callback(tonumber(length))
            else
                print("PlayX YouTube provider: Failed to detect length from API result")
            end
        else
            print("PlayX YouTube provider: Failed to fetch API for video length")
        end
    end)
end

PlayX.Providers = {
    ["YouTube"] = {
        ["Detect"] = function(uri)
            -- Easter egg / test media
            if uri == "ttgl" then
                uri = "http://www.youtube.com/watch?v=RN63L89nJeA"
            elseif uri == "pmk" then
                uri = "http://www.youtube.com/watch?v=Z6B10uzcjPQ"
            elseif uri == "stramic" then
                uri = "http://www.youtube.com/watch?v=zSSqCLHc9ek"
            elseif uri == "thekillers" then
                uri = "http://www.youtube.com/watch?v=whsGHeB_LwI"
            elseif uri == "dnangel" then
                uri = "http://www.youtube.com/watch?v=KZhUaiT1II8"
            elseif uri == "failedme" then
                uri = "http://www.youtube.com/watch?v=VuK-aLSZtNo"
            end
            
            local m = FindMatch(uri, {
                "^http://youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
                "^http://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
                "^http://[A-Za-z0-9%.%-]*%.youtube%.com/v/([A-Za-z0-9_%-]+)",
                "^http://youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
                "^http://[A-Za-z0-9%.%-]*%.youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
            })
            
            if m then
                return m[1]
            end
        end,
        ["GetPlayer"] = function(uri, useJW)
            if uri:find("^[A-Za-z0-9_%-]+$") then
                if useJW and PlayX.JWPlayerSupportsYouTube() then
                    return {
                        ["Handler"] = "JW",
                        ["URI"] = "http://www.youtube.com/watch?v=" .. uri,
                        ["ResumeSupported"] = true,
                        ["LowFramerate"] = false,
                        ["LengthFunc"] = function(callback)
                            GetYouTubeLength(uri, callback)
                        end,
                    }
                else
                    local vars = {
                        ["autoplay"] = "1",
                        ["start"] = "__start__",
                        ["rel"] = "0",
                        ["hd"] = "0",
                        ["showsearch"] = "0",
                        ["showinfo"] = "0",
                        ["enablejsapi"] = "1",
                    }
                    local url = "http://www.youtube.com/v/" .. uri .. "&" .. URLEncodeTable(vars)
                    
                    return {
                        ["Handler"] = "FlashAPI",
                        ["URI"] = url,
                        ["ResumeSupported"] = true,
                        ["LowFramerate"] = false,
                        ["LengthFunc"] = function(callback)
                            GetYouTubeLength(uri, callback)
                        end,
                        ["HandlerArgs"] = {
                            ["JSInitFunc"] = "onYouTubePlayerReady",
                            ["JSVolumeFunc"] = "setVolume",
                            ["StartMul"] = 1,
                        },
                    }
                end
            end
        end
    },
    ["Flash"] = {
        ["Detect"] = function(uri)
            return nil
        end,
        ["GetPlayer"] = function(uri, useJW)
            if uri:lower():find("^http://") then
                return {
                    ["Handler"] = "Flash",
                    ["URI"] = uri,
                    ["ResumeSupported"] = false,
                    ["LowFramerate"] = false,
                }
            end
        end
    },
    ["FlashMovie"] = {
        ["Detect"] = function(uri)
            local m = FindMatch(uri:gsub("%?.*$", ""), {
                "^http://.+%.swf$",
                "^http://.+%.SWF$",
            })
            
            if m then
                return m[1]
            end
        end,
        ["GetPlayer"] = function(uri, useJW)
            if uri:lower():find("^http://") then
                return {
                    ["Handler"] = "Flash",
                    ["URI"] = uri,
                    ["ResumeSupported"] = false,
                    ["LowFramerate"] = false,
                    ["HandlerArgs"] = {
                        ["ForcePlay"] = true,
                    },
                }
            end
        end
    },
    ["MP3"] = {
        ["Detect"] = function(uri)
            local m = FindMatch(uri:gsub("%?.*$", ""), {
                "^http://.+%.mp3$",
                "^http://.+%.MP3$",
            })
            
            if m then
                return m[1]
            end
        end,
        ["GetPlayer"] = function(uri, useJW)
            if uri:lower():find("^http://") then
                return {
                    ["Handler"] = "JWAudio",
                    ["URI"] = uri,
                    ["ResumeSupported"] = true,
                    ["LowFramerate"] = true,
                }
            end
        end
    },
    ["FlashVideo"] = {
        ["Detect"] = function(uri)
            local m = FindMatch(uri:gsub("%?.*$", ""), {
                "^http://.+%.flv$",
                "^http://.+%.FLV$",
                "^http://.+%.mp4$",
                "^http://.+%.MP4$",
                "^http://.+%.aac$",
                "^http://.+%.AAC$",
            })
            
            if m then
                return m[1]
            end
        end,
        ["GetPlayer"] = function(uri, useJW)
            if uri:lower():find("^http://") then
                return {
                    ["Handler"] = "JWVideo",
                    ["URI"] = uri,
                    ["ResumeSupported"] = false,
                    ["LowFramerate"] = false,
                }
            end
        end
    },
    ["AnimatedImage"] = {
        ["Detect"] = function(uri)
            return nil
        end,
        ["GetPlayer"] = function(uri, useJW)
            if uri:lower():find("^http://") then
                return {
                    ["Handler"] = "Image",
                    ["URI"] = uri,
                    ["ResumeSupported"] = true,
                    ["LowFramerate"] = false,
                }
            end
        end
    },
    ["Image"] = {
        ["Detect"] = function(uri)
            local m = FindMatch(uri:gsub("%?.*$", ""), {
                "^http://.+%.jpe?g$",
                "^http://.+%.JPE?G$",
                "^http://.+%.png$",
                "^http://.+%.PNG$",
                "^http://.+%.gif$",
                "^http://.+%.GIF$",
            })
            
            if m then
                return m[1]
            end
        end,
        ["GetPlayer"] = function(uri, useJW)
            if uri:lower():find("^http://") then
                return {
                    ["Handler"] = "Image",
                    ["URI"] = uri,
                    ["ResumeSupported"] = true,
                    ["LowFramerate"] = true,
                }
            end
        end
    },
    ["Livestream"] = {
        ["Detect"] = function(uri)
            local m = FindMatch(uri:gsub("%?.*$", ""), {
                "^http://www%.livestream%.com/([a-zA-Z0-9_]+)$",
                "^http://livestream%.com/([a-zA-Z0-9_]+)$",
            })
            
            if m then
                return m[1]
            end
        end,
        ["GetPlayer"] = function(uri, useJW)
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
                
                local url = "http://static.livestream.com/scripts/playerv2.js?" .. URLEncodeTable(vars)
                
                return {
                    ["Handler"] = "FlashAPI",
                    ["URI"] = url,
                    ["ResumeSupported"] = false,
                    ["LowFramerate"] = false,
                    ["HandlerArgs"] = {
                        ["URLIsJavaScript"] = true,
                        ["VolumeMul"] = 0.1,
                    },
                }
            end
        end
    },
    ["Vimeo"] = {
        ["Detect"] = function(uri)
            -- Easter egg / test media
            if uri == "timelapse" then
                uri = "http://www.vimeo.com/5273209"
            elseif uri == "kaflive" then
                uri = "http://www.vimeo.com/4389551"
            end
            
            local m = FindMatch(uri:gsub("%?.*$", ""), {
                "^http://[A-Za-z0-9%.%-]*%.vimeo%.com/([0-9]+)",
                "^http://vimeo%.com/([0-9]+)",
            })
            
            if m then
                return m[1]
            end
        end,
        ["GetPlayer"] = function(uri, useJW)
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
    },
}