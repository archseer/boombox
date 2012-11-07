Boombox?.unloadTempEventListeners()

Player.executeOnLoad ->
  # current time
  Boombox.registerTempEventListener('timeupdate', (e) ->
    if Boombox.mediaElement.currentTime? and Boombox.mediaElement.duration
      # update position
      $('#wave-played').width("#{Boombox.mediaElement.currentTime * 100 / Boombox.mediaElement.duration}%") 
  , false)


# generate waveforms with 'waveform <file> <output.png> --method rms -ctransparent -b#fffff'

# loading
#media.addEventListener('progress', (e) ->
#  player.setProgressRail(e)
#  player.setCurrentRail(e)
#, false)