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

* ~~Wire up the volume bar plugin into the new volume bar design.~~(Add a .volume-bar-total to limit the handle to an inner margin (narrows the bar with a padding of half the volume handle width)? right now it spans too much.
* ~~Make a blue-ish hue glow for the header buttons.~~
* ~~Fix tabs, so that events work when we switch pages back and forth.~~
* ~~Fix up the coffeescript to follow a certain pattern -- make it actually make sense~~...

* Fix scrollbar on table.

* FF: event binding doesn't work -- the play/pause button doesn't update and the player page doesn't work.
* Cover art doesn't update on the player page.
* Now playing icon (small speaker) needs to be reapplied on the listing mode.

* ~~Login system via Warden, later support for multiple users.~~
* Add a logout button on the UI.
* Invite new users via mail system
* ~~Import Roboto into the project.~~

* ~~Get view icons from fontello and figure out where to put them on the UI.~~
* Cover art view (thumbnail view), incorporate [this tutorial](http://tympanus.net/Tutorials/ThumbnailGridExpandingPreview/), where the preview would be a tracklist.
* Cover flow view (add the icon to the view switcher!)
* Store the preferences (view, shuffle/loop) in the user session and/or user's DB model.

* AJAX-ify the tables and/or figure out a way to make it work with huuuuge filelists.
* Rewrite tagger. Support embedded cover art. Cache cover art. Use GridFS maybe?
* Make a mobile version, swipable tabs?
* CSS Animations, effects, eyecandy! :3 ~~Port CSS3 cover art effects from Redbird.~~
* Restyle buttons.

* Some songs, like LATENYC #1 and #2 
* Extend models to feature Artist and Album models (albums are separate unless artist or albumartist or the sort field matches!)

v2

* (enable streaming via. MPD?)
* Playlists
* Rating system
* Match up songs that go great together
* Wire up shuffle and loop. (after we have playlists)
* Support for [AAC](https://github.com/audiocogs/aac.js), [FLAC](https://github.com/audiocogs/flac.js), [ALAC](https://github.com/audiocogs/alac.js). Is ogg supported?
* Funky waveforms in canvas via the new audio API's by FF and Chrome.
