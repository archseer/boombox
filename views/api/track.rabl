object @track

attribute :_id => :id
attribute :title

child :artist do
  extends 'api/artist'
end

child :album do
  extends 'api/album'
end

attributes :year, :track, :disc, :total_tracks, :total_discs,
 :genre,  :rating, :bpm, :duration, :length, :cover, :created_at, :updated_at