Boombox.unloadTempEventListeners()

oldID = -1 # something that the ID will never be for start value
loadData =->
  unless oldID == Boombox.songID
    $.get "ajax/track/#{Boombox.songID}", (data) ->
      $('#contents.player #cover img').attr 'src', data.cover
      $('#contents.player .artist').text data.artist
      $('#contents.player .album').text data.album
      $('#contents.player .title').text data.title
      oldID = Boombox.songID

loadData()
Boombox.registerTempEventListener('play', loadData, false)