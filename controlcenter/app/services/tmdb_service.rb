class TMDBService
  TMDB_API_KEY = ENV["TMDB_API_KEY"]

  def initialize(title:, year:)
      @title = title
      @year = year
  end

  def call
    query = URI.encode_www_form_component(@title)

    url = URI("https://api.themoviedb.org/3/search/movie?query=#{query}&year=#{@year}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["accept"] = "application/json"
    request["Authorization"] = "Bearer " + TMDB_API_KEY

    response = http.request(request)

    # Parse the JSON response
    if response.code.to_i == 200
      data = JSON.parse(response.body)
      if data["results"].count > 0
        snake_case_keys(data["results"][0])
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
