require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @req, @res, @params = req, res, route_params
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    raise "double render" if already_rendered?
    res.body = content
    res.content_type = type
    session.store_session(res)
    @already_rendered = true
  end

  # helper method to alias @already_rendered
  def already_rendered?
    @already_rendered
  end

  # set the response status code and header
  def redirect_to(url)
    raise "double render" if already_rendered?
    res.header['location'] = url
    res.status = 302
    session.store_session(res)
    @already_rendered = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    raise "double render" if already_rendered?
    template_fname = File.join("views",
                               self.class.name.underscore,
                               "#{template_name}.html.erb")
    content = ERB.new(File.read(template_fname)).result(binding)
    render_content(content, "text/html")
    @already_rendered = true
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    send(name)
    render name unless already_rendered?
  end
end
