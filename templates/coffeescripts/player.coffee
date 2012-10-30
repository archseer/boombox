$.get "ajax/track/#{$('#player').attr('class')}", (data) ->
  $('#contents.player #cover img').attr 'src', data.cover
  $('#contents.player .artist').text data.artist
  $('#contents.player .album').text data.album
  $('#contents.player .title').text data.title