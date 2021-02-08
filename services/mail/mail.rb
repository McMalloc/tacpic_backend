require 'mail'
# require 'singleton'

module SMTP
  MAIL_PATH = "#{ENV['APPLICATION_BASE']}/services/mail/".freeze
  LAYOUT = Helper.load_template(MAIL_PATH + 'layout.html.erb')

  def self.layout(params)
    LAYOUT.result_with_hash(params)
  end

  ORDER_CONFIRM_TEMPLATE = Helper.load_template(MAIL_PATH + 'order_confirmation_template.erb')

  def self.order_confirm(params)
    LAYOUT.result_with_hash({ body: ORDER_CONFIRM_TEMPLATE.result_with_hash(params) })
  end

  QUOTE_CONFIRM_TEMPLATE = Helper.load_template(MAIL_PATH + 'quote_confirmation_template.erb')
  VERIFY_ACCOUNT_TEMPLATE = Helper.load_template(MAIL_PATH + 'verify_account_template.erb')

  def self.verify_account(params)
    LAYOUT.result_with_hash({ body: VERIFY_ACCOUNT_TEMPLATE.result_with_hash(params) })
  end

  RESET_PASSWORD_TEMPLATE = Helper.load_template(MAIL_PATH + 'reset_password_template.erb')

  def self.reset_password(params)
    LAYOUT.result_with_hash({ body: RESET_PASSWORD_TEMPLATE.result_with_hash(params) })
  end

  PRODUCTION_JOB_TEMPLATE = Helper.load_template(MAIL_PATH + 'production_job_template.erb')

  def self.production_job(params)
    LAYOUT.result_with_hash({ body: PRODUCTION_JOB_TEMPLATE.result_with_hash(params) })
  end

  def self.render(template, params)
    send(template, params)
  rescue StandardError => e
    puts e.message
    e.message
  end

  class SendMail
    include Singleton

    def initialize; end

    def process_mail(mail)
      func_name = /`(.*?)'/.match(caller[0]).captures[0]

      if ENV['RACK_ENV'] == 'test'
        File.write("#{ENV['APPLICATION_BASE']}/tests/results/#{func_name}.txt", mail.to_s)
      else
        begin
          Thread.new do
            mail.deliver!
          end
        rescue StandardError
          puts 'Error'
          # TODO: error handling
        end
      end
    end

    def send_order_confirmation(recipient, invoice)
      order = Order[invoice.order_id]

      mail = Mail.new do
        from 'bestellung@tacpic.de'
        to recipient
        subject "Bestellbestätigung #{invoice.invoice_number}"
        html_part do
          content_type 'text/html; charset=UTF-8'
          body SMTP.order_confirm({
                                    invoice: invoice,
                                    order: order,
                                    invoice_address: invoice.address,
                                    shipping_address: Address[Shipment.find(order_id: order.id).address_id]
                                  })
        end

        add_file "#{ENV['APPLICATION_BASE']}/assets/AGB_tacpic.pdf"
      end

      process_mail(mail)
    end

    def send_production_job(order, zipfile_name)
      return if ENV['RACK_ENV'] == 'test'

      mail = Mail.new do
        from 'auftrag@tacpic.de'
        to ENV['PRODUCTION_ADDRESS']
        subject "Auftrag \##{order.id}"
        html_part do
          content_type 'text/html; charset=UTF-8'
          body SMTP.production_job({
                                     order_items: order.order_items.map(&:values),
                                     finalise_link: order.get_finalise_link
                                   })
        end

        add_file content: File.read(zipfile_name),
                 filename: "#{order.created_at.strftime('%Y-%m-%d')} Dateien für Bestellung Nr. #{order.id}.zip"
      end

      process_mail(mail)
    end

    def send_invoice_to_accounting(invoice)
      mail = Mail.new do
        from 'auftrag@tacpic.de'
        to ENV['ACCOUNTING_ADDRESS']
        subject "Rechnung \##{invoice.id}"
        body '-'

        add_file invoice.get_pdf_path
      end

      process_mail(mail)
    end

    def send_quote_confirmation(recipient, quote_id, items)
      mail = Mail.new do
        from 'info@tacpic.de'
        to recipient
        subject "Ihre Anfrage #{quote_id}"
        body ORDER_CONFIRM_TEMPLATE.result_with_hash({ items: items })
      end

      process_mail(mail)
    end
  end
end
