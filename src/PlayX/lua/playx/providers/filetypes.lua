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

local MP3 = {}

function MP3.Detect(uri)
    local m = PlayX.FindMatch(uri:gsub("%?.*$", ""), {
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
            ["Handler"] = "JWAudio",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = true,
        }
    end
end

list.Set("PlayXProviders", "MP3", MP3)

local FlashVideo = {}

function FlashVideo.Detect(uri)
    local m = PlayX.FindMatch(uri:gsub("%?.*$", ""), {
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
            ["Handler"] = "JWVideo",
            ["URI"] = uri,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
        }
    end
end

list.Set("PlayXProviders", "FlashVideo", FlashVideo)

local AnimatedImage = {}

function AnimatedImage.Detect(uri)
    return nil
end

function AnimatedImage.GetPlayer(uri, useJW)
    if uri:lower():find("^http://") then
        return {
            ["Handler"] = "Image",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
        }
    end
end

list.Set("PlayXProviders", "AnimatedImage", AnimatedImage)

local Image = {}

function Image.Detect(uri)
    local m = PlayX.FindMatch(uri:gsub("%?.*$", ""), {
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
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = true,
        }
    end
end

list.Set("PlayXProviders", "Image", Image)