require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @cookie_name = "_rails_lite_app" if self.class == Session

    raw_cookie = req.cookies.select do |cookie|
      cookie.name == @cookie_name
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
      @cookie_name, JSON.dump(@cookie))

    res.cookies << cookie
  end
end

class Flash < Session
  def initialize(req)
    @cookie_name = "_rails_lite_app_flash"
    @req_time = req.request_time

    super(req)

    reset_flash if flash_data_is_expired?
  end

  def reset_flash
    @cookie = {}
    @cookie[:setting_req_time] = @req_time
  end

  def flash_data_is_expired?
    @cookie[:setting_req_time] == (nil || !@req_time)
  end
end