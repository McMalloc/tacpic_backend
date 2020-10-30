require 'mail'
# require 'singleton'

module SMTP
  LAYOUT = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/layout.html.erb")

  def self.layout(params)
    LAYOUT.result_with_hash(params)
  end

  ORDER_CONFIRM_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/order_confirmation_template.erb")

  def self.order_confirm(params)
    LAYOUT.result_with_hash({body: ORDER_CONFIRM_TEMPLATE.result_with_hash(params)})
  end

  QUOTE_CONFIRM_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/quote_confirmation_template.erb")
  VERIFY_ACCOUNT_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/verify_account_template.erb")

  def self.verify_account(params)
    LAYOUT.result_with_hash({body: VERIFY_ACCOUNT_TEMPLATE.result_with_hash(params)})
  end

  RESET_PASSWORD_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/reset_password_template.erb")

  def self.reset_password(params)
    LAYOUT.result_with_hash({body: RESET_PASSWORD_TEMPLATE.result_with_hash(params)})
  end

  PRODUCTION_JOB_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/production_job_template.erb")

  def self.production_job(params)
    LAYOUT.result_with_hash({body: PRODUCTION_JOB_TEMPLATE.result_with_hash(params)})
  end

  def self.render(template, params)
    begin
      send(template, params)
    rescue StandardError => error
      puts error.message
      error.message
    end
  end

  class SendMail
    include Singleton

    def initialize
    end

    def send_order_confirmation(recipient, invoice)
      order = Order[invoice.order_id]
      unless ENV["RACK_ENV"] == 'test'
        Mail.deliver do
          from 'bestellung@tacpic.de'
          to recipient
          subject "Bestellbestätigung #{invoice.invoice_number}"
          html_part do
            content_type 'text/html; charset=UTF-8'
            body SMTP::order_confirm({
                                         invoice: invoice,
                                         order: order,
                                         invoice_address: invoice.address,
                                         shipping_address: Address[Shipment.find(order_id: order.id).address_id]
                                     })
          end
        end
      end
    end

    def send_production_job(order, zipfile_name)
      unless ENV["RACK_ENV"] == 'test'
        Mail.deliver do
          from 'auftrag@tacpic.de'
          to ENV['PRODUCTION_ADDRESS']
          subject "Auftrag \##{order.id}"
          html_part do
            content_type 'text/html; charset=UTF-8'
            body SMTP::production_job({
                                          order_items: order.order_items.map(&:values),
                                          finalise_link: order.get_finalise_link
                                      })
          end

          add_file content: File.read(zipfile_name), filename: "#{order.created_at.strftime("%Y-%m-%d")} Dateien für Bestellung Nr. #{order.id}.zip"
        end
      end
    end

    def send_invoice_to_accounting(invoice)
      Mail.deliver do
        from 'auftrag@tacpic.de'
        to ENV['ACCOUNTING_ADDRESS']
        subject "Rechnung \##{invoice.id}"
        body "-"

        add_file invoice.get_pdf_path
      end
    end

    def send_quote_confirmation(recipient, quote_id, items)
      unless ENV["RACK_ENV"] == 'test'
        Mail.deliver do
          from 'info@tacpic.de'
          to recipient
          subject "Ihre Anfrage #{quote_id}"
          body ORDER_CONFIRM_TEMPLATE.result_with_hash({items: items})
        end
      end
    end
  end
end