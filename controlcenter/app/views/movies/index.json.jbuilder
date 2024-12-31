json.array! @movies do |movie|
    json.title movie.title
    json.poster_url movie.poster_url
    json.year movie.year
    json.imdb_id movie.imdb_id if movie.imdb_id.present?
    json.tmdb_id movie.tmdb_id if movie.tmdb_id.present?
end
