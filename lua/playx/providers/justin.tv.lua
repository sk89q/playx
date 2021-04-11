-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2021 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$

local JustinTV = {}

function JustinTV.Detect(uri)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "^https?://www%.justin%.tv/([a-zA-Z0-9_/]+)$",
        "^https?://justin%.tv/([a-zA-Z0-9_/]+)$",
    })
    
    if m then
        return m[1]
    end
end

function JustinTV.GetPlayer(uri, useJW)
    if uri:lower():find("^[a-zA-Z0-9_/]+$") then
        return {
            ["Handler"] = "justin.tv",
            ["URI"] = GetConVarString("playx_host_url"),
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                JustinTV.QueryMetadata(uri, callback, failCallback)
            end,
            ["HandlerArgs"] = {
                ["URL"] = uri           
            }
    }
    end
end

function JustinTV.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = "http://www.justin.tv/" .. uri,
    })
end

list.Set("PlayXProviders", "justin.tv", JustinTV)
list.Set("PlayXProvidersList", "justin.tv", {"justin.tv"})