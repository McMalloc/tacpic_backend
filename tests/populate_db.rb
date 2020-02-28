require_relative '../db/config'
require_relative '../models/init'
require_relative '../env.rb'
require "faker"
require "uuid"

$_db = Database.init ENV['TACPIC_DATABASE_URL']
Store.init

def random_record(model)
  model.order(Sequel.lit('RANDOM()')).first
end

def random(max)
  rand(max).to_i + 1
end

n_users = 10
n_tags = 10
n_graphics = 100
n_taggings = 800
uuid = UUID.new

puts "creating users ..."
# bypass auth
(1..n_users).each do
  $_db[:users].insert(
      role: 1,
      email: Faker::Internet.email,
      created_at: Time.now
  )
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

Tag.create(name: "din a4", taxonomy_id: 1) # ensure certain tags for testing

puts "creating graphics ..."
(1..n_graphics).each do |i|
  user = random_record(User)
  graphic = Graphic.create(
      # description: Faker::Lorem.sentence, #
      user_id: user.id,
      title: Faker::Quote.famous_last_words,
      description: Faker::Lorem.paragraph
  )

  puts "creating variants and versions for graphic no " + graphic.id.to_s + " ..."
  (1..random(4)).each do |j|
    variant = graphic.add_variant(
        title: Faker::Color.color_name + " " + Faker::Restaurant.name,
        derived_from: 0,
        width: 210,
        height: 297,
        medium: 'swell',
        braille_system: 'de-de-g2',
        description: Faker::Lorem.sentence
    )

    (1..random(5)).each do |k|
      user = random_record(User)
      variant.add_version(
          user_id: user.id,
          document: %Q{[
    {
      "name": "Seite 1",
      "text": false,
      "objects": [
        {
          "uuid": "#{uuid.generate}",
          "x": #{(1..180).to_a.sample},
          "y": #{(1..250).to_a.sample},
          "width": #{(1..50).to_a.sample},
          "height": #{(1..90).to_a.sample},
          "fill": "#{Faker::Color.hex_color}",
          "pattern": {
            "template": "#{["striped", "bigdots"].sample}",
            "angle": 0,
            "scaleX": 1,
            "scaleY": 1,
            "offset": true
          },
          "moniker": "Rechteck",
          "angle": #{(0..90).to_a.sample},
          "type": "rect"
        },
        {
          "uuid": "#{uuid.generate}",
          "x": #{(1..180).to_a.sample},
          "y": #{(1..250).to_a.sample},
          "width": #{(1..50).to_a.sample},
          "height": #{(1..90).to_a.sample},
          "fill": "#{Faker::Color.hex_color}",
          "pattern": {
            "template": "#{["striped", "bigdots"].sample}",
            "angle": 0,
            "scaleX": 1,
            "scaleY": 1,
            "offset": true
          },
          "moniker": "Rechteck",
          "angle": 0,
          "type": "rect"
        },
        {
          "uuid": "3f1fb36e-0b61-4781-9ae3-2a2b95e7ef66",
          "x": #{(1..180).to_a.sample},
          "y": #{(1..250).to_a.sample},
          "width": #{50},
          "height": #{50},
          "fill": "#{Faker::Color.hex_color}",
          "pattern": {
            "template": "#{["striped", "bigdots"].sample}",
            "angle": 0,
            "scaleX": 1,
            "scaleY": 1
          },
          "moniker": "Ellipse",
          "angle": 0,
          "type": "ellipse"
        }
      ]
    }
  ]}
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