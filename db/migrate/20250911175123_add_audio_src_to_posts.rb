class AddAudioSrcToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :audio_src, :string
  end
end
