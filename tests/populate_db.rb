require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require "faker"

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init

def random_record(model)
  model.order(Sequel.lit('RAND()')).first
end

def random(max)
  rand(max).to_i + 1
end

n_users = 500
n_tags = 50
n_graphics = 100
n_taggings = 500

puts "creating users ..."
# bypass auth
(1..n_users).each do
  $_db[:users].insert(
      role: 1,
      created_at: Time.now
  )
end

puts "creating tags ..."
(1..n_tags).each do |i|
  Tag.create(
         # user_id: rand(98).to_i + 1,
         name: Faker::Lorem.unique.word
  )
end

puts "creating graphics ..."
(1..n_graphics).each do |i|
  graphic = Graphic.create(
      description: Faker::Lorem.sentence, #
      title: Faker::Quote.famous_last_words,

      )

  puts "creating variants and versions for graphic no " + graphic.id.to_s + " ..."
  (1..random(5)).each do |j|
    variant = graphic.add_variant(
        title: Faker::Lorem.paragraph + " -- " + j.to_s,
        description: Faker::Lorem.sentence,
        long_description: Faker::Lorem.paragraph
    )

    (1..random(10)).each do |k|
      user = random_record(User)
      variant.add_version(
          user_id: user.id,
          document: "<svg tacpic:graphic_id=\"#{graphic.id}\" tacpic:variant_id=\"#{variant.id}\"></svg>"
      )
    end
  end
end

puts "creating taggings..."
(1..n_taggings).each do
  Tagging.create(
      user_id: random_record(User).id,
      tag_id: random_record(Tag).id,
      variant_id: random_record(Variant).id
  )
end