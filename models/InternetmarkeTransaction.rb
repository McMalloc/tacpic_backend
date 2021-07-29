class InternetmarkeTransaction < Sequel::Model
  def after_create
    super
    if balance < 2000
      SMTP::SendMail.instance.send_info('Kontostand der Portokasse knapp', "Stand mit Transaktions-ID #{id}: #{Helper.format_currency(balance)}")
    end
  end
  
  def get_voucher
    File.join(ENV['APPLICATION_BASE'], "files/vouchers", "voucher_#{voucher_id}", '0.png')
  end
end
