require_relative "./test_helper"

describe "User routes" do
  # it "should never spill a list of all users" do
  #   get 'users'
  #   assert !last_response.ok?
  # end
end

describe "Addresses" do
  before do
    header 'Authorization', 'Bearer ' + $token
    header 'Content-Type', 'application/json'
  end

  it "should delete/inactivate address with id #{$fixture_disposable_address_id}" do
    post "users/addresses/inactivate/#{$fixture_disposable_address_id}", {}
    assert_equal 204, last_response.status
    post "users/addresses/inactivate/#{$fixture_disposable_address_id}", {}
    assert_equal 204, last_response.status
    post "users/addresses/inactivate/#{$fixture_foreign_address_id}", {}
    assert_equal 403, last_response.status
  end

  it "should add new addresses" do
    addresses_count_before = $db[:addresses].where(user_id: $test_user_id).count
    data_shipping = {
        street: Faker::Address.street_name,
        house_number: (10001..99999).to_a.sample,
        additional: rand > 0.8 ? Faker::Address.community : nil,
        city: Faker::Address.city,
        last_name: Faker::Name.last_name,
        first_name: Faker::Name.first_name,
        country: Faker::Address.country_code_long,
        zip: Faker::Address.zip,
        state: ["S-A", "NRW"].sample,
    }
    data_invoice = {
        street: Faker::Address.street_name,
        house_number: (10001..99999).to_a.sample,
        company_name: Faker::Company.name,
        is_invoice_addr: true,
        additional: rand > 0.8 ? Faker::Address.community : nil,
        city: Faker::Address.city,
        country: Faker::Address.country_code_long,
        zip: Faker::Address.zip,
        state: ["S-A", "NRW"].sample,
    }
    data_invalid = {
        street: Faker::Address.street_name,
        house_number: (10001..99999).to_a.sample,
        is_invoice_addr: true,
        additional: rand > 0.8 ? Faker::Address.community : nil,
        city: Faker::Address.city,
        country: Faker::Address.country_code_long,
        zip: Faker::Address.zip,
        state: ["S-A", "NRW"].sample,
    }
    post 'users/addresses', data_shipping.to_json
    pp last_response.body
    assert_equal 201, last_response.status

    post 'users/addresses', data_invoice.to_json
    pp last_response.body
    assert_equal 201, last_response.status

    # post 'users/addresses', data_invalid.to_json
    # pp last_response.body
    # assert_equal 400, last_response.status

    addresses_count_after = $db[:addresses].where(user_id: $test_user_id).count
    assert_equal addresses_count_before + 2, addresses_count_after
  end

  it "should get all addresses" do
    get 'users/addresses'
    assert last_response.ok?
    pp last_response.body
  end
end

describe "Signup" do
  # it "should accept a valid signup request and create a user" do
  #   data = {
  #       email: "valid@example.com",
  #       password: "notSO_safe_PaSsWORd-3-1--7-8-",
  #       captcha: "heiß"
  #   }
  #   post 'user/new', data.to_json, "CONTENT_TYPE" => "application/json"
  #
  #   assert last_response.ok?
  # end
  #
  # it "should refuse an invalid sign up request and respond with a descriptive error message" do
  #   data = {
  #       email: "valid@example.com",
  #       password: "notSO_safe_PaSsWORd-3-1--7-8-",
  #       captcha: "wrong captcha"
  #   }
  #   post 'user/new', data.to_json, "CONTENT_TYPE" => "application/json"
  #
  #   assert last_response.ok?
  # end
end
