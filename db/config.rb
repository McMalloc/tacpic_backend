require 'sequel'

module Database
  # # method isn't loading env-specific settings since tests and development can happen on one machine with a simple database setup, while production instances use different config files anyway
  # def self.url(user, pw, dbname, host, mode)
  #   "mysql2://#{user}:#{pw}@#{host}/#{dbname}-#{mode}"
  # end

  def self.init(url)
    Sequel::Model.plugin :validation_class_methods
    Sequel.connect url
  end
end