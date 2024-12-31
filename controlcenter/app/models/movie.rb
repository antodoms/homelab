class Movie < ApplicationRecord
    has_many :movie_languages
    has_many :movie_qualities

    has_many :languages, through: :movie_languages
    has_many :qualities, through: :movie_qualities

    has_many :download_artifacts
end
