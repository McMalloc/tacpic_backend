class CreateVariants < Sequel::Migration
  def up
    create_table :variants do
      primary_key :id
      foreign_key :graphic_id, :graphics
      Integer :derived_from

      Integer :graphic_no_of_pages
      String :graphic_format
      TrueClass :graphic_landscape
      # constraint(:graphic_valid_format){%w(a4 a4_landscape a3 a3_landscape).include? graphic_format}

      Integer :braille_no_of_pages
      String :braille_format
      # constraint(:braille_valid_format){%w(a4 a3).include? braille_format}

      String :file_name
      String :medium
      String :braille_system
      TrueClass :public, default: true
      String :title, null: false
      String :description, longtext: true
      DateTime :created_at

      full_text_index [:title, :description]
    end
  end

  def down
    drop_table :variants
  end
end