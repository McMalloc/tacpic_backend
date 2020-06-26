require 'prawn'

class Invoice < Sequel::Model
  one_to_one :address
  many_to_many :order_items, join_table: :invoice_items
  one_to_many :payments

  def after_create
    super
    self.generate_pdf
  end

  def generate_pdf
    Prawn::Document.generate("implicit.pdf") do
      logo = "#{ENV['APPLICATION_BASE']}/tacpic_backend/assets/tacpic_logo.png"
      image logo, :at => [50,450], :width => 450
      text "Hello World"
    end
  end
end
