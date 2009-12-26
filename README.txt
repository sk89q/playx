PlayX
Copyright (c) 2009 sk89q <http://www.sk89q.com>
Licensed under the GNU Lesser General Public License v2

Introduction
------------

PlayX is a versatile media player for Gmod that is capable of playing
several different types of media, ranging from YouTube videos to images.

Features:
- Play YouTube videos, Livestream channels, Flash movies, MP3, FLV, MP4,
  and AAC files, images, and Vimeo videos
- Auto-detection of type of media
- Video resuming support (support varies; see list below)
- Video resuming for players who joined after the video started
  (support varies; see list below)
- Automatic video length detection for YouTube videos will stop rendering
  of videos when finished
- Automatic end of the video after a delay when all administrators have
  left the server.
- Ability to begin the media at a point other than the beginning
  (support varies; see list below)
- Client-side video restarting support with resume (support varies; see
  list below)
- Server-side video stop support
- Client side enabling and disabling of the player
- Adjustable FPS of player
- Adjustable volume of player (support varies; see list below)
- Ad-less player for YouTube (requires JW player; discussed below)
- For non-animated media (static images, music files), a low frame rate
  mode is automatically activated to significantly reduce frame rate drop
- Low frame rate mode can be forced for any media
- Contains a projector mode, with a model that does not require CS:S
- Projector screen is the same size as the screen of IamMcLovin's YouTube 
  player
- Notice printed on screen on how to re-enable the player, should the
  user disable the player
- Message printed to chat whenever a video is played, should the user
  disable the player
- Protection against Gmod freezes (you hear a click and water sound upon
  returning to Gmod), so that the video continues playing
- Can be easily extended with more video providers
- By default, administrator only, but can be extended to allow access on
  different criteria
- Client-side and server-side APIs

A lot of the functionality available requires that you have an installation
of the JW Player (http://www.longtailvideo.com/) somewhere, and that you
have set the value of the playx_jw_url cvar to the URL of the player.

Server Cvars
------------

string playx_jw_url (def. "http://playx.googlecode.com/svn/jwplayer/player.swf")
    The JW Player URL. Required for a lot of functionality.

bool playx_jw_youtube (def. "1")
    Flag to mark whether to use the JW Player for YouTube videos. In
    addition to hosting the JW player, you also need to host the "yt.swf"
    file that comes with the JW player for YouTube play to work.
    
    Using the JW Player for YouTube will result in no ads, and also no
    annotations and no captions. You can disable use of the JW player
    client-side via a checkbox when starting a video.

number playx_admin_timeout (def. "120")
    The delay after all administrators have left the server before 
    automatically stopping the playing media. This is defined in seconds.
    Use "0" to disable this feature.

number playx_expire (def. "10")
    The grace period after a video ends before stopping the video. Set to
    "-1" to disable this feature. Defined in seconds.

Support
-------

- YouTube: auto-detect, resume / seek, volume control, length detection
- Flash: auto-detect
- MP3: auto-detect, resume / seek (not really)
- FLV: auto-detect
- MP4: auto-detect
- AAC: auto-detect
- image: auto-detect, resume, volume N/A, length N/A
- Livestream: auto-detect, resume, volume control, length N/A
- Vimeo: auto-detect, volume control

Providers
---------

Providers are registered in the PlayX.Providers table. See
playx/providers.lua to see the format of providers. The client-side
list of providers can also be changed, although you would have to either
modify PlayX directly, or download another Lua file. The client-side list
of providers is found in playx/client/providers.lua.

Handlers
--------

Handlers are a client-side construct. They are the actual players. They
generate HTML for the web browser control in order to play a piece of
media.

There is not a 1:1 relationship between providers and handlers. Many 
different providers can be played using an already-implemented handler.
Handlers are defined in playx/client/providers.lua.

Hooks
-----

To override authorization, define a global function named
PlayXIsPermittedHook that takes in one argument, a Player. Have it return
true to permit access, and false to deny access.

API
---

See API.txt for more information.

There is an example usage of the API in the contrib/ folder.
