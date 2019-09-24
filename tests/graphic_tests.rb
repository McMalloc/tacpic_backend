require_relative "./test_helper"
require "faker"

describe "Versions" do
  it "should create an graphic, variant and version if the graphic doesn't exist already" do
    data = {
            user_id: 0,
            document: "<svg tacpic:graphic_id=\"\" tacpic:variant_id=\"\"></svg>",
            # no variant_id means: create a new variant
            # only if the user decided that a new Graphic will be created and the client queried additional info
            title: "a valid title for a graphic",
            description: Faker::Lorem.paragraph
        }
    post 'versions', data.to_json


    assert_equal 202, last_response.status
    $db[:versions].first
    puts $db[:graphics][0]
  end
end


describe "routes" do
  it "..." do
    title = "a valid title for a graphic"
    data = {
        user_id: 0,
        title: title,
        is_request: false
    }
    post 'graphics', data.to_json

    assert_equal 202, last_response.status
    assert_equal title, $db[:graphics].where(id: 1).get(:title)
  end

  it "should get the correct graphic" do
    random_id = (rand 9).to_i
    get "graphic/#{random_id}"

    assert_equal 200, last_response.status
    assert_equal $db[:graphics][random_id].title, JSON.parse(last_response.body).title
  end

  it "should get all variants" do
    random_id = (rand 9).to_i
    get "graphic/#{random_id}/variants"

    # all variants should be available at once
    assert_equal 200, last_response.status
    assert_equal $db[:graphics][random_id].title, JSON.parse(last_response.body).title
  end
end
