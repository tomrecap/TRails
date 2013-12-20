require 'uri'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    @params = {}

    @params.merge!(route_params)
    if req.body
      @params.merge!(parse_www_encoded_form(req.body))
    end
    if req.query_string
      @params.merge!(parse_www_encoded_form(req.query_string))
    end
  end

  def [](key)
    @params[key]
  end

  def to_s
    @params.to_json.to_s
  end

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    params = {}

    key_values = URI.decode_www_form(www_encoded_form)
    key_values.each do |full_key, value|
      scope = params

      key_seq = parse_key(full_key)
      key_seq.each_with_index do |key, idx|
        if (idx + 1) == key_seq.count
          scope[key] = value
        else
          scope[key] ||= {}
          scope = scope[key]
        end
      end
    end

    params
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    match_data = /(?<head>.*)\[(?<rest>.*)\]/.match(key)
    if match_data
      parse_key(match_data["head"]).push(match_data["rest"])
    else
      [key]
    end
  end
end
