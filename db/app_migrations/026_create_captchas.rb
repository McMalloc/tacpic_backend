class CreateCaptchas < Sequel::Migration
  def up
    create_table :captchas do
      primary_key :id
      String :question_key
      String :answer_pattern_key

      Integer :times_asked, null: false, default: 0
      Integer :times_false_negative, null: false, default: 0

      DateTime :created_at, null: false
    end
  end

  def down
    drop_table? :captchas
  end
end