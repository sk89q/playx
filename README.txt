PlayX
Copyright (c) 2009 sk89q <http://www.sk89q.com>
Licensed under the GNU General Public License v2

Introduction
------------

PlayX is a versatile media player for Gmod that is capable of playing
several different types of media, ranging from YouTube videos to images.

Features:
- YouTube videos, Livestream channels, Flash movies, MP3, FLV, MP4,
  and AAC files, images, and Vimeo videos can be played
  - Select a particular provider, or let PlayX automatically detect that
    information from the URL
  - PlayX can be extended to play videos from other providers
  - YouTube videos can be played in a custom player that contains no
    pesky advertisements, and also likewise, no annotations and captions
    - The custom media player can be disabled on a case-by-case basis
  - Certain types of media (music files and images) are automatically put
    into a low frame rate mode that tells clients to render the video
    at 1 FPS, to prevent unnecessary reduce frame rate drop
    - Any piece of media can be forced into low frame rate mode
  - Flash movies will be "forced play" so that they can be played in the
    player even if you would normally have to press a "Play" button
- The screen can be drawn on a prop or projected from a projector model
  - Available non-projector props are Counter-Strike: Source screens, and
    one projector is from CS:S
  - Another projector is the Gmod camera model, so anyone can watch the
    video with no needed addons or games
  - Any model can be used for the player even if the screen coordinates
    are not explicitly defined, although support varies, and it best works
    on (some) PHX plate models
  - The projector screen is the same size as the projector screens in
    IamMcLovin's YouTube player, allowing for easy replacement of the
    projector in an adv. dupe file
- Videos can be resumed (support varies between providers)
  - Users can hide the player (where resume is supported), and restart the
    player, resuming the video from where it 'would be' for everyone else
  - Users who join after the video start can see the video from the point
    where it would be for everyone else
  - Videos can be started at a certain point in the video other than the
    beginning
  - Should the server clear of administrators, the player will
    automatically stop the video after a delay to prevent the video from
    continuing to load for everyone that joins
- The currently playing media can be ended prematurely
  - The video can be automatically stopped when it ends if it is a
    YouTube video
    - Configurable grace period after the video ends so that users who may
      have had short buffering issues can still enjoy the video until the
      end
    - This feature can be disabled completely, or disabled on a
      video-by-video basis
- Clients can adjust the frame rate of the screen as well as the
  volume of the video (support varies between providers)
  - The player can be disabled altogether by a client, and the setting will
    persist between sessions
    - If the player is disabled, the user will see a message on the screen
      reminding the user on how to re-enable the player
    - When a video is started, and the user has the player disabled, a
      notice will be printed to their chat reminding them that they have
      the player disabled
- Protection against Gmod freezes (where you hear a click and water sound
  upon returning to Gmod) that will keep the video continuing to play
  - If the projector screen starts to appear only if the projector prop
    is in view, a button on the PlayX settings tool menu panel will correct
    that issue
- PlayX is extensible
  - More providers can be added to PlayX
  - PlayX contains both client-side and server-side APIs
  - By default, PlayX checks whether you are an administrator on the
    server before giving access, but this can be overrided with a custom
    authorization routine

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
- MP3*: auto-detect, resume / seek (not really), volume control
- FLV*: auto-detect, volume control
- MP4*: auto-detect, volume control
- AAC*: auto-detect, volume control
- Image: auto-detect, resume, volume N/A, length N/A
- Livestream: auto-detect, resume, volume control, length N/A
- Vimeo: auto-detect, volume control

* Requires that the playx_jw_url cvar be pointed to a valid URL of a
  hosted copy of the JW Player.

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
