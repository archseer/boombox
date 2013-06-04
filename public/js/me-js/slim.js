/*!
 * A slim version of the mediaelementplayer.js, where the
 * audio portion is extracted and lots of unneeded features
 * were trashed.
 *
 */
if (typeof jQuery != 'undefined') {
  mejs.$ = jQuery;
} else if (typeof ender != 'undefined') {
  mejs.$ = ender;
}
(function ($) {
  // default player values
  mejs.MepDefaults = {
    // default if the user doesn't specify
    defaultWidth: 400,
    // default if the user doesn't specify
    defaultHeight: 30,

    // default amount to move back when back key is pressed
    defaultSeekBackwardInterval: function(media) {
      return (media.duration * 0.05);
    },
    // default amount to move forward when forward key is pressed
    defaultSeekForwardInterval: function(media) {
      return (media.duration * 0.05);
    },

    // width of audio player
    width: -1,
    // height of audio player
    height: -1,
    // initial volume when the player starts (overrided by user cookie)
    startVolume: 0.8,
    // useful for <audio> player loops
    loop: false,
    // forces the hour marker (##:00:00)
    alwaysShowHours: false,

    // automatically calculate the width of the progress bar based on the sizes of other elements
    autosizeProgress : true,

    // features to show
    features: ['current','duration','progress','volume'],

    // turns keyboard support on and off for this instance
    enableKeyboard: true,

    // whenthis player starts, it will pause other players
    pauseOtherPlayers: true,

    // array of keyboard actions such as play pause
    keyActions: [
        {
          keys: [
            32, // SPACE
            179 // GOOGLE play/pause button
            ],
          action: function(player, media) {
            if (media.paused || media.ended) {
              media.play();
            } else {
              media.pause();
            }
          }
        },
        {
          keys: [38], // UP
          action: function(player, media) {
            var newVolume = Math.min(media.volume + 0.1, 1);
            media.setVolume(newVolume);
          }
        },
        {
          keys: [40], // DOWN
          action: function(player, media) {
            var newVolume = Math.max(media.volume - 0.1, 0);
            media.setVolume(newVolume);
          }
        },
        {
          keys: [
            37, // LEFT
            227 // Google TV rewind
          ],
          action: function(player, media) {
            if (!isNaN(media.duration) && media.duration > 0) {
              // 5%
              var newTime = Math.max(media.currentTime - player.options.defaultSeekBackwardInterval(media), 0);
              media.setCurrentTime(newTime);
            }
          }
        },
        {
          keys: [
            39, // RIGHT
            228 // Google TV forward
          ],
          action: function(player, media) {
            if (!isNaN(media.duration) && media.duration > 0) {
              // 5%
              var newTime = Math.min(media.currentTime + player.options.defaultSeekForwardInterval(media), media.duration);
              media.setCurrentTime(newTime);
            }
          }
        }
    ]
  };

  mejs.mepIndex = 0;

  mejs.players = [];

  // wraps a MediaElement object in player controls
  mejs.MediaElementPlayer = function(node, o) {
    // enforce object, even without "new" (via John Resig)
    if ( !(this instanceof mejs.MediaElementPlayer) ) {
      return new mejs.MediaElementPlayer(node, o);
    }

    var t = this;

    // these will be reset after the MediaElement.success fires
    t.$media = t.$node = $(node);
    t.node = t.media = t.$media[0];

    // check for existing player
    if (typeof t.node.player != 'undefined') {
      return t.node.player;
    } else {
      // attach player to DOM node for reference
      t.node.player = t;
    }

    // try to get options from data-mejsoptions
    if (typeof o == 'undefined') {
      o = t.$node.data('mejsoptions');
    }

    // extend default options
    t.options = $.extend({},mejs.MepDefaults,o);

    // add to player array (for focus events)
    mejs.players.push(t);

    // start up
    t.init();

    return t;
  };

  // actual player
  mejs.MediaElementPlayer.prototype = {
    hasFocus: false,

    init: function() {

      var
        t = this,
        mf = mejs.MediaFeatures,
        // options for MediaElement (shim)
        meOptions = $.extend(true, {}, t.options, {
          success: function(media, domNode) { t.meReady(media, domNode); },
          error: function(e) { t.handleError(e);}
        });

      // remove native controls
      t.$media.removeAttr('controls');

      // unique ID
      t.id = 'mep_' + mejs.mepIndex++;

      // build container
      t.container =
        $('<div id="' + t.id + '" class="mejs-container">'+
          '<div class="mejs-inner">'+
            '<div class="mejs-mediaelement"></div>'+
            '<div class="mejs-controls"></div>'+
            '<div class="mejs-clear"></div>'+
          '</div>' +
        '</div>')
        .addClass(t.$media[0].className)
        .insertBefore(t.$media);

      // add classes for user and content
      t.container.addClass(
        (mf.isAndroid ? 'mejs-android ' : '') +
        (mf.isiOS ? 'mejs-ios ' : '') +
        (mf.isiPad ? 'mejs-ipad ' : '') +
        (mf.isiPhone ? 'mejs-iphone ' : '') +
        'mejs-audio '
      );

      // move the <video/video> tag into the right spot
      if (mf.isiOS) {

        // sadly, you can't move nodes in iOS, so we have to destroy and recreate it!
        var $newMedia = t.$media.clone();

        t.container.find('.mejs-mediaelement').append($newMedia);

        t.$media.remove();
        t.$node = t.$media = $newMedia;
        t.node = t.media = $newMedia[0]

      } else {

        // normal way of moving it into place (doesn't work on iOS)
        t.container.find('.mejs-mediaelement').append(t.$media);
      }

      // find parts
      t.controls = t.container.find('.mejs-controls');

      // determine the size

      /* size priority:
        (1) audioWidth (forced),
        (2) style="width;height;"
        (3) width attribute,
        (4) defaultWidth (for unspecified cases)
      */

      if (t.options['width'] > 0 || t.options['width'].toString().indexOf('%') > -1) {
        t.width = t.options['width'];
      } else if (t.media.style.width !== '' && t.media.style.width !== null) {
        t.width = t.media.style.width;
      } else if (t.media.getAttribute('width') !== null) {
        t.width = t.$media.attr('width');
      } else {
        t.width = t.options['defaultWidth'];
      }

      if (t.options['height'] > 0 || t.options['height'].toString().indexOf('%') > -1) {
        t.height = t.options['height'];
      } else if (t.media.style.height !== '' && t.media.style.height !== null) {
        t.height = t.media.style.height;
      } else if (t.$media[0].getAttribute('height') !== null) {
        t.height = t.$media.attr('height');
      } else {
        t.height = t.options['defaultHeight'];
      }

      // set the size, while we wait for the plugins to load below
      t.setPlayerSize(t.width, t.height);

      // create MediaElementShim
      meOptions.pluginWidth = t.height;
      meOptions.pluginHeight = t.width;


      // create MediaElement shim
      mejs.MediaElement(t.$media[0], meOptions);
    },

    // Sets up all controls and events
    meReady: function(media, domNode) {
      var t = this,
        autoplayAttr = domNode.getAttribute('autoplay'),
        autoplay = !(typeof autoplayAttr == 'undefined' || autoplayAttr === null || autoplayAttr === 'false'),
        featureIndex,
        feature;

      // make sure it can't create itself again if a plugin reloads
      if (t.created)
        return;
      else
        t.created = true;

      t.media = media;
      t.domNode = domNode;

      // add user-defined features/controls
      for (featureIndex in t.options.features) {
        feature = t.options.features[featureIndex];
        if (t['build' + feature]) {
          try {
            t['build' + feature](t, t.controls, t.media);
          } catch (e) {
            // TODO: report control error
            //throw e;
            //console.log('error building ' + feature);
            //console.log(e);
          }
        }
      }

      t.container.trigger('controlsready');

      // reset all layers and controls
      t.setPlayerSize(t.width, t.height);
      t.setControlsSize();

      // EVENTS

      // FOCUS: when a video starts playing, it takes focus from other players (possibily pausing them)
      media.addEventListener('play', function() {
          // go through all other players
          for (var i=0, il=mejs.players.length; i<il; i++) {
            var p = mejs.players[i];
            if (p.id != t.id && t.options.pauseOtherPlayers && !p.paused && !p.ended) {
              p.pause();
            }
            p.hasFocus = false;
          }

          t.hasFocus = true;
      },false);

      // ended for all
      t.media.addEventListener('ended', function (e) {
        try{
          t.media.setCurrentTime(0);
        } catch (exp) {

        }
        t.media.pause();

        if (t.setProgressRail)
          t.setProgressRail();
        if (t.setCurrentRail)
          t.setCurrentRail();

        if (t.options.loop) {
          t.media.play();
        }
      }, false);

      // resize on the first play
      t.media.addEventListener('loadedmetadata', function(e) {
        if (t.updateDuration) {
          t.updateDuration();
        }
        if (t.updateCurrent) {
          t.updateCurrent();
        }

        t.setPlayerSize(t.width, t.height);
        t.setControlsSize();
      }, false);


      // webkit has trouble doing this without a delay
      setTimeout(function () {
        t.setPlayerSize(t.width, t.height);
        t.setControlsSize();
      }, 50);

      // adjust controls whenever window resizes
      $(window).resize(function() {
        t.setPlayerSize(t.width, t.height);
        t.setControlsSize();
      });

      // force autoplay for HTML5
      if (autoplay && media.pluginType == 'native') {
        media.load();
        media.play();
      }

      if (t.options.success) {
        if (typeof t.options.success == 'string') {
          window[t.options.success](t.media, t.domNode, t);
        } else {
          t.options.success(t.media, t.domNode, t);
        }
      }
    },

    handleError: function(e) {
      var t = this;

      t.controls.hide();

      // Tell user that the file cannot be played
      if (t.options.error) {
        t.options.error(e);
      }
    },

    setPlayerSize: function(width,height) {
      var t = this;

      if (typeof width != 'undefined')
        t.width = width;

      if (typeof height != 'undefined')
        t.height = height;

      // detect 100% mode - use currentStyle for IE since css() doesn't return percentages
      if (t.height.toString().indexOf('%') > 0 || t.$node.css('max-width') === '100%' || (t.$node[0].currentStyle && t.$node[0].currentStyle.maxWidth === '100%')) {

        // do we have the native dimensions yet?
        var
          parentWidth = t.container.parent().closest(':visible').width(),
          newHeight = parseInt(parentWidth * t.options.defaultAudioHeight/t.options.defaultAudioWidth, 10);

        if (t.container.parent()[0].tagName.toLowerCase() === 'body') { // && t.container.siblings().count == 0) {
          parentWidth = $(window).width();
          newHeight = $(window).height();
        }

        if ( newHeight != 0 ) {
          // set outer container size
          t.container
            .width(parentWidth)
            .height(newHeight);

          // set native <audio>
          t.$media
            .width('100%')
            .height('100%');
        }

      } else {

        t.container
          .width(t.width)
          .height(t.height);
      }
    },

    setControlsSize: function() {
      var t = this,
        usedWidth = 0,
        railWidth = 0,
        rail = t.controls.find('.mejs-time-rail'),
        total = t.controls.find('.mejs-time-total'),
        current = t.controls.find('.mejs-time-current'),
        loaded = t.controls.find('.mejs-time-loaded'),
        others = rail.siblings();

      // allow the size to come from custom CSS
      if (t.options && !t.options.autosizeProgress) {
        // Also, frontends devs can be more flexible
        // due the opportunity of absolute positioning.
        railWidth = parseInt(rail.css('width'));
      }

      // attempt to autosize
      if (railWidth === 0 || !railWidth) {

        // find the size of all the other controls besides the rail
        others.each(function() {
          if ($(this).css('position') != 'absolute') {
            usedWidth += $(this).outerWidth(true);
          }
        });

        // fit the rail into the remaining space
        railWidth = t.controls.width() - usedWidth - (rail.outerWidth(true) - rail.width());
      }

      // outer area
      rail.width(railWidth);
      // dark space
      total.width(railWidth - (total.outerWidth(true) - total.width()));

      if (t.setProgressRail)
        t.setProgressRail();
      if (t.setCurrentRail)
        t.setCurrentRail();
    },

    buildkeyboard: function(player, controls, media) {
        var t = this;

        // listen for key presses
        $(document).keydown(function(e) {

            if (player.hasFocus && player.options.enableKeyboard) {

              // find a matching key
              for (var i=0, il=player.options.keyActions.length; i<il; i++) {
                var keyAction = player.options.keyActions[i];

                for (var j=0, jl=keyAction.keys.length; j<jl; j++) {
                  if (e.keyCode == keyAction.keys[j]) {
                    e.preventDefault();
                    keyAction.action(player, media, e.keyCode);
                    return false;
                  }
                }
              }
            }

            return true;
        });

        // check if someone clicked outside a player region, then kill its focus
        $(document).click(function(event) {
            if ($(event.target).closest('.mejs-container').length == 0) {
              player.hasFocus = false;
            }
        });

    },

    play: function() {
      this.media.play();
    },
    pause: function() {
      this.media.pause();
    },
    load: function() {
      this.media.load();
    },
    setMuted: function(muted) {
      this.media.setMuted(muted);
    },
    setCurrentTime: function(time) {
      this.media.setCurrentTime(time);
    },
    getCurrentTime: function() {
      return this.media.currentTime;
    },
    setVolume: function(volume) {
      this.media.setVolume(volume);
    },
    getVolume: function() {
      return this.media.volume;
    },
    setSrc: function(src) {
      this.media.setSrc(src);
    },
    remove: function() {
      var t = this;

      if (t.media.pluginType === 'flash') {
        t.media.remove();
      } else if (t.media.pluginType === 'native') {
        t.$media.prop('controls', true);
      }

      t.container.remove();
    }
  };

  // turn into jQuery plugin
  if (typeof jQuery != 'undefined') {
    jQuery.fn.mediaelementplayer = function (options) {
      return this.each(function () {
        new mejs.MediaElementPlayer(this, options);
      });
    };
  }

  $(document).ready(function() {
    // auto enable using JSON attribute
    $('.mejs-player').mediaelementplayer();
  });

  // push out to window
  window.MediaElementPlayer = mejs.MediaElementPlayer;

})(mejs.$);

