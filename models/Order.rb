class Order < Sequel::Model
  many_to_one :user
  one_to_many :shipped_items
  one_to_many :invoices
  one_to_many :shipments
  one_to_many :order_items

  # get a hash to finalise order via link
  def get_hash
    Digest::MD5.hexdigest created_at.to_s + id.to_s
  end

  def get_finalise_link
    "#{ENV['API_HOST']}/orders/#{id}/finalise?hash=#{get_hash}"
  end

  def get_postage_item
    order_items.find { |item| item.product_id.include? 'postage' }
  end

  def generate_documents
    invoices.last.generate_invoice_pdf
    shipments.last.generate_shipping_pdf unless invoices.last.address_id == shipments.last.address_id
  end

  def send_job
    job = Job.new(self)
    job.send_mail
    update(status: CONSTANTS::ORDER_STATUS::TRANSFERED)
  end

  def send_order_confirmation
    attached_files = order_items
                     .filter { |item| item.product_id == 'graphic_nobraille' || item.product_id == 'graphic' }
                     .map { |item| Variant[item.content_id].get_rtf(path_only: true) }

    SMTP::SendMail.instance.send_order_confirmation(
      User[user_id].email,
      invoices.last, self, attached_files
    )
  end
end
