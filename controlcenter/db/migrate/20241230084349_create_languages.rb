class CreateLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :languages do |t|
      t.timestamps

      t.string :title
    end
  end
end
