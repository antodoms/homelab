class DownloadArtifact < ApplicationRecord
    belongs_to :movie
    belongs_to :quality
    belongs_to :language
end
