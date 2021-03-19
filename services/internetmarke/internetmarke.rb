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

  pp formatted_address
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
      puts '[SOAP] INFO Authenticating...'
      request_time = Time.now.to_f.round
      if @time_of_last_request.nil? || request_time - @time_of_last_request > AUTH_TIMEOUT
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
      end

      puts '[SOAP] OK   Authenticated: ' + @token.to_s

      @token
    end
  end

  class Voucher
    @@valid_pplsIds = CSV.parse(File.read('services/commerce/postage.csv'), headers: true).map do |row|
      { pplId: row[0].to_i, price: row[2].to_i }
    end
    attr_accessor :shop_order_id, :file_url, :file_name, :sender_address, :receiver_address, :wallet_balance, :error, :order_id

    def initialize(product, order_id, receiver_address, sender_address = {
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
                   nil # not a valid product
                 end

      @sender_address = sender_address
      @order_id = order_id
      @receiver_address = receiver_address
      @error = false
    end

    def save_voucher
      puts "Get from #{@file_link}"
      @file_name = "voucher_#{Time.now.strftime('%Y-%m-%d')}_#{@voucher_id}"
      file_path = File.join(ENV['APPLICATION_BASE'], 'files/vouchers', @file_name)
      system "wget '#{@file_link}' -O #{file_path}.zip"
      system "unzip #{file_path}.zip -d #{file_path}"
    end

    # TODO: eventuell mehrere Marken pro Checkout?
    def checkout
      token = Client.instance.authenticate
      sender = transform_address(@sender_address)
      receiver = transform_address(@receiver_address)
      product = @product
      total = @@valid_pplsIds.find { |row| row[:pplId] == product }[:price]

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

        @wallet_balance = response.body[:checkout_shopping_cart_png_response][:wallet_balance]
        @file_link = response.body[:checkout_shopping_cart_png_response][:link]
        @order_id = response.body[:checkout_shopping_cart_png_response][:shopping_cart][:shop_order_id]
        @voucher_id = response.body[:checkout_shopping_cart_png_response][:shopping_cart][:voucher_list][:voucher][:voucher_id]
        save_voucher
      rescue StandardError => e
        logs = $_db[:backend_errors]

        logs.insert(
          method: 'Internetmarke',
          path: 'na',
          params: order_id,
          frontend_version: 'na',
          backend_version: $_version,
          type: e.class.name,
          backtrace: e.backtrace,
          message: e.message,
          created_at: Time.now
        )
        @error = true
      end
    end
  end
end
