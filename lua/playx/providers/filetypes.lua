-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.8.5 by Nexus [BR] on 10-01-2014 09:25 PM (-02:00 GMT)

local Shoutcast = {}

function Shoutcast.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^https?://[^:/]+/;stream%.nsv$",
        "^https?://[^:/]+:[0-9]+/?$",
    })
    
    if m then
        return m[1]
    end
end

function Shoutcast.GetPlayer(uri, useJW)
    local m = playxlib.FindMatch(uri, {
        "^https?://.+$",
    })
    
    if m then
        if not uri:lower():find("^;stream%.nsv") then
            if uri:find("/$") then
                uri = uri .. ";stream%.nsv"
            else
                uri = uri .. "/;stream%.nsv"
            end
        end
        
        return {
            ["Handler"] = "JWAudio",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = true,
            ["MetadataFunc"] = function(callback, failCallback)
                Shoutcast.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function Shoutcast.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "Shoutcast", Shoutcast)
list.Set("PlayXProvidersList", "Shoutcast", {"Shoutcast"})

-- RTMP
local RTMP = {}

function RTMP.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^rtmp://.+$",
        "^rtmp://.+$",
    })
    
    if m then
        return uri
    end
end

function RTMP.GetPlayer(uri, useJW)
    local m = playxlib.FindMatch(uri, {
        "^rtmp://.+$",
    })
    
    if m then       
        return {
            ["Handler"] = "JWRTMP",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                RTMP.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function RTMP.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "RTMP", RTMP)
list.Set("PlayXProvidersList", "RTMP", {"RTMP"})

local MP3 = {}

function MP3.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^https?://.+%.mp3$",
        "^https?://.+%.MP3$",
    })
    
    if m then
        return m[1]
    end
end

function MP3.GetPlayer(uri, useJW)
    if uri:lower():find("^https?://") then
        return {
            ["Handler"] = "JWAudio",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = true,
            ["MetadataFunc"] = function(callback, failCallback)
                MP3.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function MP3.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "MP3", MP3)
list.Set("PlayXProvidersList", "MP3", {"MP3"})

local FlashVideo = {}

function FlashVideo.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^https?://.+%.flv$",
        "^https?://.+%.FLV$",
        "^https?://.+%.mp4$",
        "^https?://.+%.MP4$",
        "^https?://.+%.aac$",
        "^https?://.+%.AAC$",
    })
    
    if m then
        return m[1]
    end
end

function FlashVideo.GetPlayer(uri, useJW)
    if uri:lower():find("^https?://") then
        return {
            ["Handler"] = "JWVideo",
            ["URI"] = uri,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                FlashVideo.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function FlashVideo.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "FlashVideo", FlashVideo)
list.Set("PlayXProvidersList", "FlashVideo", {"FLV/MP4/AAC"})

local Image = {}

function Image.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
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
end

function Image.GetPlayer(uri, useJW)
    if uri:lower():find("^https?://") then
        return {
            ["Handler"] = "Image",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Image.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function Image.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "Image", Image)
list.Set("PlayXProvidersList", "Image", {"Image"})
list.Set("PlayXProviders", "AnimatedImage", Image) -- Legacy