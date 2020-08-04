require 'erb'
# graphic_fixture_renderer = ERB.new(File.read './tests/test_data/graphic_fixture_1.json.erb')
graphic_fixture_1 = File.read './tests/test_data/graphic_fixture_1.json'
graphic_fixture_2 = File.read './tests/test_data/graphic_fixture_2.json'
graphic_fixture_3 = File.read './tests/test_data/graphic_fixture_3.json'
graphic_fixture_4 = File.read './tests/test_data/graphic_fixture_4.json'

$test_user_id, $token = create_test_user('test@test.de', 'password').values
$test_foreign_user_id, $foreign_token = create_test_user('malloy@test.de', '12345678').values

header 'Authorization', 'Bearer ' + $token
header 'Content-Type', 'application/json'

begin
  $fixture_address_id = Address.create({
                                           user_id: $test_user_id,
                                           is_invoice_addr: false,
                                           street: "Breitscheidstr",
                                           house_number: "17",
                                           company_name: "",
                                           first_name: "Klaus",
                                           last_name: "Kleber",
                                           additional: nil,
                                           city: "Magdeburg",
                                           zip: "39444",
                                           state: "SAH",
                                           country: "DEU"
                                       }).id

  $fixture_disposable_address_id = Address.create({
                                                      user_id: $test_user_id,
                                                      is_invoice_addr: false,
                                                      street: "Dusselstraße",
                                                      house_number: "17",
                                                      company_name: "Quatschwerke AG",
                                                      first_name: "",
                                                      last_name: "",
                                                      additional: nil,
                                                      city: "Borken",
                                                      zip: "99999",
                                                      state: "RPF",
                                                      country: "DEU"
                                                  }).id

  $fixture_invoice_address_id = Address.create({
                                                   user_id: $test_user_id,
                                                   is_invoice_addr: true,
                                                   street: "Breitscheidstr",
                                                   house_number: "49",
                                                   company_name: "tacpic UG (hb)",
                                                   first_name: "",
                                                   last_name: "Gause",
                                                   additional: nil,
                                                   city: "Magdeburg",
                                                   zip: "39444",
                                                   state: "SAH",
                                                   country: "DEU"
                                               }).id

  $fixture_foreign_address_id = Address.create({
                                                   user_id: $test_foreign_user_id,
                                                   is_invoice_addr: false,
                                                   street: "Breitscheidstr",
                                                   house_number: "17",
                                                   company_name: "tacpic UG (hb)",
                                                   first_name: "Gundula",
                                                   last_name: "Gause",
                                                   additional: nil,
                                                   city: "Magdeburg",
                                                   zip: "39444",
                                                   state: "SAH",
                                                   country: "DEU"
                                               }).id

  post '/graphics', graphic_fixture_1
  response = JSON.parse(last_response.body)
  $fixture1_version_id = response['first_version']['id']
  $fixture1_variant_id = response['default_variant']['id']
  $fixture1_graphic_id = response['created_graphic']['id']

  post '/graphics', graphic_fixture_2
  response = JSON.parse(last_response.body)
  $fixture2_version_id = response['first_version']['id']
  $fixture2_variant_id = response['default_variant']['id']
  $fixture2_graphic_id = response['created_graphic']['id']

  post '/graphics', graphic_fixture_3
  response = JSON.parse(last_response.body)
  $fixture3_version_id = response['first_version']['id']
  $fixture3_variant_id = response['default_variant']['id']
  $fixture3_graphic_id = response['created_graphic']['id']

  post '/graphics', graphic_fixture_4
  response = JSON.parse(last_response.body)
  $fixture4_version_id = response['first_version']['id']
  $fixture4_variant_id = response['default_variant']['id']
  $fixture4_graphic_id = response['created_graphic']['id']

  $variant_1_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 1,
                     graphic_format: "a4",
                     graphic_landscape: false,
                     braille_no_of_pages: 0,
                     braille_format: "a4",
                     title: "1x a4 Grafik"
                 }).id
  $variant_2_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 1,
                     graphic_format: "a3",
                     graphic_landscape: false,
                     braille_no_of_pages: 0,
                     braille_format: "a4",
                     title: "1x a3 Grafik"
                 }).id
  $variant_3_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 0,
                     graphic_format: "a4",
                     graphic_landscape: false,
                     braille_no_of_pages: 1,
                     braille_format: "a4",
                     title: "1x Braille"
                 }).id
  $variant_4_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 2,
                     graphic_format: "a4",
                     graphic_landscape: false,
                     braille_no_of_pages: 7,
                     braille_format: "a4",
                     title: "2x a4 Grafik, 7x Braille"
                 }).id
  $variant_5_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 1,
                     graphic_format: "a3",
                     graphic_landscape: false,
                     braille_no_of_pages: 3,
                     braille_format: "a4",
                     title: "1x a3 Grafik, 3x Braille"
                 }).id
  $variant_6_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 5,
                     graphic_format: "a4",
                     graphic_landscape: false,
                     braille_no_of_pages: 0,
                     braille_format: "a4",
                     title: "5x a4 Grafik"
                 }).id
  $variant_7_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 5,
                     graphic_format: "a3",
                     graphic_landscape: true,
                     braille_no_of_pages: 0,
                     braille_format: "a4",
                     title: "5x a3 Grafik"
                 }).id
  $variant_8_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 0,
                     graphic_format: "a4",
                     graphic_landscape: false,
                     braille_no_of_pages: 5,
                     braille_format: "a4",
                     title: "5x Braille"
                 }).id
  $variant_9_id = Variant.create({
                     graphic_id: $fixture1_graphic_id,
                     graphic_no_of_pages: 0,
                     graphic_format: "a4",
                     graphic_landscape: false,
                     braille_no_of_pages: 30,
                     braille_format: "a4",
                     title: "30x Braille"
                 }).id

# pp last_response.body
rescue StandardError => e
  pp e
end