class TamilmvParseJob < ApplicationJob
    def perform(movie_id)
        movie = Movie.find(movie_id)

        return if movie.status == "parsed"

        update_imdb_id(movie)
        update_tmdb_id(movie)

        movie.update(status: "parsed")

        process_download_links(movie)
    end

    def update_imdb_id(movie)
        return if movie.imdb_id.present?

        service = IMDBService.new(title: movie.title, year: movie.year).call

        return if service.nil?

        movie.imdb_id = service[:imdb_id]
        movie.poster_url = service[:poster]
        movie.save
    end

    def update_tmdb_id(movie)
        return if movie.tmdb_id.present?

        service = TMDBService.new(title: movie.title, year: movie.year).call

        return if service.nil?

        movie.tmdb_id = service[:id]
        movie.poster_url = "https://image.tmdb.org/t/p/w440_and_h660_face/" + service[:poster_path] if movie.poster_url.blank?
        movie.save
    end

    def process_download_links(movie)
        TamilmvThreadParseJob.perform_later(movie.id)
    end
end
