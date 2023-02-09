 -- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.8.26 by Dathus on 2021-04-11 05:29 PM (-03:00 GMT)
local TwitchVod = {}

function TwitchVod.Detect(uri)
    local m = playxlib.FindMatch(uri, {
        "^https?://twitch.tv/videos/([0-9]+)",
        "^https?://www.twitch.tv/videos/([0-9]+)"
    })

    if m then
        return m[1]
    end
end

function TwitchVod.GetPlayer(uri, useJW)
    if uri:find("^[0-9]+$") then
        local url = "https://ziondevelopers.github.io/playx/twitchhost.html?videoId=" .. uri
        
        return {
          ["Handler"] = "TwitchVod",
          ["URI"] = url,
          ["ResumeSupported"] = true,
          ["LowFramerate"] = false,
          ["MetadataFunc"] = function(callback, failCallback)
                TwitchVod.QueryMetadata(uri, callback, failCallback)
            end                
        }
    end
end

function TwitchVod.QueryMetadata(uri, callback, failCallback)   
      callback({
          ["URL"] = "https://www.twitch.tv/videos/" .. uri,
      })
end

list.Set("PlayXProviders", "TwitchVod", TwitchVod)
list.Set("PlayXProvidersList", "TwitchVod", {"TwitchVod"})
 