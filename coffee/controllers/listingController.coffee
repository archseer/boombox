# List view controller
#
# Fancy description here
#
window.boomboxApp.controller "listingController", ($scope, $http) ->

  # Update sidebar
  $('.sidebar li').removeClass "selected"
  $("#link-index").addClass "selected"
  $("#contents").removeClass().addClass "index"

  # Set up events
  Boombox?.unloadTempEventListeners()

  # Table cell selection
  lastCell = ''
  $("#table-album-list tbody").on 'click', 'tr', (e) ->
    if e.ctrlKey
      $(this).toggleClass 'active'
      lastCell = $(this) if $(this).hasClass 'active'
    else if e.shiftKey and lastCell? and lastCell isnt ''
      $('#table-album-list tr').between($(this), lastCell).each ->
        lastCell = $(this).addClass 'active'
    else
      $('#table-album-list tr').removeClass 'active'
      lastCell = $(this).addClass 'active'

  $("#table-album-list tbody").on 'dblclick', 'tr', -> Boombox.playSong($(this))
  $("#table-album-list tbody").on 'tap', 'tr', ->
    $('#table-album-list tr').removeClass 'active'
    $(this).toggleClass 'active'
    Boombox.playSong($(this))

  if Boombox? and Boombox.songID?
    Boombox.nowPlaying = $("tr##{Boombox.songID}")
    if Boombox.isPlaying()
      Boombox.nowPlaying.replaceClass('paused', 'playing')
    else
      Boombox.nowPlaying.replaceClass('playing', 'paused')

  # Request data
  $http({
      url: "/api/tracks/all",
      method: "GET"
  }).success (data) ->
    $scope.tracks = data