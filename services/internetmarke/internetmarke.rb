require 'savon'
require 'digest/md5'
require 'singleton'

def transform_address(address)
  formatted_address = {}
  if address[:company_name].nil?
    formatted_address[:name] = {
        personName: {
            firstname: address[:first_name],
            lastname: address[:last_name]
        },
    }
  else
    formatted_address[:name] = {
        companyName: {
            company: address[:company_name]
        },
    }
  end

  formatted_address[:address] = {
      street: address[:street],
      houseNo: address[:house_number],
      zip: address[:zip],
      city: address[:city],
      country: address[:country],
  }

  pp formatted_address
  formatted_address
end

module Internetmarke
  class Client
    include Singleton
    TIMEFORMAT = "%d%m%Y-%H%M%S"
    AUTH_TIMEOUT = ENV['INTERNETMARKE_AUTH_TIMEOUT'].to_i
    PARTNER_ID = ENV['PARTNER_ID']
    KEY_PHASE = ENV['KEY_PHASE']
    SCHLUESSEL_DPWN_MARKTPLATZ = ENV.delete('SCHLUESSEL_DPWN_MARKTPLATZ')
    INTERNETMARKE_USERNAME = ENV['INTERNETMARKE_USERNAME']
    INTERNETMARKE_PASSWORD = ENV.delete('INTERNETMARKE_PASSWORD')

    attr_accessor :wallet_balance
    attr_accessor :client

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
          "PARTNER_ID" => PARTNER_ID,
          "PARTNER_SIGNATURE" => get_hash(request_time)[0..7],
          "REQUEST_TIMESTAMP" => request_time,
          "KEY_PHASE" => KEY_PHASE,
          "SCHLUESSEL_DPWN_MARKTPLATZ" => SCHLUESSEL_DPWN_MARKTPLATZ
      }
    end

    # TODO Fehlerbehandlung
    def authenticate
      request_time = Time.now.to_f.round
      if @time_of_last_request.nil? || request_time - @time_of_last_request > AUTH_TIMEOUT
        @time_of_last_request = request_time
        response_auth = @client.call(
            :authenticate_user,
            soap_header: create_header,
            message: {
                username: INTERNETMARKE_USERNAME,
                password: INTERNETMARKE_PASSWORD
            })
        @token = response_auth.body[:authenticate_user_response][:user_token]
        @wallet_balance = response_auth.body[:authenticate_user_response][:wallet_balance]
        # if @wallet_balance < 200
        #   # TODO tu was, wenn die Portokasse unter einen Wert von XY€ rutscht
        # end
      end

      @token
    end
  end

  class Voucher
    attr_accessor :shop_order_id
    attr_accessor :file_url
    attr_accessor :sender_address
    attr_accessor :receiver_address
    attr_accessor :shipment_id

    def initialize(product, shipment_id, receiver_address, sender_address = {
            company_name: "tacpic UG (haftungsbeschränkt)",
            street: "Breitscheidtr.",
            house_number: "51",
            zip: "39114",
            city: "Magdeburg",
            country: "DEU",
        })
      if product == 1 || product == 11 || product == 21 || product == 31
        @product = product
      else
        @product = nil # not a valid product
      end

      @shipment_id = shipment_id
      @sender_address = sender_address
      @receiver_address = receiver_address
      @error = false
    end

    def save_voucher
      puts "Get from #{@file_link}"
      file_name = "#{ENV['APPLICATION_BASE']}/tacpic_backend/files/vouchers/voucher_#{@shipment_id}_#{@voucher_id}"
      system "wget '#{@file_link}' -O #{file_name}.zip"
      system "unzip #{file_name}.zip -d #{file_name}"
    end

    # @return [String]
    def get_voucher_path
      "#{ENV['APPLICATION_BASE']}/tacpic_backend/files/vouchers/voucher_#{@shipment_id}_#{@voucher_id}/0.png"
    end

    # TODO eventuell mehrere Marken pro Checkout?
    def checkout
      token = Client.instance.authenticate
      sender = transform_address(@sender_address)
      receiver = transform_address(@receiver_address)
      product = @product
      total = case product
              when 1
                80
              when 11
                95
              when 21
                155
              when 31
                270
              else
                -1 # invalid, will cancel operation
              end
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
                      voucherLayout: "AddressZone"
                  },
                  Total: total
        end

        @wallet_balance = response.body[:checkout_shopping_cart_png_response][:wallet_balance]
        @file_link = response.body[:checkout_shopping_cart_png_response][:link]
        @order_id = response.body[:checkout_shopping_cart_png_response][:shopping_cart][:shop_order_id]
        @voucher_id = response.body[:checkout_shopping_cart_png_response][:shopping_cart][:voucher_list][:voucher][:voucher_id]
        save_voucher
      rescue StandardError => e
        @error = true
        puts "Error in SOAP call: #{e.inspect}"
      end

    end
  end
end