class Track
  include MongoMapper::Document
  validates_presence_of :filename
  key :title, String
  key :artist, String
  key :album, String
  key :year, String
  key :track, Integer
  key :disc, Integer
  key :albumartist, String
  key :total_tracks, Integer
  key :total_discs, Integer
  key :genre, String
  key :rating, Integer
  key :bpm, Integer

  key :time, Integer
  key :filename, String
  timestamps!

  attr_protected :filename

  def cover
    if folder = "public/#{File.dirname self.filename}/Folder.jpg" and File.exist? folder
      path = folder
    elsif dir = Dir.glob("public/#{File.dirname self.filename}/*.{jpg,jpeg,png}", File::FNM_CASEFOLD)
      path = dir.first
    end
    path ||= "blank.png"
    path.gsub('public/', '')
  end

  def length
    sec = self.time
    min, sec = sec.divmod(60)
    h, min = min.divmod(60)
    str = ""
    str << "%02d:" % h if h > 0
    str << "%02d:" % min
    str << "%02d" % sec
    return str
  end

  # Add cover by default to json and escape URI
  def as_json(*args)
    hash = super(*args)
    hash['filename'] = URI.escape(hash['filename'])
    hash[:cover] = cover
    return hash
  end

  def write_tags
    # Load an ID3v2 tag from a file
    TagLib::MPEG::File.open("public/#{self.filename}") do |file|
      tag = file.id3v2_tag

      tag.title = self.title
      tag.artist = self.artist
      tag.album = self.album
      tag.year = self.year.to_i
      tag.genre = self.genre
      # track count
      if self.total_tracks and self.track
        tag.frame_list('TRCK').first.text = "#{self.track}/#{self.total_tracks}"
      elsif tag.track
        tag.track = self.track.to_i
      end
      # add album artist
      if self.albumartist
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TPE2',TagLib::String::UTF8) if tag.frame_list('TPE2').empty?
        tag.frame_list('TPE2').first.text = self.albumartist
      end
      # add disc
      if self.disc
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TPOS',TagLib::String::UTF8) if tag.frame_list('TPOS').empty?
        disc = self.disc.to_s
        disc << "/#{self.total_discs}" if self.total_discs
        tag.frame_list('TPOS').first.text = disc
      end
      # bpm
      if self.bpm
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TBPM',TagLib::String::UTF8) if tag.frame_list('TBPM').empty?
        tag.frame_list('TBPM').first.text = self.bpm.to_s
      end

      file.save
    end
  end
end