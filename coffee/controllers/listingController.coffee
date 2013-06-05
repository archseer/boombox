# List view controller
#
# Fancy description here
#
window.boomboxApp.controller "listingController", ($scope, $http) ->
  $http({
      url: "/api/tracks/all",
      method: "GET"
  }).success (data, status, headers, config) ->
    $scope.tracks = data