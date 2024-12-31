module Parsers
  class TamilmvParser < BaseParser
    class << self
      BASE_URL = "https://www.1tamilmv.tf"
      VALID_LANGUAGES = %w[tamil telugu hindi malayalam kannada english].freeze

      def process
        movies = get_contents
        movies.each do |movie|
          object = Movie.find_by(title: movie[:title], year: movie[:year])
          next if object

          object = Movie.new(title: movie[:title], year: movie[:year], full_title: movie[:full_title], status: "queued", thread_url: movie[:link])
          movie[:languages].each do |lang|
            language = Language.find_or_create_by(title: lang)
            object.languages << language
          end
          movie[:quality].each do |quality|
            object.qualities << Quality.find_or_create_by(title: quality)
          end
          object.save

          TamilmvParseJob.perform_later(object.id)
        end
      end

      def extract_year(full_title)
        match = full_title.match(/\((\d{4})\)/)
        match ? match[1] : nil
      end

      def extract_language_and_quality(text)
        languages = text.scan(/\[(.*?)]/).flatten.first&.split("+")&.select { |lang| VALID_LANGUAGES.include? lang.downcase } || []
        quality = text.scan(/\b(1080p|720p|480p|4K)\b/).flatten.uniq
        [ languages, quality ]
      end

      # Fallback function to extract languages from full_title
      def extract_languages_from_title(title)
        VALID_LANGUAGES.select { |lang| title.downcase.include?(lang) }
      end

      # Check if the title contains Sxx Exx (e.g., S04 EP06)
      def is_episode?(title)
        title.match?(/S\d{2}\s*E\d{2}/i)
      end

      # Helper method to extract short title
      def extract_short_title(full_title)
        # Use a regex to remove details like year, language, and other metadata
        short_title = full_title.sub(/\s*\(.*?\).*/, "") # Remove content inside parentheses and after
        short_title.strip
      end

      def get_contents
        page = fetch_html(BASE_URL)

        movies = []

        page.css("span").each do |span|
          title_match = span.text.strip.match(/^(.*?)(\d{4}.*?)-/)
          next unless title_match

          full_title = title_match[1].strip + title_match[2].strip
          # Skip if the title contains Sxx Exx
          next if is_episode?(full_title)

          link = span.at_xpath("following-sibling::a/@href")&.value

          # Extract languages and quality
          text = span.text + (span.at_xpath("following-sibling::a")&.text || "")
          languages, quality = extract_language_and_quality(text)

          # Fallback to extracting languages from full_title if none found
          languages = extract_languages_from_title(full_title) if languages.empty?

          movies << { title: extract_short_title(full_title), full_title: full_title, link: link, languages: languages, quality: quality, year: extract_year(full_title) } if link
        end

        # Process <a> tags directly for movies without <span> around the title
        page.css("a").each do |a|
          content = a.text.strip
          title_match = content.match(/^(.*?)(\d{4}.*?)-/)
          next unless title_match

          full_title = title_match[1].strip + title_match[2].strip
          # Skip if the title contains Sxx Exx
          next if is_episode?(full_title)
          link = a[:href]

          # Extract languages and quality
          languages, quality = extract_language_and_quality(content)

          # Fallback to extracting languages from full_title if none found
          languages = extract_languages_from_title(full_title) if languages.empty?

          movies << { title: extract_short_title(full_title), full_title: full_title, link: link, languages: languages, quality: quality, year: extract_year(full_title) } if link
        end

        movies
      end
    end
  end
end
