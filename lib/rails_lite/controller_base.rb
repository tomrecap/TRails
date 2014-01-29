require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'

require "debugger"

class ControllerBase
  attr_reader :params, :req, :res

  @@form_authenticity_tokens ||= []

  # setup the controller
  def initialize(req, res, route_params = {})
    @req, @res = req, res
    @already_rendered = false
    session
    @params = Params.new(req, route_params)

    update_form_authenticity_tokens_array
    # @@form_authenticity_token = SecureRandom.urlsafe_base64(16)
  end

  def update_form_authenticity_tokens_array
    new_token = SecureRandom.urlsafe_base64(16)
    @@form_authenticity_tokens << new_token
    @@form_authenticity_tokens.shift if @@form_authenticity_tokens.count > 2
    @@form_authenticity_tokens
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
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

  # def render_content(content, type)
  # end

  # def form_authenticity_token
  #   @@form_authenticity_token
  # end

  def form_authenticity_tokens
    @@form_authenticity_tokens
  end

  def authenticity_token_is_valid?
    return true if @req.request_method.downcase == "get"

    form_authenticity_tokens
      .include?(params[:authenticity_token])
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    path =
      "views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    erb_template = ERB.new(File.read(path))
    erb_result = erb_template.result(binding)

    render_content(erb_result, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  def flash
    @flash ||= Flash.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    # unless authenticity_token_is_valid?
    #   raise "authenticity token is missing or invalid."
    # end

    self.send(name)

    render(name) unless already_rendered?
  end
end
