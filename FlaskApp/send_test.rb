require "uri"
require "net/http"
require 'json'

params = {'box1' => 'Nothing is less important than which fork you use. Etiquette is the science of living. It embraces everything. It is ethics. It is honor. -Emily Post',
'button1' => 'Submit'
}
x = Net::HTTP.post_form(URI.parse('http://localhost:5000/json'), params)
puts x.body

uri = URI('http://localhost:5000/json')
http = Net::HTTP.new(uri.host, uri.port)
req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
req.body = {name: 'John Doe', role: 'agent'}.to_json
puts "Request #{req.body}"
res = http.request(req)
puts "response #{res.body}"
