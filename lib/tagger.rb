module Tagger
  def self.generate_db sinatra
    files = Dir["#{File.dirname(__FILE__)}/../public/music/**/*.mp3"]
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
        :albumartist => tag.frame_list('TPE2').first,
        :total_tracks => tag.frame_list('TRCK').first.to_s.split('/')[1],
        :total_discs => disc[1],
        :genre => tag.genre || old_tag.genre,
        #:rating => ,
        :bpm => tag.frame_list('TBPM').first,
      )
      t.filename = sinatra.relative_to filename
        
      # pwd is project root
      %x{bin/waveform --width 1200 --height 180 --color-bg ffffffff --color-center 00000000 --color-outer 00000000 "public/#{t.filename}" "public/waveforms/#{t.id}.png"}

      t.save!
    }
  end

  def self.write_tags track
    # Load an ID3v2 tag from a file
    TagLib::MPEG::File.open("public/#{track.filename}") do |file|
      tag = file.id3v2_tag

      tag.title = track.title
      tag.artist = track.artist
      tag.album = track.album
      tag.year = track.year.to_i
      tag.genre = track.genre
      # track count
      if track.total_tracks and track.track
        tag.frame_list('TRCK').first.text = "#{track.track}/#{track.total_tracks}"
      elsif tag.track
        tag.track = track.track.to_i
      end
      # add album artist
      if track.albumartist
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TPE2',TagLib::String::UTF8) if tag.frame_list('TPE2').empty?
        tag.frame_list('TPE2').first.text = track.albumartist
      end
      # add disc
      if track.disc
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TPOS',TagLib::String::UTF8) if tag.frame_list('TPOS').empty?
        disc = track.disc.to_s
        disc << "/#{track.total_discs}" if track.total_discs
        tag.frame_list('TPOS').first.text = disc
      end
      # bpm
      if track.bpm
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TBPM',TagLib::String::UTF8) if tag.frame_list('TBPM').empty?
        tag.frame_list('TBPM').first.text = track.bpm.to_s
      end

      file.save
    end
  end
end