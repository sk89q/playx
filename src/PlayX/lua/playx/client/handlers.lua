-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
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

local WebResource = PlayX.MakeClass()

function WebResource:Initialize(vars)
    self.URL = vars.URL or nil
    self.CSS = vars.CSS or ""
    self.Script = vars.Script or ""
    self.ScriptURL = vars.ScriptURL or nil
    self.Body = vars.Body or ""
    self.VolumeScriptFunction = vars.VolumeScriptFunction or nil
end

function WebResource:Merge(resource)
    self.URL = resource.URL
    self.CSS = resource.CSS
    self.Script = resource.Script
    self.Body = resource.Body
end

function WebResource:GetVolumeScript(volume)
    if self.VolumeScriptFunction then
        return self.VolumeScriptFunction(volume)
    end
end

function WebResource:GetURL()
    return self.URL
end

function WebResource:GetCSS()
    return self.CSS
end

function WebResource:GetScript()
    return self.Script
end

function WebResource:GetScriptURL()
    return self.ScriptURL
end

function WebResource:GetBody()
    return self.Body
end

function WebResource:GetHTML()
    return [[
<!DOCTYPE html>
<html>
<head>
<title>PlayX</title>
<style type="text/css">
]] .. self.CSS .. [[
</style>
<script type="text/javascript">
]] .. self.Script .. [[
</script>
</head>
<body>
]] .. self.Body .. [[
</body>
</html>
]]
end

local function TryWebEngines(resource)
    local chrome = PlayX.GetEngine("ChromeEngine")
    local ie = PlayX.GetEngine("HTMLEngine")
    
    if chrome:IsSupported() then
        return chrome(resource)
    end
    
    return ie(resource)
end

--- Generates the HTML for an image viewer. The image viewer will automatically
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
<img src="]] .. PlayX.HTMLEncode(url) .. [[" alt="" onload="resize(this); keepResizing = false" style="margin: auto" />
</td>
</tr>
</table>
</div>
]]
    
    return WebResource({
        CSS = css,
    })
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
    local url = PlayX.HTMLEncode(url)
    local flashVarsString = flashVars and PlayX.URLEncodeTable(flashVars) or ""
    
    local css = [[
body {
  margin: 0;
  padding: 0;
  border: 0;
  background: #000000;
  overflow: hidden;
}]]
    
    if forcePlay then        
        js = (js or "") .. [[
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
  <param name="allowscriptaccess" value="always">
  <param name="allowfullscreen" value="false">
  <param name="FlashVars" value="]] .. flashVarsString .. [[">
]] .. extraParams .. [[
</object> 
</div>
]]

    return WebResource({
        CSS = css,
        Script = js,
        Body = body,
    })
end

--- Generate the HTML page for the JW player.
-- @param width
-- @param height
-- @param url 
-- @param provider JW player provider ("image", "audio", etc.)
-- @param start
-- @param volume
-- @return HTML
local function GenerateJWPlayer(width, height, url, provider, start, volume)
    local flashURL = PlayX.JWPlayerURL
    
    local flashVars = {
        ["autostart"] = "true",
        ["backcolor"] = "000000",
        ["frontcolor"] = "444444",
        ["start"] = start,
        ["volume"] = volume,
        ["file"] = url,
        ["playerready"] = "jwInit",
    }
    
    if provider then
        flashVars["provider"] = provider
    end
    
    local volumeScriptFunction = function(volume)
        return [[
try {
  document.getElementById('player').sendEvent("VOLUME", "]] .. tostring(volume) .. [[");
} catch(e) {}
]]
    end
    
    local resource = GenerateFlashPlayer(width, height, flashURL, flashVars)
    resource.volumeScriptFunction = volumeScriptFunction
    
    return TryWebEngines(resource)
end

--- Generates the HTML code for an included JavaScript file.
-- @param width
-- @param height
-- @param url
-- @return HTML
local function GenerateScriptEmbed(width, height, url, js)
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
    
    return WebResource({
        CSS = css,
        Script = js,
        Body = body,
        ScriptURL = url,
    })
end

local function StaticURLHandler(args, width, height, start, volume)
    return TryWebEngines(WebResource({
        URL = args.URL,
    }))
end

