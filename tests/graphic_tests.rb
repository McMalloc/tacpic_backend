require_relative "./test_helper"

# describe "Graphic#after_save" do
#   it "should create an empty variant and version alongside the graphic" do
#     data = {
#         user_id: 0,
#         title: "a valid title for a graphic",
#         is_request: false
#     }
#     post 'graphics', data.to_json
#
#     assert_equal 202, last_response.status
#     puts $test_db[:graphics][0]
#   end
# end

describe "routes" do
  it "..." do
    data = {
        user_id: 0,
        title: "a valid title for a graphic",
        is_request: false
    }
    post 'graphics', data.to_json

    assert_equal 202, last_response.status
    puts $test_db[:graphics][0]
  end

  it "should get the correct graphic" do
    random_id = (rand 9).to_i
    get "graphic/#{random_id}"

    assert_equal 200, last_response.status
    assert_equal $test_db[:graphics][random_id].title, JSON.parse(last_response.body).title
  end

  it "should get all variants" do
    random_id = (rand 9).to_i
    get "graphic/#{random_id}/variants"

    # all variants should be available at once
    assert_equal 200, last_response.status
    assert_equal $test_db[:graphics][random_id].title, JSON.parse(last_response.body).title
  end
end
