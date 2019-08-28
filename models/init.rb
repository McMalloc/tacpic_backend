require 'sequel'

module Store
  def self.init
    Dir.glob('./models/*.rb').each { |file| require file }
  end
end


