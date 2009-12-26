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

--- Generates the HTML for an image viewer.
-- @param width
-- @param height
-- @param url
-- @return HTML
local function GenerateImageViewer(width, height, url)
    url = url:gsub("&", "&amp;"):gsub("\"", "&quot;")
    
    return [[
<!DOCTYPE html>
<html>
<head>
<title>PlayX</title>
<style type="text/css">
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
</style>
<script type="text/javascript">
var keepResizing = true
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
</script>
</head>
<body>
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
<table border="0" cellpadding="0" cellmargin="0" style="width: ]] .. width .. [[px; height: ]] .. height .. [[px">
<tr>
<td>
<img src="]] .. url .. [[" alt="" onload="resize(this); keepResizing = false" />
</td>
</tr>
</table>
</div>
</body>
</html>
]]
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
    url = url:gsub("&", "&amp;"):gsub("\"", "&quot;")
    
    if not flashVars then
        flashVars = ""
    else
        flashVars = URLEncodeTable(flashVars)
    end
    
    if forcePlay then
        if not js then js = "" end
        
        js = js .. [[
setInterval(function() {
  try {
    var player = document.getElementById('player');
    if (!player.IsPlaying()) { player.play(); }
  } catch (e) {}
}, 1000)
]]
        extraParams = [[
<param name="loop" value="false">
]]
    end
    
    if js then
        js = "<script type=\"text/javascript\">" .. js .. "</script>"
    else
        js = ""
    end
    
    return [[
<!DOCTYPE html>
<html>
<head>
<title>PlayX</title>
<style type="text/css">
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}
</style>
]] .. js .. [[
</head>
<body>
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" 
  type="application/x-shockwave-flash"
  src="]] .. url .. [["
  width="100%" height="100%" id="player">
  <param name="movie" value="]] .. url .. [[">
  <param name="quality" value="high">
  <param name="allowscriptaccess" value="always">
  <param name="allowfullscreen" value="false">
  <param name="FlashVars" value="]] .. flashVars .. [[">
]] .. extraParams .. [[
</object> 
</div>
</body>
</html>
]]
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
    }
    
    if provider then
        flashVars["provider"] = provider
    end
    
    return GenerateFlashPlayer(width, height, flashURL, flashVars)
end

--- Generates the HTML code for an included JavaScript file.
-- @param width
-- @param height
-- @param url
-- @return HTML
local function GenerateJSEmbed(width, height, url, js)
    url = url:gsub("&", "&amp;"):gsub("\"", "&quot;")
    
    if js then
        js = "<script type=\"text/javascript\">" .. js .. "</script>"
    else
        js = ""
    end
    
    return [[
<!DOCTYPE html>
<html>
<head>
<title>PlayX</title>
<style type="text/css">
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}
</style>
]] .. js .. [[
</head>
<body>
<div style="width: ]] .. width .. [[px; height: ]] .. height .. [[px; overflow: hidden">
  <script src="]] .. url .. [[" type="text/javascript"></script>
</div>
</body>
</html>
]]
end

PlayX.Providers = {
    ["YouTube"] = "YouTube",
    ["Flash"] = "Flash [don't force play]",
    ["FlashMovie"] = "Flash movie [force play buttons]",
    ["MP3"] = "MP3",
    ["FlashVideo"] = "FLV/MP4/AAC",
    ["AnimatedImage"] = "Animated image",
    ["Image"] = "Image",
    ["Livestream"] = "Livestream",
    ["Vimeo"] = "Vimeo",
}

PlayX.Handlers = {
    ["JW"] = function(width, height, start, volume, uri)
        return GenerateJWPlayer(width, height, start, volume, uri, handlerArgs), false
    end,
    ["JWVideo"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateJWPlayer(width, height, start, volume, uri, "video"), false
    end,
    ["JWAudio"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateJWPlayer(width, height, start, volume, uri, "sound"), false
    end,
    ["JWRTMP"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateJWPlayer(width, height, start, volume, uri, "rtmp"), false
    end,
    ["Flash"] = function(width, height, start, volume, uri, handlerArgs)
        local flashVars = {}
        if handlerArgs.FlashVars then
            flashVars = handlerArgs.FlashVars
        end
        local forcePlay = handlerArgs.ForcePlay
        local center = handlerArgs.Center
        return GenerateFlashPlayer(width, height, uri, flashVars, nil, forcePlay), center
    end,
    ["Image"] = function(width, height, start, volume, uri, handlerArgs)
        return GenerateImageViewer(width, height, uri), true -- Center
    end,
    ["FlashAPI"] = function(width, height, start, volume, uri, handlerArgs)
        local url = uri
        local js = ""
        
        if not handlerArgs.NoDimRepl then
            url = url:gsub("__width__", width)
            url = url:gsub("__height__", height)
        end
        
        if handlerArgs.VolumeMul != nil then
            url = url:gsub("__volume__", handlerArgs.VolumeMul * volume)
        end
        
        if handlerArgs.StartMul != nil then
            url = url:gsub("__start__", handlerArgs.StartMul * start)
        end
        
        if handlerArgs.JSInitFunc != nil then
            local code = ""
            local jsVolMul = handlerArgs.JSVolumeMul and handlerArgs.JSVolumeMul or 1
            local jsStartMul = handlerArgs.JSStartMul and handlerArgs.JSStartMul or 1
            
            if handlerArgs.JSVolumeFunc then
                code = code .. "player." .. handlerArgs.JSVolumeFunc .. "(" .. 
                    tostring(jsVolMul * volume) .. ");"
            end
            
            if handlerArgs.JSStartFunc then
                code = code .. "player." .. handlerArgs.JSStartFunc .. "(" .. 
                    tostring(jsStartMul * start) .. ");"
            end
            
            if handlerArgs.JSPlayFunc then
                code = code .. "player." .. handlerArgs.JSPlayFunc .. "();"
            end
        
        if handlerArgs.RawInitJS != nil then
            code = code .. handlerArgs.RawInitJS
        end
            
            js = js .. [[
function ]] .. handlerArgs.JSInitFunc .. [[() {
  try {
    var player = document.getElementById('player');
]] .. code .. [[
  } catch (e) {}
}
]]
        end
        
        if handlerArgs.RawJS != nil then
            js = js .. handlerArgs.RawJS
        end
        
        if handlerArgs.URLIsJavaScript then -- Include a JS file instead
            return GenerateJSEmbed(width, height, url, js), false
        else
            return GenerateFlashPlayer(width, height, url, nil, js), false
        end
    end,
}