#=+=+=+=+=+=+= 
# menu buttons
#=============
$(document).ready ->
  $('#menu a').pjax('#contents')

  $('#contents').on 'pjax:error', (e, xhr, err)->
    $(this).html "Something went wrong: #{err}" 

  $('#contents').on 'pjax:timeout', ->
    $(this).html "The request has timed out. Your connection may be down."

  $('#contents').on 'pjax:success', (e) ->
    # makes the current page in the menu selected
    $('#menu li').removeClass 'selected'
    $(e.relatedTarget).children('li').addClass 'selected'
    # adds the link title to class of contents for easy styling.
    $(this).removeClass().addClass $(e.relatedTarget).attr("href").slice(1)

  true