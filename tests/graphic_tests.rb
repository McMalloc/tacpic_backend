require_relative "./test_helper"
require "faker"

describe "Versions" do
  # it "should create an graphic, variant and version if the graphic doesn't exist already" do
  #   data = {
  #       user_id: 0,
  #       document: "<svg tacpic:graphic_id=\"\" tacpic:variant_id=\"\"></svg>",
  #       # no variant_id means: create a new variant
  #       # only if the user decided that a new Graphic will be created and the client queried additional info
  #       title: "a valid title for a graphic",
  #       description: Faker::Lorem.paragraph
  #   }
  #   post 'versions', data.to_json
  #
  #   assert_equal 202, last_response.status
  #   $db[:versions].first
  #   puts $db[:graphics][0]
  # end
end

describe "Retrieve Graphics" do
  it "should retrieve a list graphics / variants that match specific tags" do
    random_tag_1 = rand 19
    random_tag_2 = rand 19
    random_tag_3 = rand 19

    query_string = "graphics?tags=#{random_tag_1},#{random_tag_2},#{random_tag_3}&limit=10"
    puts query_string
    get query_string
    graphics = JSON.parse(last_response.body)
    assert_equal 200, last_response.status
    assert_equal 10, graphics.length

    # title = "a valid title for a graphic"
    # data = {
    #     user_id: 0,
    #     title: title,
    #     is_request: false
    # }
    # post 'graphics', data.to_json
    #
    # assert_equal 202, last_response.status
    # assert_equal title, $db[:graphics].where(id: 1).get(:title)
  end

  it "should get a single graphic" do
    random_id = (rand 9).to_i
    get "graphics/#{random_id}"

    assert_equal 200, last_response.status
    assert_equal $db[:graphics].where(id: random_id).get(:title), JSON.parse(last_response.body)['graphic']['title']
  end
end
