require 'sequel'
Sequel.extension :symbol_as
# https://github.com/jeremyevans/sequel-annotate
module Store
  def self.init
    %w[User
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
    Taxonomy
    UserLayout
    Annotation
    Comment
    Post
    QuoteRequest
    Vote
    Request
    Proposal
    RequestTagging
    Approval
    RequestVote
    Captcha].each { |file| require_relative "./#{file}" }
  end
end

class Sequel::Model
  def before_create
    self.created_at ||= Time.now
    super
  end
end
