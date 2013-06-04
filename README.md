boombox
=======

A HTML5 web music library with a Sinatra backend. Works like a proper native application.

Note: waveform requires SoX installed.


## Setup

Put your music files, folders and cover art (mp3) into `public/music`, then open the `/reset` URL in your browser.


## TODO

* Wire up the volume bar plugin into the new volume bar design.
* Wire up shuffle and loop.
* Make a blue-ish hue glow for the header buttons.
* Fix tabs, so that events work when we switch pages back and forth.
* Fix up the coffeescript to follow a certain pattern -- make it actually make sense...

* Login system via Warden, later support for multiple users.

* Get view icons from fontello and figure out where to put them on the UI.
* Cover art view (thumbnail view), incorporate [this tutorial](http://tympanus.net/Tutorials/ThumbnailGridExpandingPreview/), where the preview would be a tracklist.
* Cover flow view

* AJAX-ify the tables and/or figure out a way to make it work with huuuuge filelists.

* Rewrite tagger. Support embedded cover art. Cache cover art. Use GridFS maybe?

* Make a mobile version, swipable tabs?

* CSS Animations, effects, eyecandy! :3 Port CSS3 cover art effects from Redbird.

v2

* (enable streaming via. MPD?)
* Playlists
* Support for [AAC](https://github.com/audiocogs/aac.js), [FLAC](https://github.com/audiocogs/flac.js), [ALAC](https://github.com/audiocogs/alac.js). Is ogg supported? 
* Funky waveforms in canvas via the new audio API's by FF and Chrome.