# Player view controller
#
# Fancy description here
#
window.boomboxApp.controller "playerController", ($scope, $http) ->

  # Update sidebar
  $('.sidebar li').removeClass "selected"
  $("#link-player").addClass "selected"
  $("#contents").removeClass().addClass "player"

  Boombox?.unloadTempEventListeners()

  oldID = -1 # something that the ID will never be for start value
  loadData = ->
    unless oldID == Boombox.songID
      $http({
        url: "/api/track/#{Boombox.songID}",
        method: "GET"
      }).success (data) ->
        $scope.track = data
        oldID = Boombox.songID

  loadData()

  Player.executeOnLoad ->
    Boombox.registerTempEventListener('play', loadData, false)