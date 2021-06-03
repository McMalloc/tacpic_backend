require 'mail'
require_relative '../../helper/functions'
# require 'singleton'

module SMTP
  def self.init
    Mail.defaults do
      delivery_method :smtp, { address: ENV['SMTP_SERVER'],
                               port: ENV['SMTP_PORT'],
                               domain: ENV['SMTP_HELOHOST'],
                               user_name: ENV['SMTP_USER'],
                              #  password: ENV['SMTP_PASSWORD'],
                               password: ENV.delete('SMTP_PASSWORD'),
                               authentication: 'plain',
                               ssl: true }
    end
  end

  MAIL_PATH = "#{ENV['APPLICATION_BASE']}/services/mail/".freeze
  LAYOUT = Helper.load_template(MAIL_PATH + 'layout.html.erb')
  PRODUCTION_JOB_TEMPLATE = Helper.load_template(MAIL_PATH + 'production_job_template.erb')
  ORDER_CONFIRM_TEMPLATE = Helper.load_template(MAIL_PATH + 'order_confirmation_template.erb')
  QUOTE_CONFIRM_TEMPLATE = Helper.load_template(MAIL_PATH + 'quote_confirmation_template.erb')
  VERIFY_ACCOUNT_TEMPLATE = Helper.load_template(MAIL_PATH + 'verify_account_template.erb')
  RESET_PASSWORD_TEMPLATE = Helper.load_template(MAIL_PATH + 'reset_password_template.erb')
  ERROR_REPORT_TEMPLATE = Helper.load_template(MAIL_PATH + 'error_report_template.erb')

  def self.layout(params)
    LAYOUT.result_with_hash(params)
  end

  def self.order_confirm(params)
    LAYOUT.result_with_hash({ body: ORDER_CONFIRM_TEMPLATE.result_with_hash(params) })
  end

  def self.error_report(params)
    LAYOUT.result_with_hash({ body: ERROR_REPORT_TEMPLATE.result_with_hash(params) })
  end

  def self.verify_account(params)
    LAYOUT.result_with_hash({ body: VERIFY_ACCOUNT_TEMPLATE.result_with_hash(params) })
  end

  def self.reset_password(params)
    LAYOUT.result_with_hash({ body: RESET_PASSWORD_TEMPLATE.result_with_hash(params) })
  end

  def self.production_job(params)
    LAYOUT.result_with_hash({ body: PRODUCTION_JOB_TEMPLATE.result_with_hash(params) })
  end

  def self.render(template, params)
    # invoke method from above with ruby's send
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
        rescue StandardError => e
          logs = $_db[:backend_errors]
          logs.insert(
            method: 'SMTP',
            path: 'na',
            params: mail.inspect,
            frontend_version: 'na',
            backend_version: $_version,
            type: e.class.name,
            backtrace: e.backtrace,
            message: e.message,
            created_at: Time.now
          )

          $_logger.error "[SMTP] #{e.class.name}: #{e.message}"
          # TODO: error handling
        end
      end
    end

    def send_order_confirmation(recipient, invoice, filepaths)
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

        filepaths.each { |path| add_file path }
        add_file "#{ENV['APPLICATION_BASE']}/assets/AGB_tacpic.pdf"
        add_file "#{ENV['APPLICATION_BASE']}/assets/Muster-Widerrufsformular.pdf"
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

    def send_error_report(component, error, context, attachment)
      return if ENV['RACK_ENV'] == 'test'
      mail = Mail.new do
        from 'appserver@tacpic.de'
        to ENV['WEBMASTER_MAIL']
        subject "Error in #{component}: #{error.message}"
        html_part do
          content_type 'text/html; charset=UTF-8'
          body SMTP.error_report({
                                     component: component,
                                     type: error.class.name,
                                     message: error.message,
                                     backtrace: error.backtrace.join("\n"),
                                     context: context
                                   })
        end
      end

      add_file content: File.read(attachment) unless attachment.nil?

      process_mail(mail)
    end

    def send_invoice_to_accounting(invoice)
      mail = Mail.new do
        from 'buchhaltung@tacpic.de'
        to ENV['ACCOUNTING_ADDRESS']
        subject "[Buchhaltung] Rechnung \##{invoice.id}"
        body 'Für die Buchhaltung.'

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
