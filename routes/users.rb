Tacpic.route 'users' do |r|
  r.rodauth

  r.options do
    puts "-----------    OPTIONS"

    response["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
    response["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
    response["Access-Control-Allow-Origin"] = "*"
  end

  r.get do
    "eingeloggt?" + rodauth
  end
end