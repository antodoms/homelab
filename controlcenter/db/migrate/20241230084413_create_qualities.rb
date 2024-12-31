class CreateQualities < ActiveRecord::Migration[8.0]
  def change
    create_table :qualities do |t|
      t.timestamps

      t.string :title
    end
  end
end
