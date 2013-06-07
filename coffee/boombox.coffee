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

# Run block, hooks up global listener
window.boomboxApp.run ($rootScope) ->

  # Auto-centering
  $rootScope.$on "centerRequest", ->
    $(".center").each ->
      _element = $(this)

      _top = Math.max 0, ($(window).height() - _element.outerHeight()) / 2
      _left = Math.max 0, ($(window).width() - _element.outerWidth()) / 2
      _top += $(window).scrollTop()
      _left += $(window).scrollLeft()

      _element.css "position", "absolute"
      _element.css "top", _top + "px"
      _element.css "left", _left + "px"
      true
