require_relative "./test_helper"

describe "Creating Graphics" do
  before do
    header "Authorization", "Bearer " + $token
    header "Content-Type", "application/json"
  end

  after do
    if last_response.status > 202
        pp last_response
    end
  end

  it "should create a new graphics, variants and versions" do
    test_data = read_test_data("new_graphic")
    post "graphics", test_data
    assert_equal 201, last_response.status

    test_data = read_test_data("new_variant")
    post "variants", test_data
    assert_equal 201, last_response.status

    test_data = read_test_data("new_version")
    post "variants/2", test_data
    assert_equal 201, last_response.status

    test_data = read_test_data("new_graphic_from_variant")
    post "graphics", test_data
    assert_equal 201, last_response.status

    test_data = read_test_data("catch_all_graphic")
    post "graphics", test_data
    file = get_body(last_response)['first_version']['file_name']
    assert_equal 201, last_response.status
    assert_equal 0, compare_images(file + '-RASTER-p0', 'catch_all_p0')
    assert_equal 0, compare_images(file + '-RASTER-p1', 'catch_all_p1')
  end
end
