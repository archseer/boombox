Boombox?.unloadTempEventListeners()

oldID = -1 # something that the ID will never be for start value
loadData = ->
  unless oldID == Boombox.songID
    $.get "api/track/#{Boombox.songID}", (data) ->
      $('#contents.player #cover img').attr 'src', data.cover
      $('#contents.player .artist').text " " + data.artist
      $('#contents.player .album').text " " + data.album
      $('#contents.player .title').text " " + data.title
      oldID = Boombox.songID

loadData() if Boombox?

Player.executeOnLoad ->
  Boombox.registerTempEventListener('play', loadData, false)