require_relative "./test_helper"

describe "Retrieve Tags" do
  it "should retrieve a single tag" do
    random_id = rand(Tag.count - 1)
    get "tags/#{random_id}"
    tag = JSON.parse(last_response.body)
    assert_equal tag['id'], random_id
    assert_equal 200, last_response.status
  end

  it "should retrieve the most popular tags" do
    get "tags"
    tags = JSON.parse(last_response.body)
    assert_equal 200, last_response.status
    assert_equal 10, tags.count
    expect(tags.first['count']).must_be :>=, tags.last['count']
  end

  it "should retrieve a custom amount of tags" do
    get "tags?limit=15"
    tags = JSON.parse(last_response.body)
    assert_equal 200, last_response.status
    assert_equal 15, tags.count
  end

  it "should retrieve tags based on string search" do
    term = "din"
    get "tags/search/" + term
    tags = JSON.parse(last_response.body)
    puts tags
    assert_equal 200, last_response.status
    assert tags.first['name'].downcase.include? term
  end
end
