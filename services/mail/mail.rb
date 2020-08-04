require 'mail'
require 'singleton'

module SMTP
  class SendMail
    include Singleton
    # SMTP_PASSWORD = ENV.delete('SMTP_PASSWORD')
    ORDER_CONFIRM_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/order_confirmation_template.erb")

    def initialize
      Mail.defaults do
        delivery_method :smtp, { address:              ENV['SMTP_SERVER'],
                                 port:                 ENV['SMTP_PORT'],
                                 domain:               ENV['SMTP_HELOHOST'],
                                 user_name:            ENV['SMTP_USER'],
                                 password:             ENV.delete('SMTP_PASSWORD'),
                                 authentication:       'login',
                                 enable_starttls_auto: true  }
      end
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
  end
end