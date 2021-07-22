class CreateTags < Sequel::Migration
  def up
    create_table :tags do
      primary_key :id
      foreign_key :user_id, :users
      foreign_key :taxonomy_id, :taxonomies

      String :name, size: 255, unique: true # Original name, for now the actual name of the tag, in light of i18n it will be the reference moniker for translations and the tag_id will be used to map translations

      String :description
      DateTime :created_at

      index :name
      # constraint name_min_length: char_length(:name) > 2
    end
  end

  def down
    drop_table? :tags
  end
end
