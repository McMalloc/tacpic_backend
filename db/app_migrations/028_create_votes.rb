class CreateVotes < Sequel::Migration
  def up
    create_table :votes do
      foreign_key :user_id, :users
      foreign_key :post_id, :posts
      TrueClass :value, default: true # true: upvote, false: downvote

      primary_key [:user_id, :post_id], name: :vote_pk
      DateTime :created_at
    end
  end

  def down
    drop_table? :votes
  end
end