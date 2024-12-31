class TamilmvThreadParseJob < ApplicationJob
    def perform(movie_id)
        movie = Movie.find(movie_id)

        return if movie.status == "completed"

        link = Parsers::TamilmvThreadParser.new(movie.thread_url).process

        return if link.nil?

        quality = Quality.find_or_create_by(title: link[:quality])
        language = Language.find_or_create_by(title: link[:language])

        url = DownloadArtifact.find_or_create_by(movie_id: movie&.id, quality_id: quality&.id, language_id: language&.id)
        url.torrent_link = link[:torrent_url]
        url.magnet_link = link[:magnet_url]
        url.title = link[:title]
        url.save

        movie.update(status: "completed")
    end
end
