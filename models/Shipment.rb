class Shipment < Sequel::Model
  one_to_one :address
  one_to_many :shipped_items

  def generate_shipping_receipt_pdf
    Prawn::Document.generate("implicit.pdf") do
      logo = "#{ENV['APPLICATION_BASE']}/tacpic_backend/assets/tacpic_logo.png"
      image logo, :at => [50,450], :width => 450
      text "Hello World"
    end
  end
end
