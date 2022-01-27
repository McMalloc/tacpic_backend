require 'savon'
require 'digest/md5'

def transform_address(address)
  formatted_address = {}
  formatted_address[:name] = if address[:company_name].nil? || address[:company_name].strip.empty?
                               {
                                 personName: {
                                   firstname: address[:first_name],
                                   lastname: address[:last_name]
                                 }
                               }
                             else
                               {
                                 companyName: {
                                   company: address[:company_name]
                                 }
                               }
                             end

  formatted_address[:address] = {
    street: address[:street],
    houseNo: address[:house_number],
    zip: address[:zip],
    city: address[:city],
    country: address[:country]
  }

  formatted_address
end

module Internetmarke
  class Client
    include Singleton
    TIMEFORMAT = '%d%m%Y-%H%M%S'.freeze
    AUTH_TIMEOUT = ENV['INTERNETMARKE_AUTH_TIMEOUT'].to_i
    PARTNER_ID = ENV['PARTNER_ID']
    KEY_PHASE = ENV['KEY_PHASE']
    SCHLUESSEL_DPWN_MARKTPLATZ = ENV.delete('SCHLUESSEL_DPWN_MARKTPLATZ')
    INTERNETMARKE_USERNAME = ENV['INTERNETMARKE_USERNAME']
    INTERNETMARKE_PASSWORD = ENV.delete('INTERNETMARKE_PASSWORD')

    attr_accessor :wallet_balance, :client

    def initialize
      @client = Savon.client(wsdl: ENV['INTERNETMARKE_WSDL_URL'])
      @oparations = @client.operations
      @time_of_last_request = nil
      @token = nil
    end

    def get_hash(request_time)
      Digest::MD5.hexdigest("#{PARTNER_ID}::#{request_time}::#{KEY_PHASE}::#{SCHLUESSEL_DPWN_MARKTPLATZ}")
    end

    def create_header
      request_time = Time.now.strftime(TIMEFORMAT)
      {
        'PARTNER_ID' => PARTNER_ID,
        'PARTNER_SIGNATURE' => get_hash(request_time)[0..7],
        'REQUEST_TIMESTAMP' => request_time,
        'KEY_PHASE' => KEY_PHASE,
        'SCHLUESSEL_DPWN_MARKTPLATZ' => SCHLUESSEL_DPWN_MARKTPLATZ
      }
    end

    # TODO: Fehlerbehandlung
    def authenticate
      $_logger.info '[INTERNETMARKE] Authenticating...'
      request_time = Time.now.to_f.round
      if @token.nil? || @time_of_last_request.nil? || request_time - @time_of_last_request > AUTH_TIMEOUT
        begin
          @time_of_last_request = request_time
          response_auth = @client.call(
            :authenticate_user,
            soap_header: create_header,
            message: {
              username: INTERNETMARKE_USERNAME,
              password: INTERNETMARKE_PASSWORD
            }
          )
          @token = response_auth.body[:authenticate_user_response][:user_token]
          @wallet_balance = response_auth.body[:authenticate_user_response][:wallet_balance]
          # if @wallet_balance < 200
          #   # TODO tu was, wenn die Portokasse unter einen Wert von XY€ rutscht
          # end
          $_logger.info '[INTERNETMARKE] OK   Authenticated: ' + @token.to_s
        rescue StandardError => e
          raise e
        end
      end

      @token
    end
  end

  class Voucher
    @@valid_pplsIds = CSV.parse(File.read('services/commerce/postage.csv'), headers: true).map do |row|
      { pplId: row[0].to_i, price: row[2].to_i }
    end
    attr_accessor :shop_order_id, :file_url, :file_name, :sender_address, :receiver_address, :wallet_balance, :error,
                  :context_id, :total, :voucher_id, :product

    def initialize(product, context_id, receiver_address, sender_address = {
      company_name: 'tacpic UG (haftungsbeschränkt)',
      street: 'Breitscheidtr.',
      house_number: '51',
      zip: '39114',
      city: 'Magdeburg',
      country: 'DEU'
    })
      @product = if @@valid_pplsIds.map { |row| row[:pplId] }.include? product
                   product
                 else
                   raise 'not a valid product'
                 end

      @sender_address = sender_address
      @receiver_address = receiver_address
      @context_id = context_id
      @error = nil
    end

    def save_voucher
      $_logger.info "[INTERNETMARKE] Get from #{@file_link}"
      @file_name = "voucher_#{@voucher_id}"
      file_path = File.join(ENV['APPLICATION_BASE'], 'files/vouchers', @file_name)
      # curl_cmd = "curl -o #{file_path}.zip -s -O #{@file_link}"
      wget_cmd = "wget '#{@file_link}' -O #{file_path}.zip"
      unzip_cmd = "unzip -o #{file_path}.zip -d #{file_path}"

      system wget_cmd
      system unzip_cmd
    end

    # TODO: eventuell mehrere Marken pro Checkout?
    def checkout
      if ENV['RACK_ENV'] == 'production'
        token = Client.instance.authenticate
        sender = transform_address(@sender_address)
        receiver = transform_address(@receiver_address)
        product = @product
        total = @@valid_pplsIds.find { |row| row[:pplId] == product }[:price].to_i
        @total = total
        $_logger.info '[INTERNETMARKE] Purchasing...'

        begin
          response = Client.instance.client.call :checkout_shopping_cart_png do
            soap_header Client.instance.create_header
            message userToken: token,
                    positions: {
                      productCode: product,
                      address: {
                        sender: sender,
                        receiver: receiver
                      },
                      voucherLayout: 'AddressZone'
                    },
                    Total: total
          end
          $_logger.info "[INTERNETMARKE] Transaction successfull #{response.to_json}"

          @wallet_balance = response.body[:checkout_shopping_cart_png_response][:wallet_ballance].to_i
          @file_link = response.body[:checkout_shopping_cart_png_response][:link]
          @shop_order_id = response.body[:checkout_shopping_cart_png_response][:shopping_cart][:shop_order_id]
          @voucher_id = response.body[:checkout_shopping_cart_png_response][:shopping_cart][:voucher_list][:voucher][:voucher_id]
        rescue StandardError => e
          logs = $_db[:backend_errors]
          $_logger.error "[INTERNETMARKE] #{e.class.name}: #{e.message}"

          SMTP::SendMail.instance.send_error_report(
            'Internetmarke', e, "for entity #{context_id}", nil
          )

          logs.insert(
            method: 'Internetmarke',
            path: 'na',
            params: 'na',
            frontend_version: 'na',
            backend_version: $_version,
            type: e.class.name,
            backtrace: e.backtrace,
            message: e.message,
            created_at: Time.now
          )
          @error = e
        ensure
          nil
        end
      else
        @wallet_balance = 2000
        @total = 999
        @file_link = 'http://localhost:9292/voucher_MOCK7A5C680000000BD7.zip'
        @shop_order_id = 'MOCK_SHOP_ID'
        @voucher_id = 'MOCK7A5C680000000BD7'
      end
      save_voucher
    end
  end
end
