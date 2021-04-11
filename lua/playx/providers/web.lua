-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2021 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$

local StaticWeb = {}

function StaticWeb.Detect(uri)    
    return nil
end

function StaticWeb.GetPlayer(uri, useJW)
    if uri:find("^https?://") then
        return {
            ["Handler"] = "IFrame",
            ["URI"] = uri,
            ["ResumeSupported"] = true,
            ["LowFramerate"] = false,
            ["MetadataFunc"] = function(callback, failCallback)
                StaticWeb.QueryMetadata(uri, callback, failCallback)
            end,
        }
    end
end

function StaticWeb.QueryMetadata(uri, callback, failCallback)
    callback({
        ["URL"] = uri,
    })
end

list.Set("PlayXProviders", "StaticWeb", StaticWeb)
list.Set("PlayXProvidersList", "StaticWeb", {"Non-browsable Webpage"})