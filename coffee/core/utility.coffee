jQuery.fn.between = (elm0, elm1) ->
  index0 = $(this).index(elm0)
  index1 = $(this).index(elm1)

  if (index0 <= index1)
    return this.slice index0, index1 + 1
  else
    return this.slice index1, index0 + 1

jQuery.fn.center = ->
  @css "position", "absolute"
  @css("top", Math.max(0, (($(window).height() - @outerHeight()) / 2) + $(window).scrollTop()) + "px")
  @css("left", Math.max(0, (($(window).width() - @outerWidth()) / 2) + $(window).scrollLeft()) + "px")
  this

jQuery.fn.replaceClass = (original, replacement) ->
  @removeClass(original).addClass(replacement)

resizeWindow = ->
  $('#modal').center()
  return true