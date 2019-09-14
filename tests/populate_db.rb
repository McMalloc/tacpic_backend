require_relative '../db/config'
require_relative '../env'
require 'faker'

$_db = Database.init ENV['TACPIC_DATABASE_URL']

nrOfUsers = 50
nrOfTags = 3
nrOfVariants = 10

def map_fields(field)
  case field
  when "email"
    Faker::Internet.email
  when "password"
    Faker::JapaneseMedia::DragonBall.character
  when "salt"
    Faker::Internet.password(min_length: 4, max_length: 4)
  when "salt"
    Faker::Internet.password(min_length: 4, max_length: 4)
  else
    Faker::Lorem.sentence
  end
end

def insert(db_name, n, fields)
  $_db[db_name]

  Hash[fields.collect { |f| [f, faker_map(f)]}]
end

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