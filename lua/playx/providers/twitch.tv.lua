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
-- Version 2.7.7 by Nexus [BR] on 10-07-2013 10:00 AM

local TwitchTV = {}

function TwitchTV.Detect(uri, useJW)
    local m = playxlib.FindMatch(uri:gsub("%?.*$", ""), {
        "twitch%.tv/([A-Za-z0-9%.%-%_]+)"
    })
    
    if m then
        return uri
    end
end

function TwitchTV.GetPlayer(url, useJW)
	local channelID = "";
	local chapterID = 0;
	local fullURL = "";
	
	local uri = playxlib.FindMatch(url:gsub("%?.*$", ""), {
        "twitch%.tv/([A-Za-z0-9%.%-%_]+)"
    })   
    
    if uri ~= "" then     
		if uri[1] ~= nil then
			channelID = uri[1];
			uri = uri[1]
			if string.find(url, "/c/") then
				chapterID = url:split("/c/");
				chapterID = chapterID[2]
				fullURL = "http://www.twitch.tv/"..channelID.."/c/"..chapterID;
			else
				fullURL = "http://www.twitch.tv/"..channelID;
			end	
		end	
	    
	    if uri:lower():find("^[a-zA-Z0-9_]+$") then        
	        return {
	            ["Handler"] = "twitch.tv",
	            ["URI"] =  GetConVarString("playx_host_url"),
	            ["ResumeSupported"] = true,
	            ["LowFramerate"] = false,
	            ["MetadataFunc"] = function(callback, failCallback)
	                TwitchTV.QueryMetadata(fullURL, callback, failCallback)
	            end,
	            ["HandlerArgs"] = {
	                ["VolumeMul"] = 50,
	                ["ChannelID"] = channelID,
	                ["ChapterID"] = chapterID           
	            },
	        }
	    end
    end
end

function TwitchTV.QueryMetadata(url, callback, failCallback)
	   callback({
        ["URL"] = url,
    })
end

list.Set("PlayXProviders", "twitch.tv", TwitchTV)
list.Set("PlayXProvidersList", "twitch.tv", {"twitch.tv"})