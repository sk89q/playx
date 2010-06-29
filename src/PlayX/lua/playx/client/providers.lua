-- PlayX
-- Copyright (c) 2009 sk89q <http://www.sk89q.com>
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

local HandlerResult = {}

function HandlerResult:new(css, js, body, jsURL, center, url)
    local instance = {
        ["CSS"] = css,
        ["Body"] = body,
        ["JS"] = js,
        ["JSInclude"] = jsURL,
        ["Center"] = center,
        ["ForceIE"] = false,
        ["ForceURL"] = url,
    }
    
    setmetatable(instance, self)
    self.__index = self
    return instance
end

function HandlerResult:GetVolumeChangeJS(volume)
    return nil
end

function HandlerResult:AppendJavaScript(js)
    self.JS = (self.JS and self.JS or "") .. js
end

function HandlerResult:GetHTML()
    return [[
<!DOCTYPE html>
<html>
<head>
<title>PlayX</title>
<style type="text/css">
]] .. self.CSS .. [[
</style>
<script type="text/javascript">
]] .. (self.JS and self.JS or "") .. [[
</script>
</head>
<body>
]] .. self.Body .. [[
</body>
</html>
]]
end

--- Percent encodes a value.
-- @param s String
-- @return Encoded
local function URLEncode(s)
    s = tostring(s)
    local new = ""
    
    for i = 1, #s do
        local c = s:sub(i, i)
        local b = c:byte()
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
            (b >= 48 and b <= 57) or
            c == "_" or c == "." or c == "~" then
            new = new .. c
        else
            new = new .. string.format("%%%X", b)
        end
    end
    
    return new
end

--- Percent encodes a table for the query part of a URL.
-- @param vars Table of keys and values
-- @return Encoded string
local function URLEncodeTable(vars)
    local str = ""
    
    for k, v in pairs(vars) do
        str = str .. URLEncode(k) .. "=" .. URLEncode(v) .. "&"
    end
    
    return str:sub(1, -2)
end

--- HTML encodes a string.
-- @param str
-- @return Encoded string
local function HTMLEncode(str)
    return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;")
end

--- Generates the HTML for an IFrame.
-- @param width
-- @param height
-- @param url
-- @return HTML
local function GenerateIFrame(width, height, url)    
    return HandlerResult:new("", "", "", "", false, url)
end

--- Generates the HTML for an image viewer. The image viewer will automatiaclly
-- center the image (once size information becomes exposed in JavaScript).
-- @param width
-- @param height
-- @param url
-- @return HTML
local function GenerateImageViewer(width, height, url)
    local url = HTMLEncode(url)
    
    -- CSS to center the image
    local css = [[
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}
td {
  text-align: center;
  vertical-align: middle;
}
]]
    
    -- Resizing code
    local js = [[
var keepResizing = true;
function resize(obj) {
  var ratio = obj.width / obj.height;
  if (]] .. width .. [[ / ]] .. height .. [[ > ratio) {
    obj.style.width = (]] .. height .. [[ * ratio) + "px";
  } else {
    obj.style.height = (]] .. width .. [[ / ratio) + "px";
  }
}
setInterval(function() {
  if (keepResizing && document.images[0]) {
    resize(document.images[0]);
  }
}, 1000);
]]
    
    local body = [[
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
<table border="0" cellpadding="0" cellmargin="0" style="width: ]] .. width .. [[px; height: ]] .. height .. [[px">
<tr>
<td style="text-align: center">
<img src="]] .. url .. [[" alt="" onload="resize(this); keepResizing = false" style="margin: auto" />
</td>
</tr>
</table>
</div>
]]
    
    return HandlerResult:new(css, js, body)
end

--- Generates the HTML for a Flash player viewer.
-- @param width
-- @param height
-- @param url
-- @param flashVars Table
-- @param js Extra JavaScript to add
-- @param forcePlay Forces the movie to be 'played' every 1 second, if not playing
-- @return HTML
local function GenerateFlashPlayer(width, height, url, flashVars, js, forcePlay)
    local extraParams = ""
    local url = HTMLEncode(url)
    local flashVars = flashVars and URLEncodeTable(flashVars) or ""
    
    local css = [[
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}]]
    
    if forcePlay then        
        js = (js and js or "") .. [[
setInterval(function() {
  try {
    var player = document.getElementById('player');
    if (player && !player.IsPlaying()) {
      player.play();
    }
  } catch (e) {}
}, 1000);
]]
        extraParams = [[
<param name="loop" value="false">
]]
    end
    
    local body = [[
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" 
  type="application/x-shockwave-flash"
  src="]] .. url .. [["
  width="100%" height="100%" id="player">
  <param name="movie" value="]] .. url .. [[">
  <param name="quality" value="high">
  <param name="allowscriptaccess" value="internal">
  <param name="allowfullscreen" value="false">
  <param name="FlashVars" value="]] .. flashVars .. [[">
]] .. extraParams .. [[
</object> 
</div>
]]
    
    local result = HandlerResult:new(css, js, body)
    if forcePlay then result.ForceIE = true end
    return result
