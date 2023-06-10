-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.9.2 by Dathus [BR] on 2023-06-10 4:26 PM (-03:00 GMT)

list.Set("PlayXHandlers", "Vimeo", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateVimeoEmbed(width, height, start, volume, uri, "vimeo")
end)

list.Set("PlayXHandlers", "Livestream", function(width, height, start, volume, uri, handlerArgs)
    local volumeFunc = function(volume)
        return [[
        	try {
        		document.lsplayer.setVolume(]] .. playxlib.volumeFloat(volume) .. [[);
        	} catch (e) {}
        ]]
    end
    
    local playFunc = function(volume)
        return [[
        	try {
	        	document.lsplayer.setPlay();
	        	document.getElementById("lsplayer").style.width='100%';
			} catch (e) {}
      	]]
    end
    
    local pauseFunc = function(volume)
        return [[
        	try {
        		document.lsplayer.setPause();
        		document.getElementById("lsplayer").style.width='1px';
        	} catch (e) {}
        ]]
    end
	    
    return playxlib.HandlerResult{
        url = playxlib.JSEscape(uri),
        center = false,
        volumeFunc = volumeFunc,
        playFunc = playFunc,
        pauseFunc = pauseFunc,

        js = [[	        			      
			try {
				var checkReady = setInterval(function(){ if(document.readyState === "complete"){ playerReady(); clearInterval(checkReady);} }, 10);
			} catch (e) {}
			
			function sendPlayerData(data) {
			    var str = "";
			    for (var key in data) {
			        str += encodeURIComponent(key) + "=" + encodeURIComponent(data[key]) + "&"
			    }
			    playx.processPlayerData(str);
			}
			
			function livestreamPlayerCallback(event) {
			  var msg;
			  
			  if (event == 'chromelessPlayerLoadedEvent') {
			    msg = "LOADING";
			  } else if (event == 'playbackCompleteEvent') {
			    msg = "COMPLETED";
			  } else if (event == 'playbackEvent') {
			    msg = "PLAYING";
			  } else if (event == 'pauseEvent') {
			    msg = "PAUSED";
			  } else if (event == 'connectionEvent') {
			    msg = "BUFFERING";
			  }else{
			  	msg = "..."
			  }
			  
			  sendPlayerData({ State: msg, Position: document.lsplayer.getTime(), Duration: document.lsplayer.getDuration() });
			}
			
			function updateState() {
			  sendPlayerData({Title: document.lsplayer.getCurrentContentTitle(), Position: document.lsplayer.getTime(), Duration: document.lsplayer.getDuration() });
			}
			
			function playerReady() {  
			  try {
				  document.lsplayer.setVolume(]] .. playxlib.volumeFloat(volume) .. [[);
				  setInterval(updateState, 250);
			  } catch (e) {}
			}
	]]}
end)

-- Initial soundcloud handler by Xerasin, I fixed and make it better for my PlayX version.

list.Set("PlayXHandlers", "SoundCloud", function(width, height, start, volume, uri, handlerArgs)
  if start > 2 then
    start = start + 4 -- Lets account for buffer time...
  end
  
  local volumeFunc = function(volume)
    return "SC.Widget(document.querySelector('iframe')).setVolume("..tostring(volume)..");"
  end
  
  local playFunc = function()
    return "SC.Widget(document.querySelector('iframe')).play();"
  end
  
  local pauseFunc = function()
    return "SC.Widget(document.querySelector('iframe')).pause();"
  end
  
  return playxlib.HandlerResult{
    url =  playxlib.JSEscape(GetConVarString("playx_soundcloud_host_url"):Trim() .. "?url="..uri.."&t="..tostring(start*1000).."&vol="..tostring(volume)),
    volumeFunc = volumeFunc,
    playFunc = playFunc,
    pauseFunc = pauseFunc
  }
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