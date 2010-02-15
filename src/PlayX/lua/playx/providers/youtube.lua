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

--- Gets the length of a YouTube video, for the YouTube provider.
-- @param id Video ID
-- @param callback Callback to call with length
local function GetLength(id, callback)
    local vars = PlayX.URLEncodeTable({
        ["alt"] = "atom",
        ["key"] = "AI39si79-V-ltHhNyYvyTeaiJeexopkZoiUA56Sk-W8Z5alYUkgntdwvkmu1avAWGNixM_DuLx8-Jai6qy1am7HhbhYvWERzWA",
        ["client"] = SinglePlayer() and "SP" or ("MP:" .. GetConVar("hostname"):GetString()),
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

local YouTube = {}

function YouTube.Detect(uri)    
    local m = PlayX.FindMatch(uri, {
        "^http://youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^http://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^http://[A-Za-z0-9%.%-]*%.youtube%.com/v/([A-Za-z0-9_%-]+)",
        "^http://youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^http://[A-Za-z0-9%.%-]*%.youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    })
    
    if m then
        return m[1]
    end
end

function YouTube.GetPlayer(uri, useJW)
    if uri:find("^[A-Za-z0-9_%-]+$") then
        if useJW and PlayX.JWPlayerSupportsYouTube() then
            return {
                ["Handler"] = "JW",
                ["URI"] = "http://www.youtube.com/watch?v=" .. uri,
                ["ResumeSupported"] = true,
                ["LowFramerate"] = false,
                ["LengthFunc"] = function(callback)
                    GetLength(uri, callback)
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
            local url = "http://www.youtube.com/v/" .. uri .. "&" .. PlayX.URLEncodeTable(vars)
            
            return {
                ["Handler"] = "FlashAPI",
                ["URI"] = url,
                ["ResumeSupported"] = true,
                ["LowFramerate"] = false,
                ["LengthFunc"] = function(callback)
                    GetLength(uri, callback)
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

list.Set("PlayXProviders", "YouTube", YouTube)