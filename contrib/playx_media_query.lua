-- PlayX Media Query Extension
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

local lastResult = nil

local function UnHTMLEncode(s)
    -- Warning: Improper
    s = s:gsub("&lt;", "<")
    s = s:gsub("&gt;", ">")
    s = s:gsub("&quot;", "\"")
    s = s:gsub("&#34;", "'")
    s = s:gsub("&amp;", "&")
    return s
end

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

local function URLEncodeTable(vars)
    local str = ""
    
    for k, v in pairs(vars) do
        str = str .. URLEncode(k) .. "=" .. URLEncode(v) .. "&"
    end
    
    return str:sub(1, -2)
end

local function FindMatch(str, patterns)
    for _, pattern in pairs(patterns) do
        local m = {str:match(pattern)}
        if m[1] then return m end
    end
    
    return nil
end

local function QueryYouTubeTitle(id, successF, failureF)
    local vars = URLEncodeTable({
        ["alt"] = "atom",
        ["key"] = "AI39si7XNJTicSx18de-aAVYNq20Z0BVFwRo3l8xHu9s6L0YHFgmIlmuR8sabsj1WCghhfxdMzFgCYJapPfP3xTVdPdkTsxhXQ",
        ["client"] = SinglePlayer() and "SP" or ("MP:" .. GetConVar("hostname"):GetString()),
    })
    local url = "http://gdata.youtube.com/feeds/api/videos/" .. id .."?" .. vars

    http.Get(url, "", function(result, size)
        if size > 0 then
            local title = string.match(result, "<title type='text'>([^<]+)</title>")
            
            if title then
                successF(id, UnHTMLEncode(title))
            else
                failureF("Failed to fetch video.")
            end
        else
            failureF("An error occurred while querying YouTube.")
        end
    end)
end

local function SearchYouTube(q, successF, failureF)
    local vars = URLEncodeTable({
        ["alt"] = "atom",
        ["q"] = q,
        ["orderby"] = "relevance",
        ["max-results"] = "1",
        ["format"] = "5",
        ["key"] = "AI39si7XNJTicSx18de-aAVYNq20Z0BVFwRo3l8xHu9s6L0YHFgmIlmuR8sabsj1WCghhfxdMzFgCYJapPfP3xTVdPdkTsxhXQ",
        ["client"] = SinglePlayer() and "SP" or ("MP:" .. GetConVar("hostname"):GetString()),
    })
    local url = "http://gdata.youtube.com/feeds/api/videos?" .. vars

    http.Get(url, "", function(result, size)
        if size > 0 then
            local title = nil
            local videoID = string.match(result, "http://www%.youtube%.com/watch%?v=([A-Za-z0-9_%-]+)")
            
            if videoID then
                for m in string.gmatch(result, "<title type='text'>([^<]+)</title>") do
                    title = m
                end
            
                successF(videoID, UnHTMLEncode(title))
            else
                failureF("No results found.")
            end
        else
            failureF("An error occurred while querying YouTube.")
        end
    end)
end

local function Play(ply, provider, uri, lowFramerate)
    if PlayX.IsPermitted(ply) then
        local result, err = PlayX.OpenMedia(provider, uri, 0, lowFramerate, true, false)
        if not result then
            ply:ChatPrint("PlayX ERROR: " .. err)
        end
    else
        ply:ChatPrint("NOTE: You are not permitted to control the player")
    end
end

hook.Add("PlayerSay", "PlayXMediaQueryPlayerSay", function(ply, text, all, death)
    if not all then return end
    
    text = text:TrimRight()
    
    local m = FindMatch(text, {
        "^[!%.](yt) (.+)",
        "^[!%.](ytplay) (.+)",
        "^[!%.](ytplay)",
        "^[!%.](ytlisten) (.+)",
        "^[!%.](ytlisten)",
        "^[!%.](ytlast)",
    })
    
    if m then
        if m[1] == "yt" or (m[1] == "ytplay" and m[2]) or (m[1] == "ytlisten" and m[2]) then
            local function successF(videoID, title)
                lastResult = videoID
                
                if m[1] != "yt" then -- Play
                    Play(ply, "YouTube", videoID, m[1] == "ytlisten")
                end
                
                for _, v in pairs(player.GetAll()) do
                    v:ChatPrint(string.format("YouTube query: Query '%s': http://www.youtube.com/watch?v=%s (%s).",
                                              m[2], videoID, title))
                end
            end
            
            local function failureF(msg)
                ply:ChatPrint(string.format("YouTube query: No video found for query '%s'.", q))
            end
            
            SearchYouTube(m[2], successF, failureF)
        elseif m[1] == "ytplay" or m[1] == "ytlisten" or m[1] == "ytlast" then -- Play last
            if lastResult then
                Play(ply, "YouTube", lastResult, m[1] == "ytlisten")
            else
                ply:ChatPrint("ERROR: No last result exists!")
            end
        end
        
        return nil
    end
    
    local m = FindMatch(text, {
        "^[!%.]play (.+)",
        "^[!%.]link (.+)",
        "^[!%.]playx (.+)",
    })
    
    if m then
        Play(ply, "", m[1], false)
        
        return nil
    end
    
    local m = FindMatch(text, {
        "http://youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "http://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "http://[A-Za-z0-9%.%-]*%.youtube%.com/v/([A-Za-z0-9_%-]+)",
        "http://youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "http://[A-Za-z0-9%.%-]*%.youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    })
    
    if m then
        lastResult = m[1]
        
        local function successF(videoID, title)
            lastResult = videoID
            
            for _, v in pairs(player.GetAll()) do
                v:ChatPrint(string.format("YouTube video %s: \"%s\"",
                                          videoID, title))
            end
        end
        
        QueryYouTubeTitle(m[1], successF, function() end)
        
        return nil
    end
    
    return nil
end)