end

--- Generate the HTML page for the JW player.
-- @param width
-- @param height
-- @param start In seconds
-- @param volume 0-100
-- @param uri
-- @param provider JW player provider ("image", "audio", etc.)
-- @return HTML
local function GenerateJWPlayer(width, height, start, volume, uri, provider)
    local flashURL = PlayX.JWPlayerURL
    local flashVars = {
        ["autostart"] = "true",
        ["backcolor"] = "000000",
        ["frontcolor"] = "444444",
        ["start"] = start,
        ["volume"] = volume,
        ["file"] = uri,
        ["playerready"] = "jwInit",
    }
    
    if provider then
        flashVars["provider"] = provider
    end
    
    local result = GenerateFlashPlayer(width, height, flashURL, flashVars)
    
    result.GetVolumeChangeJS = function(volume)
        return [[
try {
  document.getElementById('player').sendEvent("VOLUME", "]] .. tostring(volume) .. [[");
} catch(e) {}
]]
    end
    
    return result
end

--- Generates the HTML code for an included JavaScript file.
-- @param width
-- @param height
-- @param url
-- @return HTML
local function GenerateJSEmbed(width, height, url, js)
    local url = HTMLEncode(url)
    
    local css = [[
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}
]]

    local body = [[
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
  <script src="]] .. url .. [[" type="text/javascript"></script>
</div>
]]
    
    return HandlerResult:new(css, js, body, url)
end

PlayX.Providers = {}

PlayX.Handlers = {
    ["IFrame"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateIFrame(width, height, uri)
    end,
    ["JW"] = function(width, height, start, volume, uri)
        return GenerateJWPlayer(width, height, start, volume, uri, handlerArgs)
    end,
    ["JWVideo"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateJWPlayer(width, height, start, volume, uri, "video")
    end,
    ["JWAudio"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateJWPlayer(width, height, start, volume, uri, "sound")
    end,
    ["JWRTMP"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateJWPlayer(width, height, start, volume, uri, "rtmp")
    end,
    ["Flash"] = function(width, height, start, volume, uri, handlerArgs)
        local flashVars = handlerArgs.FlashVars and handlerArgs.FlashVars or {}
        local forcePlay = handlerArgs.ForcePlay
        local center = handlerArgs.Center
        local result = GenerateFlashPlayer(width, height, uri, flashVars, nil, forcePlay)
        result.center = center
        return result
    end,
    ["Image"] = function(width, height, start, volume, uri, handlerArgs)
        local result = GenerateImageViewer(width, height, uri)
        result.center = true
        return result
    end,
    ["FlashAPI"] = function(width, height, start, volume, uri, handlerArgs)
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
                code = code .. "player." .. handlerArgs.JSVolumeFunc .. "(" .. 
                    tostring(jsVolMul * volume) .. ");"
                
                volChangeJSF = function(volume)
                    return "try { player." .. 
                        handlerArgs.JSVolumeFunc .. "(" .. 
                        tostring(jsVolMul * volume) .. "); } catch (e) {}"
                end
            end
            
            if handlerArgs.JSStartFunc then
                code = code .. "player." .. handlerArgs.JSStartFunc .. "(" .. 
                    tostring(jsStartMul * start) .. ");"
            end
            
            if handlerArgs.JSPlayFunc then
                code = code .. "player." .. handlerArgs.JSPlayFunc .. "();"
            end
        
            if handlerArgs.RawInitJS ~= nil then
                code = code .. handlerArgs.RawInitJS
            end
            
            js = js .. [[
var player;
function ]] .. handlerArgs.JSInitFunc .. [[() {
  try {
    player = document.getElementById('player');
]] .. code .. [[
  } catch (e) {}
}
]]
        end
        
        if handlerArgs.RawJS ~= nil then
            js = js .. handlerArgs.RawJS
        end
        
        if handlerArgs.URLIsJavaScript then -- Include a JS file instead
            result = GenerateJSEmbed(width, height, url, js)
        else
            result = GenerateFlashPlayer(width, height, url, nil, js)
        end
        
        if volChangeJSF then
            result.GetVolumeChangeJS = volChangeJSF
        end
        
        return result
    end,
}