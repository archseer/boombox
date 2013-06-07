# Angular app definition

window.boomboxApp = angular.module "boombox", []

# Routing
window.boomboxApp.config ($routeProvider, $locationProvider) ->

  # HTML5 Urls
  $locationProvider.html5Mode true

  $routeProvider.when "/", {
    controller: "listingController",
    templateUrl: "/views/listing"
  }
  $routeProvider.when "/player", {
    controller: "playerController",
    templateUrl: "/views/player"
  }
  $routeProvider.when "/waveform", {
    controller: "waveformController",
    templateUrl: "/views/waveform"
  }
  $routeProvider.when "/reset", {
    controller: "resetController",
    templateUrl: "/views/reset"
  }
  $routeProvider.when "/covers", {
    controller: "coverviewController",
    templateUrl: "/views/cover_view"
  }
  $routeProvider.otherwise({ redirectTo: "/" })

  true

# Player setup
$(document).ready ->

  # Create Boombox!
  window.Boombox = new Player

  #add the window resize callback
  $(window).resize resizeWindow
  resizeWindow()

  # AJAX search
  previousSearch = '' # we check if the query has actually changed
  $('#searchbox').keyup ->
    value = $(this).val()
    if value isnt previousSearch #and value.length >= 3 #minlength
      $.post 'ajax/search', { query: value }, (data) ->
        previousSearch = value
        $('#contents tbody').html(data)

  window.Boombox.registerHooks()

  true