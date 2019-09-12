class CreateRequestVotes < Sequel::Migration
  def up
    create_table :request_votes do
      foreign_key :user_id, :users
      foreign_key :request_id, :requests
      TrueClass :value, default: true # true: upvote, false: downvote

      primary_key [:user_id, :request_id], name: :request_vote_pk

      DateTime :created_at
    end
  end

  def down
    drop_table :request_votes
  end
end