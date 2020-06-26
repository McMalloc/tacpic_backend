require 'csv'

# module for loading fixture data, e.g. data that will not change frequently and changes
# will be accompanied by discussions, so no need for dynamically loading it from the database
# everytime some price is calculated
module Fix
  @prices = {}
  @taxes = {}
  @weights = {}
  @postages = {}

  def self.init
    CSV.parse(File.read('commerce/base_prices.csv'), headers: true).each do |row|
      @prices[row[0].to_sym] = row[1].to_i
    end

    CSV.parse(File.read('commerce/taxes.csv'), headers: true).each do |row|
      @taxes[row[0].to_sym] = row[1].to_i
    end

    CSV.parse(File.read('commerce/weights.csv'), headers: true).each do |row|
      @weights[row[0].to_sym] = row[1].to_i
    end

    CSV.parse(File.read('commerce/postage.csv'), headers: true).each do |row|
      @postages[row[1].to_sym] = row[0].to_i
    end
  end

  def self.base_price(product)
    @prices[product.to_sym]
  end

  def self.get_postage(product_name)
    @postages[product_name.to_sym]
  end

  def self.weights(artifact)
    @weights[artifact.to_sym]
  end

  def self.tax(region, type, reduced = false)
    @taxes["#{region}_#{reduced ? "reduced_" : ""}#{type}".to_sym]
  end
end