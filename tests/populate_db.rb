require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require "faker"

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init

def random_record(model)
  model.order(Sequel.lit('RANDOM()')).first
end

def random(max)
  rand(max).to_i + 1
end

n_users = 50
n_tags = 20
n_graphics = 10
n_taggings = 100

puts "creating users ..."
# bypass auth
(1..n_users).each do
  individual = Faker::Lorem.paragraph.split(" ").sample
  $_db[:users].insert(
      role: 1,
      email: "test_#{individual}_#{random(99999999)}@example.com",
      created_at: Time.now
  )
end

puts "creating tags ..."

(1..n_tags-1).each do |i|
  Tag.create(name: Faker::Lorem.unique.word)
end
Tag.create(name: "din a4") # ensure certain tags for testing

puts "creating graphics ..."
(1..n_graphics).each do |i|
  graphic = Graphic.create(
      # description: Faker::Lorem.sentence, #
      title: Faker::Quote.famous_last_words,
      description: Faker::Lorem.paragraph
      )

  puts "creating variants and versions for graphic no " + graphic.id.to_s + " ..."
  (1..random(5)).each do |j|
    variant = graphic.add_variant(
        title: Faker::Lorem.paragraph + " -- " + j.to_s,
        derived_from: 0,
        description: Faker::Lorem.sentence
    )

    (1..random(10)).each do |k|
      user = random_record(User)
      variant.add_version(
          user_id: user.id,
          document: "<svg tacpic:graphic_id=\"#{graphic.id}\" tacpic:variant_id=\"#{variant.id}\">#{rand(100).to_s}</svg>"
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