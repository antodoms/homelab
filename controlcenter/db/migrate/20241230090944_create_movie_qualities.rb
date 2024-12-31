class CreateMovieQualities < ActiveRecord::Migration[8.0]
  def change
    create_table :movie_qualities do |t|
      t.timestamps

      t.references :movie, null: false, foreign_key: true
      t.references :quality, null: false, foreign_key: true
    end
  end
end
