require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'

require "debugger"

class ControllerBase
  attr_reader :params, :req, :res

  @@form_authenticity_tokens ||= []

  def initialize(req, res, route_params = {})
    @req, @res = req, res
    @already_rendered = false
    session
    @params = Params.new(req, route_params)

    update_form_authenticity_tokens_array
  end

  def update_form_authenticity_tokens_array
    new_token = SecureRandom.urlsafe_base64(16)
    @@form_authenticity_tokens << new_token
    @@form_authenticity_tokens.shift if @@form_authenticity_tokens.count > 2
    @@form_authenticity_tokens
  end

  def render_content(content, type)
    raise "error" if already_rendered?
    @already_rendered = true

    @res.body = content
    @res.content_type = type
    binding

    @res

    session.store_session(@res)
  end

  # helper method to alias @already_rendered
  def already_rendered?
    @already_rendered
  end

  # set the response status code and header
  def redirect_to(url)
    raise "error" if already_rendered?
    @already_rendered = true

    @res.status = 302
    @res["location"] = url

    session.store_session(@res)
  end

  def form_authenticity_tokens
    @@form_authenticity_tokens
  end

  def authenticity_token_is_valid?
    return true if @req.request_method.downcase == "get"

    form_authenticity_tokens
      .include?(params[:authenticity_token])
  end

  def render(template_name)
    path =
      "views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    erb_template = ERB.new(File.read(path))
    erb_result = erb_template.result(binding)

    render_content(erb_result, "text/html")
  end

  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  def invoke_action(name)
    self.send(name)
    render(name) unless already_rendered?
  end
end
