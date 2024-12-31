class CreateMovies < ActiveRecord::Migration[8.0]
  def change
    create_table :movies do |t|
      t.timestamps

      t.string :title
      t.string :full_title
      t.string :year
      t.string :status

      t.string :imdb_id
      t.string :tmdb_id

      t.string :poster_url
      t.string :thread_url
    end
  end
end
