Tacpic.hash_branch "", "internal" do |r|
  # route: GET /backend/users
  r.hash_routes(:internal)
end

require_relative './logging'