-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2021 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.8.26 by Dathus on 2021-04-11 05:29 PM (-03:00 GMT)

list.Set("PlayXHandlers", "IFrame", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateIFrame(width, height, uri)
end)

list.Set("PlayXHandlers", "YoutubeNative", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateYoutubeEmbed(width, height, start, volume, uri, "youtube")
end)

list.Set("PlayXHandlers", "Twitch", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateTwitchEmbed(width, height, start, volume, uri, "twitch")
end)

list.Set("PlayXHandlers", "TwitchVod", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateTwitchEmbed(width, height, start, volume, uri, "twitchvod")
end)

list.Set("PlayXHandlers", "JW", function(width, height, start, volume, uri, handlerArgs)
     return playxlib.GenerateJWPlayer(width, height, start, volume, uri, handlerArgs)
end)

list.Set("PlayXHandlers", "JWVideo", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateJWPlayer(width, height, start, volume, uri, "video")
end)

--list.Set("PlayXHandlers", "JWYoutube", function(width, height, start, volume, uri, handlerArgs)
--    return playxlib.GenerateJWPlayer(width, height, start, volume, "http://www.youtube.com/watch?v="..uri, "youtube")
--end)

list.Set("PlayXHandlers", "JWAudio", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateJWPlayer(width, height, start, volume, uri, "mp3")
end)

list.Set("PlayXHandlers", "JWRTMP", function(width, height, start, volume, uri, handlerArgs)
     return playxlib.GenerateJWPlayer(width, height, start, volume, uri, "rtmp")
end)

list.Set("PlayXHandlers", "Flash", function(width, height, start, volume, uri, handlerArgs)
    local flashVars = handlerArgs.FlashVars and handlerArgs.FlashVars or {}
    local forcePlay = handlerArgs.ForcePlay
    local center = handlerArgs.Center
    local result = playxlib.GenerateFlashPlayer(width, height, uri, flashVars, nil, forcePlay)
    result.center = center
    return result
end)

list.Set("PlayXHandlers", "Image", function(width, height, start, volume, uri, handlerArgs)
    local result = playxlib.GenerateImageViewer(width, height, uri)
    result.center = true
    return result
end)

list.Set("PlayXHandlers", "FlashAPI", function(width, height, start, volume, uri, handlerArgs)
    local url = uri
    local js = ""
    local result = nil
    local volChangeJSF = nil
    
    if not handlerArgs.NoDimRepl then
        url = url:gsub("__width__", width)
        url = url:gsub("__height__", height)
    end
    
    if handlerArgs.VolumeMul ~= nil then
        url = url:gsub("__volume__", handlerArgs.VolumeMul * volume)
    end
    
    if handlerArgs.StartMul ~= nil then
        url = url:gsub("__start__", handlerArgs.StartMul * start)
    end
    
    if handlerArgs.JSInitFunc ~= nil then
        local code = ""
        local jsVolMul = handlerArgs.JSVolumeMul and handlerArgs.JSVolumeMul or 1
        local jsStartMul = handlerArgs.JSStartMul and handlerArgs.JSStartMul or 1
        
        if handlerArgs.JSVolumeFunc then
            code = code .. "try { player." .. handlerArgs.JSVolumeFunc .. "(" .. 
                tostring(jsVolMul * volume) .. "); } catch (e) {}"
            
            volChangeJSF = function(volume)
                return "try { player." .. handlerArgs.JSVolumeFunc .. "(" ..  tostring(jsVolMul * volume) .. "); } catch (e) {}"
            end
        end
        
        if handlerArgs.JSStartFunc then
            code = "try { "..code .. "player." .. handlerArgs.JSStartFunc .. "(" .. tostring(jsStartMul * start) .. "); } catch (e) {}"
        end

        if handlerArgs.RawInitJS ~= nil then
            code = code .. handlerArgs.RawInitJS
        end
        
        js = js .. [[
var player;
try {
	function ]] .. handlerArgs.JSInitFunc .. [[() {  
	    player = document.getElementById('player');
	]] .. code .. [[
	}
} catch (e) {}
]]
    end
    
    if handlerArgs.RawJS ~= nil then
        js = js .. handlerArgs.RawJS
    end
    
    if handlerArgs.URLIsJavaScript then -- Include a JS file instead
        result = playxlib.GenerateJSEmbed(width, height, url, js)
    else
        result = playxlib.GenerateFlashPlayer(width, height, url, nil, js)
    end
    
    if volChangeJSF then
        result.GetVolumeChangeJS = volChangeJSF
    end
    
    return result
end)
