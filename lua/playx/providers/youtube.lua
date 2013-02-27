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

local apiKey = "AI39si79-V-ltHhNyYvyTeaiJeexopkZoiUA56Sk-W8Z5alYUkgntdwvkmu1" ..
               "avAWGNixM_DuLx8-Jai6qy1am7HhbhYvWERzWA"

local YouTube = {}

function YouTube.Detect(uri)    
    local m = playxlib.FindMatch(uri, {
        "^http://youtu%.be/([A-Za-z0-9_%-]+)",
        "^http://youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^http://[A-Za-z0-9%.%-]*%.youtube%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^http://[A-Za-z0-9%.%-]*%.youtube%.com/v/([A-Za-z0-9_%-]+)",
        "^http://youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
        "^http://[A-Za-z0-9%.%-]*%.youtube%-nocookie%.com/watch%?.*v=([A-Za-z0-9_%-]+)",
    })
    
    if m then
        return m[1]
    end
end

function YouTube.GetPlayer(uri, useJW)
    if uri:find("^[A-Za-z0-9_%-]+$") then
        if useJW then
            return {
                ["Handler"] = "YouTubePopup",
                ["URI"] = uri,
                ["ResumeSupported"] = true,
                ["LowFramerate"] = false,
                ["MetadataFunc"] = function(callback, failCallback)
                    YouTube.QueryMetadata(uri, callback, failCallback)
                end,
            }
        else
            local vars = {
                ["autoplay"] = "1",
                ["start"] = "__start__",
                ["rel"] = "0",
                ["hd"] = "0",
                ["showsearch"] = "0",
                ["showinfo"] = "0",
                ["enablejsapi"] = "1",
            }
            
            local url = Format("http://www.youtube.com/v/%s&%s&version=3&enablejsapi=1", uri, playxlib.URLEscapeTable(vars))
            
            return {
                ["Handler"] = "FlashAPI",
                ["URI"] = url,
                ["ResumeSupported"] = true,
                ["LowFramerate"] = false,
                ["MetadataFunc"] = function(callback, failCallback)
                    YouTube.QueryMetadata(uri, callback, failCallback)
                end,
                ["HandlerArgs"] = {
                    ["JSInitFunc"] = "onYouTubePlayerReady",
                    ["JSVolumeFunc"] = "setVolume",
                    ["StartMul"] = 1,
                },
            }
        end
    end
end

function YouTube.QueryMetadata(uri, callback, failCallback)
    local vars = playxlib.URLEscapeTable({
        ["alt"] = "atom",
        ["key"] = apiKey,
        ["client"] = game.SinglePlayer() and "SP" or ("MP:" .. GetConVar("hostname"):GetString()),
    })
    
    local url = Format("http://gdata.youtube.com/feeds/api/videos/%s?%s", uri, vars)

    http.Fetch(url, function(result, size)
        if size == 0 then
            failCallback("HTTP request failed (size = 0)")
            return
        end
        
        local title = playxlib.HTMLUnescape(string.match(result, "<title type='text'>([^<]+)</title>"))
        local desc = playxlib.HTMLUnescape(string.match(result, "<content type='text'>([^<]+)</content>"))
        local submitter = playxlib.HTMLUnescape(string.match(result, "<author><name>([^<]+)</name>"))
        
        local publishedDate = nil
        local y, mo, d, h, m, s = string.match(result, "<published>([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)%.000Z</published>")
        if y then
            publishedDate = playxlib.UTCTime({year=tonumber(y), month=tonumber(m),
                                           day=tonumber(d), hour=tonumber(h),
                                           min=tonumber(m), sec=tonumber(s)})
        end
        
        local modifiedDate = nil
        local y, mo, d, h, m, s = string.match(result, "<updated>([0-9]+)-([0-9]+)-([0-9]+)T([0-9]+):([0-9]+):([0-9]+)%.000Z</updated>")
        if y then
            modifiedDate = playxlib.UTCTime({year=tonumber(y), month=tonumber(mo),
                                          day=tonumber(d), hour=tonumber(h),
                                          min=tonumber(m), sec=tonumber(s)})
        end
        
        local length = tonumber(string.match(result, "<yt:duration seconds='([0-9]+)'"))
        local tags = playxlib.ParseTags(playxlib.HTMLUnescape(string.match(result, "<media:keywords>([^<]+)</media:keywords>")), ",")
        local thumbnail = playxlib.HTMLUnescape(string.match(result, "<media:thumbnail url='([^']+)' height='360' width='480' time='[^']+'/>"))
        local comments = tonumber(string.match(result, "<gd:comments><gd:feedLink href='[^']+' countHint='([0-9]+)'/>"))
        
        local faves, views = string.match(result, "<yt:statistics favoriteCount='([0-9]+)' viewCount='([0-9]+)'/>")
        faves, views = tonumber(faves), tonumber(views)
        
        local rating, numRaters = string.match(result, "<gd:rating average='([0-9%.]+)'[^R]+numRaters='([0-9]+)'")
        rating, numRaters = tonumber(rating), tonumber(numRaters)
        if rating then rating = rating / 5.0 end
        
        if length then
            callback({
                ["URL"] = "http://www.youtube.com/watch?v=" .. uri,
                ["Title"] = title,
                ["Description"] = desc,
                ["Length"] = length,
                ["Tags"] = tags,
                ["DatePublished"] = publishedDate,
                ["DateModified"] = modifiedDate,
                ["Submitter"] = submitter,
                ["SubmitterURL"] = submitter and "http://www.youtube.com/" .. submitter or nil,
                ["NumFaves"] = faves,
                ["NumViews"] = views,
                ["NumComments"] = comments,
                ["RatingNorm"] = rating,
                ["NumRatings"] = numRaters,
                ["Thumbnail"] = thumbnail,
            })
        else
            callback({
                ["URL"] = "http://www.youtube.com/watch?v=" .. uri,
            })
        end
    end)
end

list.Set("PlayXProviders", "YouTube", YouTube)
list.Set("PlayXProvidersList", "YouTube", {"YouTube"})