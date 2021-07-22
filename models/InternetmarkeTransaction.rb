class InternetmarkeTransaction < Sequel::Model
  def get_voucher
    File.join(ENV['APPLICATION_BASE'], "files/vouchers", "voucher_#{voucher_id}", '0.png')
  end
end