local function JWPlayerHandler(args, width, height, start, volume)
    return {
        Engine = TryWebEngines(GenerateJWPlayer(width, height, args.URL,
                                                nil, start, volume)),
        Centered = false,
    }
end

local function JWAudioHandler(args, width, height, start, volume)
    return {
        Engine = TryWebEngines(GenerateJWPlayer(width, height, args.URL, "sound")),
        Centered = false,
    }
end

local function JWVideoHandler(args, width, height, start, volume)
    return {
        Engine = TryWebEngines(GenerateJWPlayer(width, height, args.URI, "video")),
        Centered = false,
    }
end

local function JWRTMPHandler(args, width, height, start, volume)
    return {
        Engine = TryWebEngines(GenerateJWPlayer(width, height, args.URL, "rtmp")),
        Centered = false,
    }
end

local function FlashHandler(args, width, height, start, volume)
    local flashVars = args.FlashVars or {}
    local forcePlay = args.ForcePlay or false
    local centered = args.Centered
    local result = GenerateFlashPlayer(width, height, args.URL,
                                       flashVars, nil, forcePlay)
    
    if forcePlay then
        return {
            Engine = PlayX.GetEngine("HTMLEngine")(result),
            Centered = false,
        }
    else
        return {
            Engine = TryWebEngines(result),
            Centered = false,
        }
    end
end

local function ImageHandler(args, width, height, start, volume)
    return {
        Engine = TryWebEngines(GenerateImageViewer(width, height, args.URL)),
        Centered = true,
    }
end

local function FlashAPIHandler(args, width, height, start, volume)
    local url = args.URL
    local jsVolMul = args.ScriptVolumeMul and args.ScriptVolumeMul or 1
    local jsStartMul = args.ScriptStartMul and args.ScriptStartMul or 1
    
    if not args.NoDimRepl then
        url = url:gsub("__width__", width)
        url = url:gsub("__height__", height)
    end
    
    if args.VolumeMul ~= nil then
        url = url:gsub("__volume__", args.VolumeMul * volume)
    end
    
    if args.StartMul ~= nil then
        url = url:gsub("__start__", args.StartMul * start)
    end
    
    if args.ScriptInitFunc ~= nil then
        local code = ""
        
        if args.ScriptVolumeFunc then
            code = code .. "player." .. args.ScriptVolumeFunc .. "(" .. 
                tostring(jsVolMul * volume) .. ");"
        end
        
        if args.ScriptStartFunc then
            code = code .. "player." .. args.ScriptStartFunc .. "(" .. 
                tostring(jsStartMul * start) .. ");"
        end
        
        if args.ScriptPlayFunc then
            code = code .. "player." .. args.ScriptPlayFunc .. "();"
        end
    
        if args.RawInitScript ~= nil then
            code = code .. args.RawInitScript
        end
        
        js = js .. [[
var player;
function ]] .. args.ScriptInitFunc .. [[() {
  try {
    player = document.getElementById('player');
]] .. code .. [[
  } catch (e) {}
}
]]
    end
    
    if args.RawScript ~= nil then
        js = js .. args.RawScript
    end
    
    local resource
    
    if args.URLIsJavaScript then -- Include a Script file instead
        resource = GenerateScriptEmbed(width, height, url, js)
    else
        resource = GenerateFlashPlayer(width, height, url, nil, js)
    end
    
    if args.ScriptVolumeFunc then
        resource.volumeScriptFunction = function(volume)
            return "try { player." .. 
                args.ScriptVolumeFunc .. "(" .. 
                tostring(jsVolMul * volume) .. "); } catch (e) {}"
        end
    end
    
    return TryWebEngines(resource)
end

list.Set("PlayXHandlers", "StaticURL", StaticURLHandler)
list.Set("PlayXHandlers", "JW", JWPlayerHandler)
list.Set("PlayXHandlers", "JWVideo", JWAudioHandler)
list.Set("PlayXHandlers", "JWVideo", JWVideoHandler)
list.Set("PlayXHandlers", "JWRTMP", JWRTMPHandler)
list.Set("PlayXHandlers", "Flash", FlashHandler)
list.Set("PlayXHandlers", "Image", ImageHandler)
list.Set("PlayXHandlers", "FlashAPI", FlashAPIHandler)