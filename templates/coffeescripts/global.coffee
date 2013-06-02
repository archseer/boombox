###
  global.coffee - Controls the UI that will not get replaced via pjax
###

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


$(document).ready ->
  # Create Boombox!
  window.Boombox = new Player

  resizeWindow()
  #add the window resize callback
  $(window).resize resizeWindow

  # AJAX search
  previousSearch = "" # we check if the query has actually changed
  $('#searchbox').keyup ->
    value = $(this).val()
    if value isnt previousSearch #and value.length >= 3 #minlength
      $.post 'ajax/search', { query: value }, (data) ->
        previousSearch = value
        $('#table tbody').html(data)

  # tag editing
  $('.edit-button').on 'click', ->
    ids = (n.id for n in $('#table tr.active'))
    #ids = $.map $('#table tr.active'), (n) -> n.id

    if ids.length > 0
      # if something is selected, ajax load the modal
      $.post 'ajax/edit-modal', { query: ids }, (data) ->
        $('#container').append data
        modal = $('#modal')
        #$('#large-fields').width(modal.width() - $('#small-fields').width()-20)
        modal.center()

        # add save and close actions
        $('#modal .close').on 'click', ->
          modal.remove()
          $('#overlay').remove()

        $('#modal .save').on 'click', (e) ->
          e.preventDefault()
          $.post 'ajax/edit', $('#modal #edit').serialize(), (data) ->
            modal.remove()
            $('#overlay').remove()
            $('#container').html(data)

        # multi track edit
        checkboxes = $('#modal input[type="checkbox"]')
        if checkboxes?
          checkboxes.on 'click', ->
            obj = $(this)
            name = obj.attr('name').match(/check\[(\w+)\]/)[1]

            if obj.is(':checked')
              $("input#id3_#{name}").removeAttr("disabled")
            else
              $("input#id3_#{name}").prop('disabled', true)

  # menu buttons control, load "pages" over pjax
  #=============
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

  Boombox.registerHooks()

  return true
