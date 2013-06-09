# Reset view controller
#
# Fancy description here
#
window.boomboxApp.controller "resetController", ($scope, $http) ->

  # Eye candy, #contents class
  $scope.$emit "highlightLink", ".link-reset", "reset"

  $http
    url: "/reset"
    method: "GET"
  .success (data) ->
    $scope.output = data