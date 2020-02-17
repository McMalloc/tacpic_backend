require_relative "./test_helper"
require "faker"

describe "Retrieve Variants" do
  before do
    header 'Authorization', 'Bearer ' + $token
    header 'Content-Type', 'application/json'
  end

  it "should retrieve a single variant" do
    random_id = rand(Variant.count - 1)
    get "variants/#{random_id}"
    tag = JSON.parse(last_response.body)
    assert_equal tag['id'], random_id
    assert_equal 200, last_response.status
  end

  it "should create a new graphic with default variant and version" do
    graphic_data = File.read('./tests/test_data/new_graphic.json')
    post 'graphics', graphic_data

    assert_equal 201, last_response.status
    # assert_equal 10, tags.count
    # expect(tags.first['count']).must_be :>=, tags.last['count']
  end

  it "should update a variant with a new version" do

  end

  it "should create a new variant for a graphic" do

  end
end
