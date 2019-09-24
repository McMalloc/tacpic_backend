require_relative "./test_helper"
require 'faker'

describe "creating valid graphics, variants and versions" do
  it "should create corresponding instances" do
    (0..10).each { |i|
      graphic = Graphic.create(
          description: Faker::Lorem.sentence, #
          title: Faker::Quote.famous_last_words,

      )

      (0..3).each { |j|
        variant = graphic.add_variant(
            title: Faker::Lorem.paragraph + " -- " + j.to_s,
            description: Faker::Lorem.sentence,
            long_description: Faker::Lorem.paragraph
        )

        (0..5).each { |k|
          rand_id = (rand*99 + 1).to_i
          user = User[rand_id]
          variant.add_version(
                               user_id: user.id,
                               document: "<svg tacpic:graphic_id=\"#{graphic.id}\" tacpic:variant_id=\"#{variant.id}\"></svg>"
          )
        }
      }
    }

    assert_equal 11, Graphic.all.length
    assert_equal 44, Variant.all.length
    assert_equal 264, Version.all.length
  end
end
