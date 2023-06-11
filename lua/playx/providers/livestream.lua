-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
--
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
--
-- $Id$
-- Version 2.9.5 by Dathus [BR] on 2023-06-11 11:22 AM (-03:00 GMT)

local Livestream = {}

function Livestream.Detect(uri, useJW)
  local m = playxlib.FindMatch(uri, {
    "^https?://livestream%.com/accounts/([0-9]+/events/[0-9]+/videos/[0-9]+)",
    "^https?://livestream%.com/accounts/([0-9]+/events/[0-9]+)",
    "^https?://livestream%.com/accounts/([0-9]+/[A-Za-z0-9%-%_%.]+)"
  })
  
  if m then
    return m[1]
  end
end

function Livestream.GetPlayer(url, useJW)
  if url:find("^[A-Za-z0-9_%-%/]+$") then
    return {
      ["Handler"] = "Livestream",
      ["URI"] = GetConVarString("playx_livestream_host_url"):Trim() .. "?path=accounts/" .. url,
      ["ResumeSupported"] = false,
      ["LowFramerate"] = false,
      ["MetadataFunc"] = function(callback, failCallback)
        Livestream.QueryMetadata(url, callback, failCallback)
      end      
    }
  end
end

function Livestream.QueryMetadata(uri, callback, failCallback)
  callback({
    ["URL"] = "https://livestream.com/" .. uri,
  })
end

list.Set("PlayXProviders", "Livestream", Livestream)
list.Set("PlayXProvidersList", "Livestream", {"Livestream"})
