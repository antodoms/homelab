module Parsers
    class TamilmvThreadParser < BaseParser
      def initialize(url)
        @url = url
      end

      def process
        page = self.class.fetch_html(@url)
        extract_torrent_data(page)
      end

      def extract_torrent_data(doc)
        # Find all torrent links with "1080p" in their text
        torrent_link = doc.css('a[data-fileext="torrent"]').find do |link|
            link.text.include?("1080p")
        end

        return unless torrent_link

        torrent_url = torrent_link["href"]
        title = torrent_link.text.strip

        # Extract the magnet URL for the same 1080p torrent if available
        magnet_link = doc.css('a[href^="magnet:"]').find do |link|
        link["href"].include?("1080p")
        end
        magnet_url = magnet_link["href"] if magnet_link

        # Extract language from the title
        language = title.match(/\((.*?)\)/)&.captures&.first

        {
            torrent_url: torrent_url,
            title: title,
            magnet_url: magnet_url,
            quality: "1080p",
            language: language
        }
      end
    end
end
