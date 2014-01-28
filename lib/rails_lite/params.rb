require 'uri'
require "active_support/core_ext/hash/deep_merge"

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    unless req.query_string.nil?
      query_params = parse_www_encoded_form(req.query_string)
    else
      query_params = {}
    end

    unless req.body.nil?
      body_params = parse_www_encoded_form(req.body)
    else
      body_params = {}
    end

    @params = route_params
      .merge(query_params)
      .merge(body_params)
  end

  def [](key)
    @params[key]
  end

  def to_s
    @params.to_s
  end

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    array_of_arrays = URI.decode_www_form(www_encoded_form)

    params = {}

    array_of_arrays.each do |key, value|
      keys = parse_key(key)
      subhash = { keys.pop => value }

      keys.count.times do
        subhash = { keys.pop => subhash }
      end

      params = params.deep_merge(subhash)
      # params[subhash.keys.first] = subhash.values.first
    end

    params
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.split(/\]\[|\[|\]/)
  end

end
