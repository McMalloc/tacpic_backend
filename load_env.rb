require 'yaml'

def parse_config
  YAML::load_file(
      File.join(
          File.dirname(
              File.expand_path(__FILE__)), './env.yml'))
end