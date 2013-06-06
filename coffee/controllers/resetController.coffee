# Reset view controller
#
# Fancy description here
#
window.boomboxApp.controller "resetController", ($scope, $http) ->

  # Update sidebar
  $('.sidebar li').removeClass "selected"
  $("#link-reset").addClass "selected"
  $("#contents").removeClass().addClass "reset"

  $http({
    url: "/reset",
    method: "GET"
  }).success (data) ->
    $scope.output = data