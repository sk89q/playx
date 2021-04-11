-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2021 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$

local Hulu = {}

function Hulu.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^https?://www.hulu.com/watch/[0-9]+$",
    })
    
    if m then
        return uri
    end
end

function Hulu.GetPlayer(uri, useJW)
    local m = playxlib.FindMatch(uri, {
        "^https?://www.hulu.com/watch/[0-9]+$",
    })
    
    if m then
        return {
            ["Handler"] = "Hulu",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                Hulu.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function Hulu.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "Hulu", Hulu)
list.Set("PlayXProvidersList", "Hulu", {"Hulu"})