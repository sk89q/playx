-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$

local Flash = {}

function Flash.Detect(uri)
    return nil
end

function Flash.GetPlayer(uri, useJW)
    if uri:lower():find("^https?://") then
        return {
            ["Handler"] = "Flash",
            ["URI"] = uri,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Flash.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function Flash.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "Flash", Flash)
list.Set("PlayXProvidersList", "Flash", {"Flash"})

local FlashMovie = {}

function FlashMovie.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^https?://.+%.swf$",
        "^https?://.+%.SWF$",
    })
    
    if m then
        return m[1]
    end
end

function FlashMovie.GetPlayer(uri, useJW)
    if uri:lower():find("^https?://") then
        return {
            ["Handler"] = "Flash",
            ["URI"] = uri,
            ["ResumeSupported"] = false,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                FlashMovie.QueryMetadata(uri, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["ForcePlay"] = true,
            },
        }
    end
end

function FlashMovie.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "FlashMovie", FlashMovie)
--list.Set("PlayXProvidersList", "FlashMovie", {"Flash movie [force play buttons]"})