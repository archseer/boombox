# Cover view controller
#
# Fancy description here
#
window.boomboxApp.controller "coverviewController", ($scope) ->

  $('.views a').removeClass "active"
  $(".views .link-cover-view").addClass "active"
  $("#contents").removeClass().addClass "cover_view"