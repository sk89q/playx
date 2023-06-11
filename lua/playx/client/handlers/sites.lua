-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2011 - 2023 DathusBR <https://www.juliocesar.me>
-- 
-- This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
-- To view a copy of this license, visit Common Creative's Website. <https://creativecommons.org/licenses/by-nc-sa/4.0/>
-- 
-- $Id$
-- Version 2.9.6 by Dathus [BR] on 2023-06-11 4:54 PM (-03:00 GMT)

list.Set("PlayXHandlers", "Vimeo", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateVimeoEmbed(width, height, start, volume, uri, "vimeo")
end)

-- Initial soundcloud handler by Xerasin, I fixed and make it better for my PlayX version.
list.Set("PlayXHandlers", "SoundCloud", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateSoundcloudEmbed(width, height, start*1000, volume, uri, "soundcloud")
end)

list.Set("PlayXHandlers", "Livestream", function(width, height, start, volume, uri, handlerArgs)
    return playxlib.GenerateLivestreamEmbed(width, height, start, volume, uri, "livestream")
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