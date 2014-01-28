require 'webrick'
require 'rails_lite'
require 'active_support/core_ext'

server = WEBrick::HTTPServer.new(Port: 8080)
trap('INT') { server.shutdown }

class MyController < ControllerBase
  def go
    render_content(request.path, "text/text")

  end
end

server.mount_proc("/") do |request, response|
  MyController.new(request, response)
end