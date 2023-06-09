 -- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.8.26 by Dathus on 2021-04-11 05:29 PM (-03:00 GMT)
local Twitch = {}

function Twitch.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^https?://twitch.tv/([A-Za-z0-9_%-]+)",
        "^https?://www.twitch.tv/([A-Za-z0-9_%-]+)"
    })

    if m then
        return m[1]
    end
end

function Twitch.GetPlayer(uri, useJW)
    if uri:find("^[A-Za-z0-9_%-]+$") then
        local url = GetConVarString("playx_twitch_host_url"):Trim() .. "?channel=" .. uri
        
        return {
          ["Handler"] = "Twitch",
          ["URI"] = url,
          ["ResumeSupported"] = true,
          ["LowFramerate"] = false,
          ["MetadataFunc"] = function(callback, failCallback)
                Twitch.QueryMetadata(uri, callback, failCallback)
            end                
        }
    end
end

function Twitch.QueryMetadata(uri, callback, failCallback)   
      callback({
          ["URL"] = "https://www.twitch.tv/" .. uri,
      })
end

list.Set("PlayXProviders", "Twitch", Twitch)
list.Set("PlayXProvidersList", "Twitch", {"Twitch"})
 