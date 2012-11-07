Boombox?.unloadTempEventListeners()

Player.executeOnLoad ->
  # current time
  Boombox.registerTempEventListener('timeupdate', ->
    # update loaded and buffered position
    if Boombox.mediaElement.currentTime? and Boombox.mediaElement.duration
      $('#wave-played').width("#{Boombox.mediaElement.currentTime * 100 / Boombox.mediaElement.duration}%")
    if Boombox.mediaElement.bufferedTime? and Boombox.mediaElement.duration
      $('#wave-loaded').width("#{Boombox.mediaElement.bufferedTime * 100 / Boombox.mediaElement.duration}%")
  , false)

  # loading
  Boombox.registerTempEventListener('progress', ->
    # update loaded and buffered position
    if Boombox.mediaElement.currentTime? and Boombox.mediaElement.duration
      $('#wave-played').width("#{Boombox.mediaElement.currentTime * 100 / Boombox.mediaElement.duration}%")
    if Boombox.mediaElement.bufferedTime? and Boombox.mediaElement.duration
      $('#wave-loaded').width("#{Boombox.mediaElement.bufferedTime * 100 / Boombox.mediaElement.duration}%")
  , false)


$('#waveform').on 'click', (e) ->
  if Boombox.mediaElement.duration
    Boombox.setCurrentTime Boombox.mediaElement.duration * (e.offsetX / $("#waveform img").width())

# generate waveforms with 'waveform <file> <output.png> --method rms -ctransparent -b#fffff'