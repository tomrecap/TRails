require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    raw_cookie = req.cookies.select do |cookie|
      cookie.name == '_rails_lite_app'
    end.first

    if raw_cookie.nil?
      @cookie = {}
    else
      @cookie = JSON.parse(raw_cookie.value)
    end
  end

  def [](key)
    @cookie[key]
  end

  def []=(key, val)
    @cookie[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    cookie = WEBrick::Cookie.new(
      '_rails_lite_app', JSON.dump(@cookie))

    res.cookies << cookie
  end
end
