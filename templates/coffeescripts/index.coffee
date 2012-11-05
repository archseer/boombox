Boombox?.unloadTempEventListeners()
# Table cell selection
lastCell = ''
$('#table tbody').on 'click', 'tr', (e) ->
  if e.ctrlKey
    $(this).toggleClass 'active'
    lastCell = $(this) if $(this).hasClass 'active'
  else if e.shiftKey and lastCell? and lastCell isnt ''
    $('#table tr').between($(this), lastCell).each ->
      lastCell = $(this).addClass 'active'
  else
    $('#table tr').removeClass 'active'
    lastCell = $(this).addClass 'active'

# BOOMBOX
# '\u25B6 ' => unicode for the play icon
$('#table tbody').on 'dblclick', 'tr', -> Boombox.playSong($(this))
$('#table tbody').on 'tap', 'tr', ->
  $('#table tr').removeClass 'active'
  $(this).toggleClass 'active'
  Boombox.playSong($(this))

if Boombox? and Boombox.songID?
  Boombox.nowPlaying = $("tr##{Boombox.songID}")
  if Boombox.isPlaying()
    Boombox.nowPlaying.replaceClass('paused', 'playing')
  else
    Boombox.nowPlaying.replaceClass('playing', 'paused')
