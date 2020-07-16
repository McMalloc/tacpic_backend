require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require "faker"
require 'erb'
require 'securerandom'

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init

document_template = File.read './tests/test_data/catalogue_template.json.erb'

def random_record(model)
  model.order(Sequel.lit('RANDOM()')).first
end

def random(max)
  rand(max).to_i + 1
end

n_users = 5
n_tags = 8
n_graphics = 5
n_taggings = 15

puts "creating users ..."
(1..n_users).each do |index|
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name

  # bypass auth
  User.create(
      email: Faker::Internet.email,
      display_name: (random(10) > 9 ? "xxX" + Faker::Games::DnD.klass + "Xxx" : "") + first_name + "_"+ (random(10) < 7 ? last_name : Faker::Ancient.hero) + "_" + random(100).to_s[0..31],
  )

  User[index].add_address(
      city: Faker::Address.city,
      zip: Faker::Address.zip[0..4],
      street: Faker::Address.street_name,
      house_number: random(40),
      is_invoice_addr: false,
      country: "DEU",
      first_name: first_name,
      last_name: last_name,
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
  (0..random(2)).each do |j|
    variant = graphic.add_variant(
        title: j == 1 ? 'Basis' : Faker::Color.color_name + " " + Faker::Restaurant.name,
        derived_from: j == 0 ? nil : 0,
        graphic_format: rand > 0.7 ? "a3" : "a4",
        graphic_landscape: rand > 0.7,
        braille_format: "a4",
        graphic_no_of_pages: random(9),
        braille_no_of_pages: random(7),
        medium: 'swell',
        braille_system: %w(de-de-g0.utb de-de-g1.ctb de-de-g2.ctb).sample,
        description: Faker::Lorem.paragraph(sentence_count: [6,8,10,14,20].sample)
    )

    (1..random(3)).each do |k|
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