require 'net/http'
require 'uri'

class LegalAPI
  include Singleton
  attr_reader :index

  def init
    @auth_hash = {
        AccessToken: ENV.delete('HAENDLERBUND_ACCESS_TOKEN'),
        APIkey: ENV.delete('HAENDLERBUND_API_KEY'),
    }
    @endpoint = ENV['HAENDLERBUND_API_URL']

    @index = []
    unless ENV['RACK_ENV'] == 'development'
      @index = index
      @index.each do |id, title|
        save URI.encode(title), get_text(id)
      end
    end

  end

  def build_query(params)
    URI.encode_www_form(@auth_hash.merge(params))
  end

  def get_text(id)
    uri = URI(@endpoint)
    uri.query = build_query({
        did: id,
        mode: 'classes',
        lang: 'de'
    })
    res = Net::HTTP.get_response(uri)
    return res.body
  end

  def index
    uri = URI(@endpoint)
    uri.query = build_query({
                                mode: 'documents',
                                lang: 'de'
                            })
    res = Net::HTTP.get_response(uri)
    return JSON.parse(res.body)
  end


  def get_file(title)
    File.open(
        File.join(ENV['APPLICATION_BASE'], 'views/legal', title + '.inc')
    ).read
  end

  def save(filename, markup)
    File.write(
        File.join(ENV['APPLICATION_BASE'], 'views/legal', filename + '.inc'),
        markup
    )
  end
end