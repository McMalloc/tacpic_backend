require 'sequel'

# https://github.com/jeremyevans/sequel-annotate
module Store
  def self.init
    %w[User
    Account
    Product
    Graphic
    Variant
    Version
    Tag
    List
    Fav
    Download
    Address
    Order
    OrderItem
    Shipment
    ShippedItem
    Invoice
    InvoiceItem
    Payment
    Tagging
    UserLayout
    Annotation
    Comment
    Post
    Vote
    Request
    Proposal
    RequestTagging
    Approval
    RequestVote
    Captcha].each { |file| require_relative "./#{file}" }
  end
end


