require 'erb'
graphic_fixture_renderer = ERB.new(File.read './tests/test_data/graphic_fixture.json.erb')

header 'Authorization', 'Bearer ' + $token
header 'Content-Type', 'application/json'

begin
  post '/graphics', graphic_fixture_renderer.result_with_hash({
                                                                  braille_no_of_pages: 2,
                                                                  graphic_no_of_pages: 4,
                                                                  braille_format: 'a3',
                                                                  graphic_format: 'a4',
                                                              })
  response = JSON.parse(last_response.body)

  $fixture1_version_id = response['first_version']['id']
  $fixture1_variant_id = response['default_variant']['id']
  $fixture1_graphic_id = response['created_graphic']['id']

  post '/graphics', graphic_fixture_renderer.result_with_hash({
                                                                  braille_no_of_pages: 5,
                                                                  graphic_no_of_pages: 8,
                                                                  braille_format: 'a4',
                                                                  graphic_format: 'a4',
                                                              })
  response = JSON.parse(last_response.body)
  $fixture2_version_id = response['first_version']['id']
  $fixture2_variant_id = response['default_variant']['id']
  $fixture2_graphic_id = response['created_graphic']['id']

  post '/graphics', graphic_fixture_renderer.result_with_hash({
                                                                  braille_no_of_pages: 10,
                                                                  graphic_no_of_pages: 2,
                                                                  braille_format: 'a4',
                                                                  graphic_format: 'a3',
                                                              })
  $fixture3_version_id = response['first_version']['id']
  $fixture3_variant_id = response['default_variant']['id']
  $fixture3_graphic_id = response['created_graphic']['id']
# pp last_response.body
rescue StandardError => e
  pp e
end

