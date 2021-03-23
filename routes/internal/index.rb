Tacpic.hash_branch '', 'internal' do |r|
  # route: GET /backend/users

  rodauth.require_authentication
  user_id = rodauth.logged_in?

  unless User[user_id].role == ROLE::ADMIN
    response.status = 403
    return {
      error: 'unauthorised'
    }
  end

  r.hash_routes(:internal)
end

# the logging route isn't available via the /internal branch
# so not logged in users can still log frontend errors
require_relative './logging'
require_relative './users'
require_relative './variants'
