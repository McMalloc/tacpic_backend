require 'mail'
require 'singleton'

options = { :address              => "smtp.gmail.com",
            :port                 => 587,
            :domain               => 'your.host.name',
            :user_name            => '<username>',
            :password             => '<password>',
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

Mail.defaults do
  delivery_method :smtp, options
end

module SMTP
  class BaseMail
    include Singleton
    SMTP_SERVER = ENV['SMTP_SERVER']
    SMTP_PORT = ENV['SMTP_PORT']
    SMTP_USER = ENV['SMTP_USER']
    SMTP_HELOHOST = ENV['SMTP_HELOHOST']
    SMTP_PASSWORD = ENV.delete('SMTP_PASSWORD')

    ORDER_CONFIRM_TEMPLATE = ERB.new File.read("#{ENV['APPLICATION_BASE']}/services/mail/mail_order_confirm_template.erb")

    def initialize
      @client = Net::SMTP.new SMTP_SERVER, SMTP_PORT.to_i
      @client.enable_starttls
    end

    def send(message, to, from)
      @client.start(SMTP_HELOHOST, SMTP_USER, SMTP_PASSWORD, :login) do
        @client.send_message message, from, to
      end
    end

    def send_order_confirm(to)
      self.send(
          ORDER_CONFIRM_TEMPLATE.result_with_hash(to: to, subject: 'RE: Test'),
          to,
          'info@tacpic.de'
      )
    end
  end

  class Mail
    def initialize
      client = SMTPClient.instance
    end


  end
end