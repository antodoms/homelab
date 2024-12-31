class CreateDownloadArtifacts < ActiveRecord::Migration[8.0]
  def change
    create_table :download_artifacts do |t|
      t.timestamps

      t.string :title
      t.string :torrent_link
      t.string :magnet_link

      t.references :movie, null: false, foreign_key: true
      t.references :language, null: true, foreign_key: true
      t.references :quality, null: false, foreign_key: true
    end
  end
end
