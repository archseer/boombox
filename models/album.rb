class Album
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  has_many   :tracks
  belongs_to :artist

  after_save do |document|
    # Delete the model if no tracks
    # (later, do this via a background queue)
  end
end
