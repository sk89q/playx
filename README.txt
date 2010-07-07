PlayX
Copyright (c) 2009-2010 sk89q <http://www.sk89q.com>
Licensed under the GNU General Public License v2
http://github.com/sk89q/playx

Introduction
------------

PlayX is a versatile media player for Gmod that is capable of playing
several different types of media, ranging from YouTube videos to images.
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

Usage
-----

PlayX can be used from the tool menu, under the "Options" tab.

Please see http://wiki.github.com/sk89q/playx/usage for more detailed information.

Server Cvars
------------

string playx_jw_url (def. "http://playx.googlecode.com/svn/jwplayer/player.swf")
    The JW Player URL. Required for a lot of functionality.

bool playx_host_url (def. "http://sk89q.github.com/playx/host/host.html")
    Required file for PlayX to work. You need to point this to the host.html
    file provided with PlayX.

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

bool playx_race_protection (def. "1")
    Enable media play race condition handling.

bool playx_wire_input (def. "0")
    Set to 1 to allow Wiremod input.

bool playx_wire_input_delay (def. "2")
    Delay between opening media with Wiremod input.
