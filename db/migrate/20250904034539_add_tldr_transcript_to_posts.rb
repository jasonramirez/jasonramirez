class AddTldrTranscriptToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :tldr_transcript, :text
  end
end
