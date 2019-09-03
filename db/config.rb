require 'sequel'
require 'yaml'

module Database
  CONFIG = YAML::load_file(
      File.join(
          File.dirname(
              File.expand_path(__FILE__)), '../config.yml'))

  DB_MODES = %w{development production test}

  def self.url(mode)
    raise "Unsupported runtime mode: #{mode.inspect}" unless DB_MODES.include? mode.to_s
    "mysql2://#{CONFIG[mode]['DB_USER']}:#{CONFIG[mode]['DB_PASSWORD']}@#{CONFIG[mode]['DB_URL']}/#{CONFIG[mode]['DB_NAME']}-#{mode}"
  end

  def self.init (mode)
    Sequel.connect url(mode)
        # adapter: 'mysql2',
        # user: user,
        # host: 'localhost',
        # database: db,
        # password: pw
  end
end