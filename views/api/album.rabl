object @album

attribute :_id => :id
attributes :name, :created_at, :updated_at

child :artist do
  extends 'api/artist'
end

child :tracks do
  #extends 'api/tracks'
end