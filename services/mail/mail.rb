require 'mail'
require 'singleton'

module SMTP
  LAYOUT = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/layout.html.erb")
  def self.layout(params)
    LAYOUT.result_with_hash(params)
  end
  ORDER_CONFIRM_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/order_confirmation_template.erb")
  def self.order_confirm(params)
    ORDER_CONFIRM_TEMPLATE.result_with_hash(params)
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

    def send_order_confirmation(recipient, invoice_number, invoice_filepath)
      unless ENV["RACK_ENV"] == 'test'
        Mail.deliver do
          from     'info@tacpic.de'
          to       recipient
          subject  "Ihre Bestellung #{invoice_number}"
          body     ORDER_CONFIRM_TEMPLATE.result_with_hash({})
          add_file invoice_filepath
        end
      end
    end

    def send_quote_confirmation(recipient, quote_id, items)
      unless ENV["RACK_ENV"] == 'test'
        Mail.deliver do
          from     'info@tacpic.de'
          to       recipient
          subject  "Ihre Anfrage #{quote_id}"
          body     ORDER_CONFIRM_TEMPLATE.result_with_hash({items: items})
        end
      end
    end
  end
end