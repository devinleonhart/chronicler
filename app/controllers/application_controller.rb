class ApplicationController < ActionController::Base
  include Authentication

  private

  def text_param(name)
    value = params[name]
    value.is_a?(String) ? value.strip : ""
  end

  def list_param(name)
    Array(params[name]).grep(String)
  end
end
