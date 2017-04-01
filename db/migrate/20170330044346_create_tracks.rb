class CreateTracks < ActiveRecord::Migration[5.0]
  def change
    create_table :tracks do |t|
      t.string :name
      t.text :description

      t.integer :artist_id
      t.integer :album_id

      t.text :audio_url

      t.integer :status

      t.timestamps
    end

    add_index :tracks, :artist_id
    add_index :tracks, :album_id
  end
end
