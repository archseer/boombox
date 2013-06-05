Boombox?.unloadTempEventListeners()
# Table cell selection
lastCell = ''
$(document).on 'click', '#table-album-list tbody tr', (e) ->
  if e.ctrlKey
    $(this).toggleClass 'active'
    lastCell = $(this) if $(this).hasClass 'active'
  else if e.shiftKey and lastCell? and lastCell isnt ''
    $('#table-album-list tr').between($(this), lastCell).each ->
      lastCell = $(this).addClass 'active'
  else
    $('#table-album-list tr').removeClass 'active'
    lastCell = $(this).addClass 'active'

# BOOMBOX
# '\u25B6 ' => unicode for the play icon
$(document).on 'dblclick', '#table-album-list tbody tr', -> Boombox.playSong($(this))
$(document).on 'tap', '#table-album-list tbody tr', ->
  $('#table-album-list tr').removeClass 'active'
  $(this).toggleClass 'active'
  Boombox.playSong($(this))

if Boombox? and Boombox.songID?
  Boombox.nowPlaying = $("tr##{Boombox.songID}")
  if Boombox.isPlaying()
    Boombox.nowPlaying.replaceClass('paused', 'playing')
  else
    Boombox.nowPlaying.replaceClass('playing', 'paused')
