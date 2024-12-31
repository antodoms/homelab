class Quality < ApplicationRecord
    has_many :movie_qualities
    has_many :movies, through: :movie_qualities
end
