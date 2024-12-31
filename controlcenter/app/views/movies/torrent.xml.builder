xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
    xml.channel do
      xml.title "Movie Torrent Links"
      xml.description "List of movies with Torrent Download Links"
      xml.link movies_torrent_path(format: :xml)
      xml.language "en-us"

      @movies.each do |movie|
        xml.item do
          xml.title movie.title
          xml.description movie.full_title
          xml.pubDate movie.created_at.to_s
          xml.link movie_url(movie)
          xml.guid movie_url(movie)
          xml.enclosure url: movie.download_artifacts[0].torrent_link, length: "10000", type: "application/x-bittorrent"
        end
      end
    end
  end
