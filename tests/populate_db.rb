require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require "faker"
require './processing/Document'
require 'erb'
require 'securerandom'

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init

document_template = File.read './tests/test_data/catalogue_template.txt'

def random_record(model)
  model.order(Sequel.lit('RANDOM()')).first
end

def random(max)
  rand(max).to_i + 1
end

n_users = 100
n_tags = 15
n_graphics = 100
n_taggings = 500

puts "creating users ..."
# bypass auth
(1..n_users).each do |index|
  $_db[:users].insert(
      role: 1,
      email: Faker::Internet.email,
      created_at: Time.now
  )

  User[index].add_address(
      city: Faker::Address.city,
      zip: Faker::Address.zip[0..4],
      street: Faker::Address.street_name,
      house_number: random(40),
      is_invoice_addr: false,
      country: "DEU",
      first_name: Faker::Name.first_name ,
      last_name: Faker::Name.last_name ,
      additional: Faker::Address.secondary_address
  )

  if random(10) > 8
    User[index].add_address(
        city: Faker::Address.city,
        zip: Faker::Address.zip,
        street: Faker::Address.street_name,
        house_number: random(40),
        is_invoice_addr: true,
        country: "DEU",
        company_name: Faker::Company.name + ' ' + Faker::Company.suffix,
        additional: Faker::Address.secondary_address
    )
  end
end

puts "creating tags ..."

(1..4).each do |i|
  Taxonomy.create(
      taxonomy: Faker::Lorem.words(number: [1, 2].sample),
      description: Faker::Lorem.words(number: (3..9).to_a.sample)
  )
end

(1..n_tags - 1).each do |i|
  Tag.create(
      name: Faker::Lorem.unique.word,
      taxonomy_id: (1..4).to_a.sample,
      description: Faker::Lorem.words(number: [3, 4, 5].sample)
  )
end

puts "creating graphics ..."
(1..n_graphics).each do |i|
  user = random_record(User)
  graphic = Graphic.create(
      # description: Faker::Lorem.sentence, #
      user_id: user.id,
      title: Faker::Quote.famous_last_words
  )

  puts "creating variants and versions for graphic no " + graphic.id.to_s + " ..."
  (1..random(4)).each do |j|
    variant = graphic.add_variant(
        title: j == 1 ? 'Basis' : Faker::Color.color_name + " " + Faker::Restaurant.name,
        derived_from: j == 0 ? nil : 0,
        width: j % 2 == 0 ? 210 : 297,
        height: j % 2 == 0 ? 297 : 420,
        medium: 'swell',
        braille_system: %w(de-de-g0.utb de-de-g1.ctb de-de-g2.ctb).sample,
        description: Faker::Lorem.paragraph(sentence_count: [6,8,10,14,20].sample)
    )

    (1..random(5)).each do |k|
      user = random_record(User)

      renderer = ERB.new document_template
      variant.add_version(
          user_id: user.id,
          document: renderer.result
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

User.create(
    email: 'robert@tacpic.de',
    display_name: 'robert'
)