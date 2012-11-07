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

  oldID = -1 # something that the ID will never be for start value
  loadWaveform =->
    unless oldID == Boombox.songID
      $('#waveform img').attr 'src', "waveforms/#{Boombox.songID}.png"
      oldID = Boombox.songID
  Boombox.registerTempEventListener('play', loadWaveform, false)
  loadWaveform()


$('#waveform').on 'click', (e) ->
  if Boombox.mediaElement.duration
    Boombox.setCurrentTime Boombox.mediaElement.duration * (e.offsetX / $("#waveform img").width())

$('#waveform').mousemove (e) ->
  $('#wave-handle').css 'opacity', '1'
  $('#wave-handle').css 'left', e.offsetX
$('#waveform').mouseleave ->
  $('#wave-handle').css 'opacity', '0'


# generate waveforms with 'waveform <file> <output.png> --method rms -ctransparent -b#fffff'