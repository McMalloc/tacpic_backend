# rodauth related configurations

Tacpic.plugin :rodauth, json: :only, csrf: :route_csrf do
  login_required_error_status 401
  enable :login, :logout, :jwt, :create_account, :reset_password # , :jwt_cors#, :session_expiration

  # translate do |key|
  #   # send the keys to client without default translation, frontend is doing i18n work
  #   return key.to_s
  # end

  # AUTH EMAIL CONFIG
  unless ENV['RACK_ENV'] == 'test'
    enable :verify_account

    after_verify_account do
      response.write @account.to_json
    end

    verify_account_email_subject { "tacpic: #{I18n.t('verify_account.subject')}" }
    verify_account_email_body { SMTP.render(:verify_account, { url: verify_account_email_link }) }
  end

  reset_password_email_subject { "tacpic: #{I18n.t('reset.subject')}" }
  reset_password_email_body { SMTP.render(:reset_password, { url: reset_password_email_link }) }

  before_reset_password { I18n.locale = request.headers['Accept-Language'].to_sym }

  send_email do |email|
    email.content_type 'text/html; charset=UTF-8'
    super email
  end
  email_from { "#{I18n.t('verify_account.from')}@tacpic.de" }

  accounts_table :users
  jwt_secret ENV.delete('TACPIC_SESSION_SECRET')
  # max_session_lifetime 86400
  after_login do
    response.write @account.to_json
  end

  before_create_account do
    @account[:display_name] = request.params['display_name'] unless request.params['display_name'].empty?
    @account[:newsletter_active] = request.params['newsletter_active']

    I18n.locale = request.headers['Accept-Language'].to_sym

    raise AccountError, 'not whitelisted' unless
        File.open(File.join(ENV['APPLICATION_BASE'], 'config/whitelist.txt'))
            .read.split("\n").include? @account[:email]

    raise AccountError, 'display name already in use' unless
        User.find(display_name: request[:display_name]).nil?

    @account[:created_at] = Time.now.to_s
  end
end
