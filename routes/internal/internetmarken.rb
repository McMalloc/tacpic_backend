Tacpic.hash_branch :internal, 'vouchers' do |r|
  r.is do
    r.get do
      InternetmarkeTransaction.all.map(&:values)
    end
  end

  r.on String do |voucher_id|
    r.is 'png' do
      r.get do
        send_file InternetmarkeTransaction.find(voucher_id: voucher_id).get_voucher,
                  type: 'image/png'
      end
    end
  end
end
