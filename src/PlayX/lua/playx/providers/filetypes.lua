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

local Shoutcast = {}

function Shoutcast.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^http://[^:/]+/;stream%.nsv$",
        "^http://[^:/]+:[0-9]+/?$",
    })
    
    if m then
        return m[1]
    end
end

function Shoutcast.GetPlayer(uri, useJW)
    local m = playxlib.FindMatch(uri, {
        "^http://[^:/]+$",
        "^http://[^:/]+/$",
        "^http://[^:/]+:[0-9]+$",
        "^http://[^:/]+:[0-9]+/$",
        
        "^http://[^:/]+/;stream%.nsv$",
        "^http://[^:/]+:[0-9]+/;stream%.nsv$",
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
            ["Handler"] = "JW",
            ["Arguments"] = {
                URL = uri,
                Provider = "sound",
            },
            ["Resumable"] = true,
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

local MP3 = {}

function MP3.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^http://.+%.mp3$",
        "^http://.+%.MP3$",
    })
    
    if m then
        return m[1]
    end
end

function MP3.GetPlayer(uri, useJW)
    if uri:lower():find("^http://") then
        return {
            ["Handler"] = "JW",
            ["Arguments"] = {
                URL = uri,
                Provider = "sound",
            },
            ["Resumable"] = true,
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
end

function FlashVideo.GetPlayer(uri, useJW)
    if uri:lower():find("^http://") then
        return {
            ["Handler"] = "JW",
            ["Arguments"] = {
                URL = uri,
                Provider = "video",
            },
            ["Resumable"] = false,
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

local AnimatedImage = {}

function AnimatedImage.Detect(uri)
    return nil
end

function AnimatedImage.GetPlayer(uri, useJW)
    if uri:lower():find("^http://") then
        return {
            ["Handler"] = "Image",
            ["Arguments"] = {
                URL = uri,
            },
            ["Resumable"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                AnimatedImage.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function AnimatedImage.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "AnimatedImage", AnimatedImage)
list.Set("PlayXProvidersList", "AnimatedImage", {"Animated image"})

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
    if uri:lower():find("^http://") then
        return {
            ["Handler"] = "Image",
            ["Arguments"] = {
                URL = uri,
            },
            ["Resumable"] = true,
            ["LowFramerate"] = true,
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