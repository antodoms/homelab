require "open-uri"

module Parsers
    class BaseParser
      class << self
        def fetch_html(url)
          Nokogiri::HTML(URI.open(url))
        end
      end
    end
end
