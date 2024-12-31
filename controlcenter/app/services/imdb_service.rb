class IMDBService
  OMDB_API_KEY = ENV["OMDB_API_KEY"]

  def initialize(title:, year:)
      @title = title
      @year = year
  end

  def call
    # Encode the title and year into a query string
    query = URI.encode_www_form_component(@title)
    url = "https://www.omdbapi.com/?apikey=#{OMDB_API_KEY}&t=#{query}&y=#{@year}"

    # Make the HTTP request
    response = HTTParty.get(url)

    # Parse the JSON response
    if response.code == 200
      data = JSON.parse(response.body)
      if data["Response"] == "True"
        snake_case_keys(data)
      else
        puts "Error: #{data["Error"]}"
        nil
      end
    else
      puts "HTTP Error: #{response.code}"
      nil
    end
  end

  def snake_case_keys(hash)
    hash.transform_keys do |key|
      key.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
    end
  end
end
