$(document).ready ->
  # var tracking the playing item.
  playing = ""
  title = $('title')

  load_song = (e) ->
    $.post 'ajax/track', { track_id: $(e).attr('id') }, (data) ->
      player.pause()
      player.setSrc(data.track)
      player.play()
      $('#player').attr('class', $(e).attr('id')) # audioElement
      playing.removeClass('playing').removeClass('paused') if playing isnt ""
      playing = e.addClass 'playing'
      
  player = new MediaElementPlayer('audio', {
    audioWidth: '100%',
    features: ['playpause','progress','current','duration','volume'],
    timeAndDurationSeparator: ' <span class="mejs-timeseparator"> / </span> ',
    success: (mediaElement, domObject) ->
      mediaElement.addEventListener('pause', ->
        playing.removeClass('playing').addClass('paused')
        title.html(title.html().replace('\u25B6 ', ''))
      , false)
      mediaElement.addEventListener('play', ->
        playing.removeClass('paused').addClass('playing')
        title.html(title.html().replace('\u25B6 ', ''))
        title.html (i, text)-> "&#9654; " + text
      , false)
      mediaElement.addEventListener('ended', ->
        load_song(playing.next())
      , false)
  })

  $('#table tbody').on 'dblclick', 'tr', ->
    row = $(this)
    load_song row

  return true