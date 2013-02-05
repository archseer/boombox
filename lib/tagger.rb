module Tagger
  def self.generate_db sinatra
    files = Dir["#{File.dirname(__FILE__)}/../public/music/**{,/*/**}/*.mp3"] #symlink follow
    files.each {|filename|
      file = TagLib::MPEG::File.new filename
      tag = file.id3v2_tag
      old_tag = file.id3v1_tag

      disc = tag.frame_list('TPOS').first 
      disc = disc ? disc.to_s.split('/') : [nil, nil]

      t = Track.new(
        :title => tag.title || old_tag.title || File.basename(filename).gsub(/\.mp3\z/, ''),
        :artist => tag.artist || old_tag.artist,
        :album => tag.album || old_tag.album,
        :year => tag.year || old_tag.year,
        :track => tag.track || old_tag.track,
        :time => file.audio_properties.length,
        :disc => disc[0],
        :albumartist => tag.frame_list('TPE2').first.to_s,
        :total_tracks => tag.frame_list('TRCK').first.to_s.split('/')[1],
        :total_discs => disc[1],
        :genre => tag.genre || old_tag.genre,
        #:rating => ,
        :bpm => tag.frame_list('TBPM').first.to_s.to_i,
      )
      t.filename = sinatra.relative_to filename
        
      # pwd is project root
      %x{bin/waveform --width 1200 --height 180 --color-bg ffffffff --color-center 00000000 --color-outer 00000000 "public/#{t.filename}" "public/waveforms/#{t.id}.png"}

      t.save!
    }
  end
end