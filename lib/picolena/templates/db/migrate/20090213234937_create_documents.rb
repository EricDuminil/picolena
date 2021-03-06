class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string   :probably_unique_id

      t.string   :complete_path
      t.string   :alias_path
      t.string   :filename
      t.string   :basename
      t.string   :filetype

      t.text     :cache_content
      t.string   :language

      t.datetime :cache_mtime
    end

    add_index(:documents, :complete_path)
    add_index(:documents, :probably_unique_id)
  end

  def self.down
    drop_table :documents
  end
end
