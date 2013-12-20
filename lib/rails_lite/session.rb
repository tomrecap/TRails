require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    cookie = req.cookies.find { |c| c.name == '_rails_lite_app' }
    @session = JSON.parse(cookie.value) if cookie
    @session ||= {}
  end

  def [](key)
    @session[key]
  end

  def []=(key, val)
    @session[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app', @session.to_json)
  end
end
