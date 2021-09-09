require 'sequel'
require_relative '../constants'
Sequel.extension :symbol_as
Sequel::Model.plugin :validation_helpers
# https://github.com/jeremyevans/sequel-annotate
module Store
  def self.init
    %w[User
       UserRights
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
       InternetmarkeTransaction
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
    self.created_at ||= Time.now.strftime(CONSTANTS::ISO_DATETIME)
    super
  end
end
