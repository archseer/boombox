class Artist
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  has_many :tracks
  has_many :albums
end
