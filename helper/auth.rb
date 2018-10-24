# require 'net/http'
# require 'uri'
require 'jwt'

module Auth
  def self.auth(token)
    hmac_secret = ENV['HMAC_SECRET']
    decoded_token = nil

    begin
      decoded_token = JWT.decode token[7..token.length],
                                 hmac_secret,
                                 true,
                                 { algorithm: 'HS256' }
    rescue => msg
      puts "#{msg.class}: #{msg.message}"
      halt 400, "#{msg.class}: #{msg.message}" #todo https://leastprivilege.com/2014/10/02/401-vs-403/
    end

    decoded_token.first['data']['user']['id'].to_i
  end
end


# def auth(token)
#   validation_uri = URI.parse("http://localhost/wordpress/wp-json/jwt-auth/v1/token/validate")
#   http = Net::HTTP.new(validation_uri.host, validation_uri.port)
#   request = Net::HTTP::Post.new(validation_uri.request_uri)
#   request['Authorization'] = token
#
#   decoded_token = JWT.decode token[7..token.length], hmac_secret, true, { algorithm: 'HS256' }
#
#   response = http.request(request)
#   if response.code.to_i == 200
#     true
#   else
#     false
#   end
# end