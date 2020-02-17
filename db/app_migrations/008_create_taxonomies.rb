class CreateTaxonomies < Sequel::Migration
  def up
    create_table :taxonomies do
      primary_key :id
      String :taxonomy, size: 255, unique: true
      String :description
      DateTime :created_at
    end
  end

  def down
    if @db.table_exists?(:taxonomies)
      drop_table :taxonomies
    end
  end
end