(function($) {

  $.extend(mejs.MepDefaults, {
    stopText: 'Stop'
  });

  // STOP BUTTON
  $.extend(MediaElementPlayer.prototype, {
    buildstop: function(player, controls, media) {
      var t = this,
        stop =
        $('<div class="mejs-button mejs-stop-button mejs-stop">' +
          '<button type="button" aria-controls="' + t.id + '" title="' + t.options.stopText + '"></button>' +
        '</div>')
        .appendTo(controls)
        .click(function() {
          if (!media.paused) {
            media.pause();
          }
          if (media.currentTime > 0) {
            media.setCurrentTime(0);
            media.pause();
            controls.find('.mejs-time-current').width('0px');
            controls.find('.mejs-time-handle').css('left', '0px');
            controls.find('.mejs-time-float-current').html( mejs.Utility.secondsToTimeCode(0) );
            controls.find('.mejs-currenttime').html( mejs.Utility.secondsToTimeCode(0) );
          }
        });
    }
  });

})(mejs.$);
(function($) {
  // progress/loaded bar
  $.extend(MediaElementPlayer.prototype, {
    buildprogress: function(player, controls, media) {

      $('<div class="mejs-time-rail">'+
        '<span class="mejs-time-total">'+
          '<span class="mejs-time-loaded"></span>'+
          '<span class="mejs-time-current"></span>'+
          '<span class="mejs-time-handle"></span>'+
          '<span class="mejs-time-float">' +
            '<span class="mejs-time-float-current">00:00</span>' +
            '<span class="mejs-time-float-corner"></span>' +
          '</span>'+
        '</span>'+
      '</div>')
        .appendTo(controls);

      var
        t = this,
        total = controls.find('.mejs-time-total'),
        loaded  = controls.find('.mejs-time-loaded'),
        current  = controls.find('.mejs-time-current'),
        handle  = controls.find('.mejs-time-handle'),
        timefloat  = controls.find('.mejs-time-float'),
        timefloatcurrent  = controls.find('.mejs-time-float-current'),
        handleMouseMove = function(e) {
          // mouse position relative to the object
          var x = e.pageX,
            offset = total.offset(),
            width = total.outerWidth(true),
            percentage = 0,
            newTime = 0,
            pos = 0;


          if (media.duration) {
            if (x < offset.left) {
              x = offset.left;
            } else if (x > width + offset.left) {
              x = width + offset.left;
            }

            pos = x - offset.left;
            percentage = (pos / width);
            newTime = (percentage <= 0.02) ? 0 : percentage * media.duration;

            // seek to where the mouse is
            if (mouseIsDown && newTime !== player.getCurrentTime()) {
              media.setCurrentTime(newTime);
            }

            // position floating time box
            if (!mejs.MediaFeatures.hasTouch) {
              timefloat.css('left', pos);
              timefloatcurrent.html(mejs.Utility.secondsToTimeCode(newTime));
              timefloat.show();
            }
          }
        },
        mouseIsDown = false,
        mouseIsOver = false;

      // handle clicks
      //controls.find('.mejs-time-rail').delegate('span', 'click', handleMouseMove);
      total
        .bind('mousedown', function (e) {
          // only handle left clicks
          if (e.which === 1) {
            mouseIsDown = true;
            handleMouseMove(e);
            $(document)
              .bind('mousemove.dur', function(e) {
                handleMouseMove(e);
              })
              .bind('mouseup.dur', function (e) {
                mouseIsDown = false;
                timefloat.hide();
                $(document).unbind('.dur');
              });
            return false;
          }
        })
        .bind('mouseenter', function(e) {
          mouseIsOver = true;
          $(document).bind('mousemove.dur', function(e) {
            handleMouseMove(e);
          });
          if (!mejs.MediaFeatures.hasTouch) {
            timefloat.show();
          }
        })
        .bind('mouseleave',function(e) {
          mouseIsOver = false;
          if (!mouseIsDown) {
            $(document).unbind('.dur');
            timefloat.hide();
          }
        });

      // loading
      media.addEventListener('progress', function (e) {
        player.setProgressRail(e);
        player.setCurrentRail(e);
      }, false);

      // current time
      media.addEventListener('timeupdate', function(e) {
        player.setProgressRail(e);
        player.setCurrentRail(e);
      }, false);


      // store for later use
      t.loaded = loaded;
      t.total = total;
      t.current = current;
      t.handle = handle;
    },
    setProgressRail: function(e) {
      var
        t = this,
        target = (e != undefined) ? e.target : t.media,
        percent = null;

      // newest HTML5 spec has buffered array (FF4, Webkit)
      if (target && target.buffered && target.buffered.length > 0 && target.buffered.end && target.duration) {
        // TODO: account for a real array with multiple values (only Firefox 4 has this so far)
        percent = target.buffered.end(0) / target.duration;
      }
      // Some browsers (e.g., FF3.6 and Safari 5) cannot calculate target.bufferered.end()
      // to be anything other than 0. If the byte count is available we use this instead.
      // Browsers that support the else if do not seem to have the bufferedBytes value and
      // should skip to there. Tested in Safari 5, Webkit head, FF3.6, Chrome 6, IE 7/8.
      else if (target && target.bytesTotal != undefined && target.bytesTotal > 0 && target.bufferedBytes != undefined) {
        percent = target.bufferedBytes / target.bytesTotal;
      }
      // Firefox 3 with an Ogg file seems to go this way
      else if (e && e.lengthComputable && e.total != 0) {
        percent = e.loaded/e.total;
      }

      // finally update the progress bar
      if (percent !== null) {
        percent = Math.min(1, Math.max(0, percent));
        // update loaded bar
        if (t.loaded && t.total) {
          t.loaded.width(t.total.width() * percent);
        }
      }
    },
    setCurrentRail: function() {
      var t = this;

      if (t.media.currentTime != undefined && t.media.duration) {

        // update bar and handle
        if (t.total && t.handle) {
          var
            newWidth = t.total.width() * t.media.currentTime / t.media.duration,
            handlePos = newWidth - (t.handle.outerWidth(true) / 2);

          t.current.width(newWidth);
          t.handle.css('left', handlePos);
        }
      }

    }
  });
})(mejs.$);
(function($) {
  // options
  $.extend(mejs.MepDefaults, {
    duration: -1,
    timeAndDurationSeparator: ' <span class="mejs-timeseparator"> / </span> '
  });

  // current and duration 00:00 / 00:00
  $.extend(MediaElementPlayer.prototype, {
    buildcurrent: function(player, controls, media) {
      var t = this;

      $('<div class="mejs-time">'+
          '<span class="mejs-currenttime">' + (player.options.alwaysShowHours ? '00:' : '')
          + '00:00' + '</span>'+
          '</div>')
          .appendTo(controls);

      t.currenttime = t.controls.find('.mejs-currenttime');

      media.addEventListener('timeupdate',function() {
        player.updateCurrent();
      }, false);
    },

    buildduration: function(player, controls, media) {
      var t = this;

      if (controls.children().last().find('.mejs-currenttime').length > 0) {
        $(t.options.timeAndDurationSeparator +
          '<span class="mejs-duration">' +
            (t.options.duration > 0 ?
              mejs.Utility.secondsToTimeCode(t.options.duration, t.options.alwaysShowHours || t.media.duration > 3600, t.options.showTimecodeFrameCount,  t.options.framesPerSecond || 25) :
                ((player.options.alwaysShowHours ? '00:' : '') + '00:00')
              ) +
          '</span>')
          .appendTo(controls.find('.mejs-time'));
      } else {

        // add class to current time
        controls.find('.mejs-currenttime').parent().addClass('mejs-currenttime-container');

        $('<div class="mejs-time mejs-duration-container">'+
          '<span class="mejs-duration">' +
            (t.options.duration > 0 ?
              mejs.Utility.secondsToTimeCode(t.options.duration, t.options.alwaysShowHours || t.media.duration > 3600, t.options.showTimecodeFrameCount,  t.options.framesPerSecond || 25) :
                ((player.options.alwaysShowHours ? '00:' : '') + '00:00')
              ) +
          '</span>' +
        '</div>')
        .appendTo(controls);
      }

      t.durationD = t.controls.find('.mejs-duration');

      media.addEventListener('timeupdate',function() {
        player.updateDuration();
      }, false);
    },

    updateCurrent:  function() {
      var t = this;

      if (t.currenttime) {
        t.currenttime.html(mejs.Utility.secondsToTimeCode(t.media.currentTime, t.options.alwaysShowHours || t.media.duration > 3600, t.options.showTimecodeFrameCount,  t.options.framesPerSecond || 25));
      }
    },

    updateDuration: function() {
      var t = this;

      if (t.media.duration && t.durationD) {
        t.durationD.html(mejs.Utility.secondsToTimeCode(t.media.duration, t.options.alwaysShowHours, t.options.showTimecodeFrameCount, t.options.framesPerSecond || 25));
      }
    }
  });

})(mejs.$);
(function($) {

  $.extend(mejs.MepDefaults, {
    muteText: 'Mute Toggle',
    hideVolumeOnTouchDevices: true,
  });

  $.extend(MediaElementPlayer.prototype, {
    buildvolume: function(player, controls, media) {
      // Android and iOS don't support volume controls
      if (mejs.MediaFeatures.hasTouch && this.options.hideVolumeOnTouchDevices)
        return;

      var t = this,
        mute = $('<div class="mejs-button mejs-volume-button mejs-mute">'+
          '<button type="button" aria-controls="' + t.id + '" title="' + t.options.muteText + '"></button>'+
        '</div>' +
        '<div class="mejs-volume-slider">'+ // outer background
          '<div class="mejs-volume-total"></div>'+ // line background
          '<div class="mejs-volume-current"></div>'+ // current volume
          '<div class="mejs-volume-handle"></div>'+ // handle
        '</div>'
        )
          .appendTo(controls),
      volumeSlider = t.container.find('.mejs-volume-slider'),
      volumeTotal = t.container.find('.mejs-volume-total'),
      volumeCurrent = t.container.find('.mejs-volume-current'),
      volumeHandle = t.container.find('.mejs-volume-handle'),

      positionVolumeHandle = function(volume, secondTry) {

        if (!volumeSlider.is(':visible') && typeof secondTry == 'undefined') {
          volumeSlider.show();
          positionVolumeHandle(volume, true);
          volumeSlider.hide()
          return;
        }

        // correct to 0-1
        volume = Math.max(0,volume);
        volume = Math.min(volume,1);

        // ajust mute button style
        if (volume == 0) {
          mute.removeClass('mejs-mute').addClass('mejs-unmute');
        } else {
          mute.removeClass('mejs-unmute').addClass('mejs-mute');
        }

        // position slider
        var
          // height of the full size volume slider background
          totalWidth = volumeTotal.width(),

          // top/left of full size volume slider background
          totalPosition = volumeTotal.position(),

          // the new left position based on the current volume
          newLeft = totalWidth * volume;

        // handle
        volumeHandle.css('left', Math.round(totalPosition.left + newLeft - (volumeHandle.width() / 2)));

        // rezize the current part of the volume bar
        volumeCurrent.width( Math.round(newLeft) );

      },
      handleVolumeMove = function(e) {

        var volume = null,
          totalOffset = volumeTotal.offset();

        // calculate the new volume based on the mouse position
        var
          railWidth = volumeTotal.width(),
          newX = e.pageX - totalOffset.left;

        volume = newX / railWidth;

        // ensure the volume isn't outside 0-1
        volume = Math.max(0,volume);
        volume = Math.min(volume,1);

        // position the slider and handle
        positionVolumeHandle(volume);

        // set the media object (this will trigger the volumechanged event)
        if (volume == 0) {
          media.setMuted(true);
        } else {
          media.setMuted(false);
        }
        media.setVolume(volume);
      },
      mouseIsDown = false,
      mouseIsOver = false;

      // SLIDER

      mute
        .hover(function() {
          volumeSlider.show();
          mouseIsOver = true;
        }, function() {
          mouseIsOver = false;
        });

      volumeSlider
        .bind('mouseover', function() {
          mouseIsOver = true;
        })
        .bind('mousedown', function (e) {
          handleVolumeMove(e);
          $(document)
            .bind('mousemove.vol', function(e) {
              handleVolumeMove(e);
            })
            .bind('mouseup.vol', function () {
              mouseIsDown = false;
              $(document).unbind('.vol');
            });
          mouseIsDown = true;

          return false;
        });


      // MUTE button
      mute.find('button').click(function() {
        media.setMuted( !media.muted );
      });

      // listen for volume change events from other sources
      media.addEventListener('volumechange', function(e) {
        if (!mouseIsDown) {
          if (media.muted) {
            positionVolumeHandle(0);
            mute.removeClass('mejs-mute').addClass('mejs-unmute');
          } else {
            positionVolumeHandle(media.volume);
            mute.removeClass('mejs-unmute').addClass('mejs-mute');
          }
        }
      }, false);

      if (t.container.is(':visible')) {
        // set initial volume
        positionVolumeHandle(player.options.startVolume);

        // shim gets the startvolume as a parameter, but we have to set it on the native <audio> elements
        if (media.pluginType === 'native') {
          media.setVolume(player.options.startVolume);
        }
      }
    }
  });
