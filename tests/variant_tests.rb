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
    graphic_data = File.read('tests/test_data/new_graphic.json')
    post 'graphics', graphic_data
    assert_equal 201, last_response.status

    default_variant_id = JSON.parse(last_response.body)['default_variant']['id']
    assert File.size?("files/original-#{default_variant_id}.svg") > 0
    assert File.size?("public/thumbnails/thumbnail-#{default_variant_id}-sm.png") > 0
    assert File.size?("public/thumbnails/thumbnail-#{default_variant_id}-xl.png") > 0
  end

  it "should update a variant with a new version" do
    version_data = File.read('tests/test_data/new_version.json')
    variant_id = JSON.parse(version_data)['variant_id']
    number_of_versions = $db[:versions].all.length
    post "variants/#{variant_id}", version_data

    puts last_response.body
    assert_equal 201, last_response.status
    assert_equal number_of_versions+1, $db[:versions].all.length
    assert File.size?("files/original-#{variant_id}.svg") > 0
    assert File.size?("public/thumbnails/thumbnail-#{variant_id}-sm.png") > 0
    assert File.size?("public/thumbnails/thumbnail-#{variant_id}-xl.png") > 0
  end

  it "should create a new variant for a graphic" do
    variant_data = File.read('tests/test_data/new_variant.json')
    number_of_versions = $db[:versions].all.length
    number_of_variants = $db[:variants].all.length
    post 'variants', variant_data

    puts last_response.body
    assert_equal 201, last_response.status
    variant_id = JSON.parse(last_response.body)['variant_id']
    assert_equal number_of_versions+1, $db[:versions].all.length
    assert_equal number_of_variants+1, $db[:variants].all.length
    assert File.size?("files/original-#{variant_id}.svg") > 0
    assert File.size?("public/thumbnails/thumbnail-#{variant_id}-sm.png") > 0
    assert File.size?("public/thumbnails/thumbnail-#{variant_id}-xl.png") > 0
  end
end
