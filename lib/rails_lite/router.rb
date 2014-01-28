require "debugger"

class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    @http_method.downcase == req.request_method.downcase &&
    @pattern.match(req.path)
  end

  def extract_route_params(req)
    keys = @pattern.names
    values = @pattern.match(req.path)
    route_params = {}
    keys.each { |key| route_params[key.to_sym] = values[key] }
    route_params
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    route_params = extract_route_params(req)
    # debugger
    controller = @controller_class.new(req, res, route_params)

    controller.invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method,
      controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action|
      add_route(pattern, http_method.to_sym, controller_class, action)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.find do |route|
      route.http_method.to_s == req.request_method.to_s.downcase &&
      route.pattern.match(req.path)
    end
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    route = match(req)
    # debugger
    route.nil? ? res.status = 404 : route.run(req, res)
  end
end
