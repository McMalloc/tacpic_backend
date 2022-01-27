Tacpic.hash_branch 'test' do |r|
  # GET /invoices/:id
  r.get 'internetmarke' do
    %{
        <S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/">
        <S:Header/>
        <S:Body>
        <CheckoutShoppingCartPNGResponse xmlns="http://oneclickforapp.dpag.de/V3">

        <link>https://internetmarke.deutschepost.de/PcfExtensionWeb/document?keyphase=1&amp;data=ORwfSjJTHkSUF4dj6mEfahg3St8HEBbf</link>
        <walletBallance>67354</walletBallance>
        <shoppingCart>
        <shopOrderId>718474626</shopOrderId>
        <voucherList>
        <voucher>
        <voucherId>A0011B1B9D0000008C71</voucherId>
        </voucher>
        </voucherList>
        </shoppingCart>
        </CheckoutShoppingCartPNGResponse>
        </S:Body>
        </S:Envelope>
    }
    
    File.read('services/internetmarke/wsdl.xml')
  end
end
