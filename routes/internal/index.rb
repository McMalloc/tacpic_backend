Tacpic.hash_branch "", "internal" do |r|
  # route: GET /backend/users
  rodauth.require_authentication
  user_id = rodauth.logged_in?
  r.hash_routes(:internal)
end

require_relative './logging'
