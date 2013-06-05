# Angular app definition

window.boomboxApp = angular.module "boombox", []

# Routing
window.boomboxApp.config ($routeProvider) ->

  $routeProvider.when "/", {
    controller: "listingController",
    templateUrl: "/views/listing"
  }
  $routeProvider.when "/player", {
    controller: "playerController",
    templateUrl: "/views/player"
  }
  $routeProvider.otherwise({ redirectTo: "/" })

  true