Tacpic.hash_branch 'invoices' do |r|
    # GET /invoices/:id
    r.on Integer do |id|
      r.get 'pdf' do
        rodauth.require_authentication
        user_id = rodauth.logged_in?
        if user_id != Invoice[id].address.user_id && !UserRights.find(user_id: user_id).can_view_admin
          response.status = 403
          return {
            error: 'unauthorised'
          }
        end
        send_file Invoice[id].get_pdf_path, type: 'application/pdf'
    end
  end
end
