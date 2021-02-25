require 'csv'

module CommerceData
  @@weights = {}
  CSV.parse(File.read('services/commerce/weights.csv'), headers: true).each do |row|
    @@weights[row[0].strip.to_sym] = row[1].to_i
  end
  @@prices = {}
  CSV.parse(File.read('services/commerce/base_prices.csv'), headers: true).each do |row|
    @@prices[row[0].strip.to_sym] = row[1].to_i
  end
  @@postages = {}
  CSV.parse(File.read('services/commerce/postage.csv'), headers: true).each do |row|
    @@postages[row[1].strip.to_sym] = {
      pplId: row[0].to_i,
      price: row[2].to_i,
      threshold: row[3].to_i
    }
  end
  @@products = {}
  CSV.parse(File.read('services/commerce/products.csv'), headers: true).each do |row|
    @@products[row[0].strip.to_sym] = {
      customisable: row[1],
      reduced_vat: row[2]
    }
  end

  @@taxes = {}
  CSV.parse(File.read('services/commerce/taxes.csv'), headers: true).each do |row|
    @@taxes[row[0].strip.to_sym] = row[1].to_i
  end

  def get_weight(id)
    @@weights[id.to_sym].to_i
  end

  def get_price(id)
    @@prices[id.to_sym].to_i
  end

  def get_postage(id)
    @@postages[id.to_sym]
  end

  def get_product(id)
    @@products[id.to_sym]
  end

  def get_taxrate(id)
    @@taxes[id.to_sym].to_i
  end
end
