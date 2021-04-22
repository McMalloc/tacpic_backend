require_relative './test_helper'

describe 'Creating Graphics' do
  before do
    header 'Authorization', 'Bearer ' + $token
    header 'Content-Type', 'application/json'
  end

  after do
    pp last_response if last_response.status > 202
  end

  it 'should create a lot of graphics' do
    ENV['RACK_ENV'] = 'development'
    (0..20).each do |_i|
      test_data = replace_test_data(read_test_data('catch_all_graphic'), 'graphicTitle', Faker::Book.title)
      post 'graphics', test_data
    end
  end
end
