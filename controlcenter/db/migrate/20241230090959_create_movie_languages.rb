class CreateMovieLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :movie_languages do |t|
      t.timestamps

      t.references :movie, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true
    end
  end
end
