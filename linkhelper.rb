#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'pp'

url = ARGV[0]

puts "Processing URL:#{url}"

uri = URI(url)
path = uri.path
query = uri.query
params = CGI::parse(query)

pp "Path:#{uri.path}"
pp "Query:#{uri.query}"
pp "Params:", params

action = params['action']
target = params['target']

pp "Action:#{action}"
pp "Target:#{target}"

exec("./#{action}.rb #{target}")
