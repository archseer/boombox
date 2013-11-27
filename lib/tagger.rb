class Musicfile

  attr_reader :title, :artist, :album, :year, :track, :duration,
  :disc, :albumartist, :total_tracks, :total_discs, :genre,
  :bpm

  def initialize(filename)
    @file = TagLib::MPEG::File.new filename

    tag = @file.id3v2_tag
    old_tag = @file.id3v1_tag

    disc = tag.frame_list('TPOS').first
    disc = disc ? disc.to_s.split('/') : [nil, nil]

    @title = tag.title || old_tag.title || File.basename(filename, '.*')
    @artist = tag.artist || old_tag.artist
    @album = tag.album || old_tag.album
    @year = tag.year || old_tag.year
    @track = tag.track || old_tag.track
    @duration = @file.audio_properties.length
    @disc = disc[0]

    @albumartist = tag.frame_list('TPE2').first.to_s
    @albumartist = nil if @albumartist.blank?

    @total_tracks = tag.frame_list('TRCK').first.to_s.split('/')[1]
    @total_discs = disc[1]
    @genre = tag.genre || old_tag.genre
    # @rating = 
    @bpm = tag.frame_list('TBPM').first.to_s.to_i
  end

end

module Tagger
  def self.generate_db sinatra
    files = Dir["#{File.dirname(__FILE__)}/../public/music/**/*.mp3"].uniq #symlink follow {,/*/**}
    files.each {|filename|
      puts filename
      file = Musicfile.new filename
      
      track = Track.new(
        title:  file.title,
        artist: file.artist,
        album:  file.album,
        year:   file.year,
        track:  file.track,
        duration: file.duration,
        disc: file.disc,
        albumartist: file.albumartist,
        total_tracks:file.total_tracks,
        total_discs: file.total_discs,
        genre: file.genre,
        #rating: ,
        bpm: file.bpm,
      )
      track.filename = sinatra.relative_to filename

      # pwd is project root
      # %x{bin/waveform --width 1200 --height 180 --color-bg ffffffff --color-center 00000000 --color-outer 00000000 "public/#{t.filename}" "public/waveforms/#{t.id}.png"}

      track.save!
    }
  end
end
