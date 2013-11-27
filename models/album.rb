class Album
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  has_many   :tracks
  belongs_to :artist

  after_create do |document|
    #destroy if self.tracks.empty?
    # Delete the model if no tracks
    # (later, do this via a background queue)
  end
end
