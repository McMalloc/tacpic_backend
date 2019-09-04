require_relative '../lib/db/config'
require 'faker'

$_db = Database::init 'development'

nrOfUsers = 50
nrOfTags = 3
nrOfVariants = 10

for a in 0..nrOfUsers do
  $_db[:users].insert(
      email: Faker::Internet.email,
      password: Faker::Internet.password(min_length: 10, max_length: 20),
      salt: Faker::Internet.password(min_length: 4, max_length: 4),
      role: 1,
      created_at: Time.now
  )


end

for a in 0..nrOfTags do
  $_db[:tags].insert name: Faker::Color.color_name, user_id: rand(nrOfUsers) + 1, created_at: Time.now
end

$_db[:graphics].insert(
    title: Faker::Lorem.sentence,
    user_id: rand(nrOfUsers) + 1,
    created_at: Time.now
)

for a in 0..nrOfVariants do
  $_db[:variants].insert(
      title: Faker::Lorem.sentence,
      user_id: rand(nrOfUsers) + 1,
      graphic_id: 1,
      created_at: Time.now
  )
end