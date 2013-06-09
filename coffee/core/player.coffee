class window.Player

  constructor: ->
    @instance = new MediaElementPlayer('audio', {
      width: '100%',
      features: ['current','duration','progress','volume'],
      timeAndDurationSeparator: ' <span class="mejs-timeseparator"> / </span> ',
      success: (mediaElement, domObject) =>

        # Speed Up: Make elements and add their class the right way, but ugly.
        $('.mejs-stop-button button').append('<i class="icon-stop"></i>')
        $('.mejs-loop-button button').append('<i class="icon-repeat"></i>')

        # Setup basic event listeners
        mediaElement.addEventListener('pause', (=> @nowPlaying.replaceClass('playing', 'paused')), false)
        mediaElement.addEventListener('play', (=> @nowPlaying.replaceClass('paused', 'playing')), false)
        mediaElement.addEventListener('ended', (=> @playNextSong() ), false)
    })

    @mediaElement = @instance.media # alias

    Player.triggerCallbacks()

    @nowPlaying = undefined # Not sure how to track properly the nowPlaying row item, here?...
    # substitute @nowPlaying with $("#song-#{@songID}")?
    @songID = undefined
    @tempEventListeners = []
    return true

  # This is ...weird
  @_callbacks = []
  @executeOnLoad: (func) ->
    if !Boombox?
      @_callbacks.push func
    else
      func.call(Boombox)

  @triggerCallbacks: ->
    while @_callbacks.length isnt 0
      @_callbacks.shift().call(Boombox)
  # weird END

  # TODO: useCapture is now bubble, so this is probably invalid
  addEventListener: (type, listener, useCapture) ->
    @instance.media.addEventListener type, listener, useCapture

  # Allows us to register a set of event listeners which we can then remove by calling unloadTempEventListeners()
  registerTempEventListener: (type, listener, useCapture) ->
    @tempEventListeners.push {type: type, "listener": listener, useCapture: useCapture}
    @addEventListener type, listener, useCapture

  unloadTempEventListeners: ->
    $(@tempEventListeners).each (index, el) =>
      @instance.media.removeEventListener(el.type, el.listener, el.useCapture)

  play: ->
    @instance.play()

  pause: ->
    @instance.pause()

  setSrc: (src) ->
    @instance.setSrc(src)

  setCurrentTime: (t) ->
    @instance.setCurrentTime(t)

  isPlaying: ->
    !@instance.media.paused

  playSong: (e) -> # e is a row in the list of songs
    $.get "api/track/#{$(e).attr('id')}", (data) =>
      @pause()
      @setSrc("/#{data.filename}")
      @instance.load()
      @play()
      @songID = $(e).attr 'id'
      @nowPlaying.removeClass('playing paused') if @nowPlaying
      @nowPlaying = e.addClass 'playing'
      $('#now-playing .cover img').attr 'src', "/#{data.cover}"

  playNextSong: ->
    nextSong = @nowPlaying.next()
    if nextSong.length > 0 then @playSong nextSong
    else @playSong @nowPlaying.parent().children('tr:first')

  playPrevSong: ->
    prevSong = @nowPlaying.prev()
    if prevSong.length > 0 then @playSong prevSong
    else @playSong @nowPlaying.parent().children('tr:last')

  registerHooks: ->
    icon = $("#player-buttons .playpause i")

    # addEventListener doesn"t work for FF... WTF?
    @addEventListener "play", ->
      alert "ASDF"
      icon.removeClass("icon-play").addClass "icon-pause"
    , false
    @addEventListener "playing", ->
      alert "ASDF"
      icon.removeClass("icon-play").addClass "icon-pause"
    , false

    @addEventListener "pause", ->
      alert "ASDF"
      icon.removeClass("icon-pause").addClass "icon-play"
    , false
    @addEventListener "paused", ->
      alert "ASDF"
      icon.removeClass("icon-pause").addClass "icon-play"
    , false

    # Top bar button handlers
    $("#player-buttons .playpause").click (e) =>
      e.preventDefault()
      if @isPlaying() then @pause() else @play()
      false
    $("#player-buttons .next").click (e) =>
      e.preventDefault()
      @playNextSong()
      false
    $("#player-buttons .back").click (e) =>
      e.preventDefault()
      @playPrevSong()
      false
