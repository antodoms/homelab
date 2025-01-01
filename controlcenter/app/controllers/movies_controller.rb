class MoviesController < ApplicationController
    def index
        @movies = Movie.where(status: "completed")
                       .order(created_at: :desc)
    end

    def torrent
        @movies = Movie.includes(:download_artifacts)
                       .where(status: "completed")
                       .order("download_artifacts.created_at DESC")
    end
end
