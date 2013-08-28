boombox
=======

A HTML5 web music library with a Sinatra backend. Works like a proper native application.

Note: waveform requires SoX installed.


## Setup

1. Put your music files, folders and cover art (mp3) into `public/music`.
2. Create a new user account by running `ruby script/new_account`.
3. Run the server and log in.
4. Open the `/reset` URL in your browser to force boombox to scan the music dir.


## TODO

* ~(Add a .volume-bar-total to limit the volume bar handle to an inner margin (narrows the bar with a padding of half the volume handle width)? right now it spans too much.
* Fix scrollbar on table.
* FF: event binding doesn't work -- the play/pause button doesn't update and the player page doesn't work.
* Fix DOM memory leaks that happen when we change the page and don't empty out the container. (use .empty()!)
* Now playing icon (small speaker) needs to be reapplied on the listing mode.
* Wire up the settings icon and make it pop down a menu (logout, options, invite)
* Invite new users via mail system
* Cover art view (thumbnail view), incorporate [this tutorial](http://tympanus.net/Tutorials/ThumbnailGridExpandingPreview/), where the preview would be a tracklist.
* Cover flow view (add the icon to the view switcher!)
* Store the preferences (view, shuffle/loop) in the user session and/or user's DB model.
* AJAX-ify the tables and/or figure out a way to make it work with huuuuge filelists.
* Rewrite tagger. Support embedded cover art. Cache cover art. Use GridFS maybe?
* Make a mobile version, swipable tabs?
* CSS Animations, effects, eyecandy! :3
* ~~Restyle buttons.~~ Pick a general color scheme and restyle again.
* Use a tabular layout (or ANYTHING saner) for the multi edit form.
* Some songs, like LATENYC #1 and #2 are actually longer in time than what the player shows.
* Extend models to feature Artist and Album models (albums are separate unless artist or albumartist or the sort field matches!)

v2

* (enable streaming via. MPD?)
* Playlists
* Rating system
* Match up songs that go great together
* Wire up shuffle and loop. (after we have playlists)
* Support for [AAC](https://github.com/audiocogs/aac.js), [FLAC](https://github.com/audiocogs/flac.js), [ALAC](https://github.com/audiocogs/alac.js). Is ogg supported?
* Funky waveforms in canvas via the new audio API's by FF and Chrome.
