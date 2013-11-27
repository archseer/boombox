object @artist

attribute :_id => :id
attributes :name, :created_at, :updated_at

child :albums do
  #extends 'api/albums'
end

child :tracks do
  #extends 'api/tracks'
end