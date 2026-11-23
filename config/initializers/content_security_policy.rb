
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.font_src        :self
    policy.img_src         :self, :data
    policy.object_src      :none
    policy.script_src      :self
    policy.style_src       :self
    policy.connect_src     :self
    policy.base_uri        :self
    policy.frame_ancestors :self
  end

  config.content_security_policy_nonce_generator = lambda do |request|
    request.session[:csp_nonce] ||= SecureRandom.base64(16)
  end
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
