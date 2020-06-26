class Address < Sequel::Model
  many_to_one :user
  one_to_one :invoice
  one_to_one :shipment

  def validate
    super
    if (!company_name || company_name.empty?) && (!last_name || last_name.empty?)
      errors.add(:last_name, 'last name or company name required')
    end
  end
end
