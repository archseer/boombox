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
    elsif dir = Dir.glob("public/#{File.dirname self.filename}/*.jpg", File::FNM_CASEFOLD)
      path = dir.first
    else
      path = "blank.jpg"
    end
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
end