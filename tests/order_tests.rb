require_relative "./test_helper"

describe "Creating Orders" do
  before do
    header "Authorization", "Bearer " + $token
    header "Content-Type", "application/json"
  end

  after do
    if last_response.status > 202
        pp last_response
    end
  end

  it "should create a new order" do
    test_data = read_test_data("order_1")
    post "orders", test_data
    assert_equal 201, last_response.status
    assert_equal 389 + 200, get_body(last_response)['total_gross']
  end
end
