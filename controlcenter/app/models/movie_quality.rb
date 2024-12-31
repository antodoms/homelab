class MovieQuality < ApplicationRecord
    belongs_to :movie
    belongs_to :quality
end
