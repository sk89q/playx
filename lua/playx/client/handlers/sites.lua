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
-- Version 2.7.4 by Nexus [BR] on 04-03-2013 07:42 PM

list.Set("PlayXHandlers", "Hulu", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.HandlerResult{
        url = uri,
        center = true,
        css = [[
* { overflow: hidden !important; }
]],
        js = [[
var m = document.head.innerHTML.match(/\/embed\/([^"]+)"/);
if (m) {
    document.body.style.overflow = 'hidden';
    var id = m[1];
    document.body.innerHTML = '<div id="player-container"></div>'
    var swfObject = new SWFObject("/site-player/playerembedwrapper.swf?referrer=none&eid="+id+"&st=&et=&it=&ml=0&siteHost=http://www.hulu.com", "player", "]] .. width .. [[", "]] .. height .. [[", "10.0.22");
    swfObject.useExpressInstall("/expressinstall.swf");
    swfObject.setAttribute("style", "position:fixed;top:0;left:0;width:1024px;height:512px;z-index:99999;");
    swfObject.addParam("allowScriptAccess", "always");
    swfObject.addParam("allowFullscreen", "true");
    swfObject.addVariable("popout", "true");
    swfObject.addVariable("plugins", "1");
    swfObject.addVariable("modes", 4);
    swfObject.addVariable("initMode", 4);
    swfObject.addVariable("sortBy", "");
    swfObject.addVariable("continuous_play_on", "false");
    swfObject.addVariable("st", ]] .. start .. [[);
    swfObject.addVariable("stage_width", "]] .. width .. [[");
    swfObject.addVariable("stage_height", "]] .. height .. [[");
    swfObject.write("player-container");
} else {
    document.body.innerHTML = 'Failure to detect ID.'
}
]]}
end)

list.Set("PlayXHandlers", "justin.tv", function(width, height, start, volume, uri, handlerArgs)
	if uri:find("/b/") then
		uri = uri:split("/b/")
		uri = uri[1].."&archive_id="..uri[2]
	end
	
    return playxlib.HandlerResult{
        center = true,      
        body = [[<object type="application/x-shockwave-flash" height="]] .. height .. [[" width="]] ..width.. [[" id="clip_embed_player_flash" data="http://www-cdn.justin.tv/widgets/]]..(uri:find('archive_id') and 'archive' or 'live')..[[_site_player.swf" bgcolor="#000000"><param name="movie" value="http://www-cdn.justin.tv/widgets/]]..(uri:find('archive_id') and 'archive' or 'live')..[[_site_player.swf" /><param name="allowScriptAccess" value="always" /><param name="allowNetworking" value="all" /><param name="allowFullScreen" value="true" /><param name="flashvars" value="auto_play=true&start_volume=]]..volume..[[&title=Title&channel=]]..uri..[[" /></object>]]
    }
end)

list.Set("PlayXHandlers", "Vimeo", function(width, height, start, volume, uri, handlerArgs)
    
    local volumeFunc = function(volume)	    
        return [[document.getElementsByTagName('object')[0].api_setVolume(]]..playxlib.volumeFloat(volume)..[[);]]
    end

    local playFunc = function(volume)
        return [[document.getElementsByTagName('object')[0].api_play();document.getElementsByTagName('object')[0].style.width='100%';]]
    end

    local pauseFunc = function(volume)
        return [[document.getElementsByTagName('object')[0].api_pause();document.getElementsByTagName('object')[0].style.width='1px';]]
    end
	    
    return playxlib.HandlerResult{
        url = "http://player.vimeo.com/video/" .. playxlib.JSEscape(uri) .. "?api=1&player_id=player&autoplay=1",
        center = false,
        volumeFunc = volumeFunc,
        playFunc = playFunc,
        pauseFunc = pauseFunc,

        js = [[
var checkReady = setInterval(function(){ if(document.readyState === "complete"){ playerReady(); clearInterval(checkReady);} }, 10);
var knownState = "Loading...";
var player = document.getElementsByTagName('object')[0];

function sendPlayerData(data) {
    var str = "";
    for (var key in data) {
        str += encodeURIComponent(key) + "=" + encodeURIComponent(data[key]) + "&"
    }
    playx.processPlayerData(str);
}

function updateState() {
  sendPlayerData({ Title: "test", State: knownState, Position: player.api_getCurrentTime(), Duration: player.api_getDuration() });
}

function onPlayerStateChange(state) {
  var msg;
  
  if (state == -1) {
    msg = "Loading...";
  } else if (state == 0) {
    msg = "Playback complete.";
  } else if (state == 1) {
    msg = "Playing...";
  } else if (state == 2) {
    msg = "Paused.";
  } else if (state == 3) {
    msg = "Buffering...";
  } else {
    msg = "Unknown state: " + state;
  }
  
  knownState = msg;  
  sendPlayerData({ State: msg, Position: player.api_getCurrentTime(), Duration: player.api_getDuration() });
}

function onFinish(){
	onPlayerStateChange(0);	
}

function onPlay(){
	onPlayerStateChange(1);	
}

function onPause(){
	onPlayerStateChange(2);	
}

function playerReady() {  
  player.api_setVolume(]] .. playxlib.volumeFloat(volume) .. [[);
  player.api_addEventListener('finish', 'onFinish');
  player.api_addEventListener('play', 'onPlay');
  player.api_addEventListener('pause', 'onPause');
  player.api_seekTo(]]..start..[[);
  setInterval(updateState, 250);
}
]]
}
end)

list.Set("PlayXHandlers", "YouTubePopup", function(width, height, start, volume, uri, handlerArgs)
    local volumeFunc = function(volume)
        return [[document.getElementsByTagName('embed')[0].setVolume(]] .. volume .. [[);]]
    end
    
    local playFunc = function(volume)
        return [[document.getElementsByTagName('embed')[0].playVideo();document.getElementsByTagName('embed')[0].style.width='100%';]]
    end
    
    local pauseFunc = function(volume)
        return [[document.getElementsByTagName('embed')[0].pauseVideo();document.getElementsByTagName('embed')[0].style.width='1px';]]
    end
	    
    return playxlib.HandlerResult{
        url = "http://www.youtube.com/watch_popup?v=" .. playxlib.JSEscape(uri) .. '&enablejsapi=1&version=3&start=' .. start,
        center = false,
        volumeFunc = volumeFunc,
        playFunc = playFunc,
        pauseFunc = pauseFunc,

        js = [[
var checkReady = setInterval(function(){ if(document.readyState === "complete"){ playerReady(); clearInterval(checkReady);} }, 10);
var knownState = "Loading...";
var player = document.getElementsByTagName('embed')[0];

function sendPlayerData(data) {
    var str = "";
    for (var key in data) {
        str += encodeURIComponent(key) + "=" + encodeURIComponent(data[key]) + "&"
    }
    playx.processPlayerData(str);
}

function onError(err) {
  var msg;
  
  if (err == 2) {
    msg = "Error: Invalid media ID";
  } else if (err == 100) {
    msg = "Error: Media removed or now private";
  } else if (err == 101 || err = 150) {
    msg = "Error: Embedding not allowed";
    msg = "Buffering...";
  } else {
    msg = "Unknown error: " + err;
  }
  
  knownState = msg;  
  sendPlayerData({ State: msg });
}

function onPlayerStateChange(state) {
  var msg;
  
  if (state == -1) {
    msg = "Loading...";
  } else if (state == 0) {
    msg = "Playback complete.";
  } else if (state == 1) {
    msg = "Playing...";
  } else if (state == 2) {
    msg = "Paused.";
  } else if (state == 3) {
    msg = "Buffering...";
  } else {
    msg = "Unknown state: " + state;
  }
  
  knownState = msg;  
  sendPlayerData({ State: msg, Position: player.getCurrentTime(), Duration: player.getDuration() });
}

function updateState() {
  sendPlayerData({ Title: "test", State: knownState, Position: player.getCurrentTime(), Duration: player.getDuration() });
}

function playerReady() {  
  player.addEventListener('onError', 'onError');
  player.addEventListener('onStateChange', 'onPlayerStateChange');
  player.setVolume(]] .. volume .. [[);
  setInterval(updateState, 250);
}
]]}
end)