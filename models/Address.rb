class Address < Sequel::Model
  many_to_one :user
  one_to_many :invoice
  one_to_many :shipment

  def validate
    super
    if (!company_name || company_name.empty?) && (!last_name || last_name.empty?)
      errors.add(:last_name, 'last name or company name required')
    end
  end
end
