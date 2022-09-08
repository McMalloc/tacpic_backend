# rodauth related configurations

Tacpic.plugin :rodauth, json: :only, csrf: :route_csrf do
  login_required_error_status 401
  enable  :login, 
          :logout, 
          :jwt,
          :create_account,
          :change_login,
          :change_password,
          :verify_login_change,
          :reset_password # , :jwt_cors#, :session_expiration

  translate do |key, default|
    # send the keys to client without default translation, frontend is doing i18n work
    key.to_s || default
  end

  # AUTH EMAIL CONFIG
  unless ENV['RACK_ENV'] == 'test'
    enable :verify_account

    after_verify_account do
      UserRights.create(
        user_id: @account[:id],
        can_order: true,
        can_hide_variants: false,
        can_view_admin: false,
        can_edit_admin: false
      )
      # response.write @account.to_json
    end

    verify_account_email_subject { "#{I18n.t('verify_account.subject')}" }
    verify_account_email_body { SMTP.render(:verify_account, { url: verify_account_email_link }) }
  end

  verify_login_change_email_subject { "#{I18n.t('verify_login_change.subject')}" }
  verify_login_change_email_body { SMTP.render(:verify_login_change, { url: verify_login_change_email_link }) }

  reset_password_email_subject { "#{I18n.t('reset.subject')}" }
  reset_password_email_body { SMTP.render(:reset_password, { url: reset_password_email_link }) }

  before_reset_password { I18n.locale = request.headers['Accept-Language'].to_sym }

  send_email do |email|
    email.content_type 'text/html; charset=UTF-8'
    super email
  end
  email_from { "#{I18n.t('verify_account.from')}@tacpic.de" }
  email_subject_prefix {  (ENV['RACK_ENV'] == 'development' ? "[DEV] " : "") + 'tacpic: ' }

  accounts_table :users
  jwt_secret ENV.delete('TACPIC_SESSION_SECRET')
  # max_session_lifetime 86400
  after_login do
    @account[:user_rights] = User[@account[:id]].user_rights.values unless User[@account[:id]].user_rights.nil?
    response.write @account.to_json
  end

  before_create_account do
    @account[:display_name] = request.params['display_name'] unless request.params['display_name'].empty?
    @account[:newsletter_active] = request.params['newsletter_active']

    I18n.locale = request.headers['Accept-Language'].to_sym unless request.headers['Accept-Language'].nil?

    raise AccountError, 'display name already in use' unless
        User.find(display_name: request[:display_name]).nil?

    @account[:created_at] = Time.now.to_s
  end
end
