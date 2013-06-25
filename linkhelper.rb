#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'pp'

def die(text)
	pp "#{text}"
	exit(1)
	return false
end

url = ARGV[0]
url || die("URL string requeired: linkhelper.rb")


pp "Processing URL:#{url}"

uri, path, query = nil

begin 
	uri = URI(url)
	path = uri.path
	pp "Path:#{uri.path}"
	query = uri.query
	pp "Query:#{uri.query}"

	params = CGI::parse(query)
rescue => e
	die("Can't process query #{query} : #{e}")
end


action = params['action']
target = params['target']

action || die("action required in query")
target || die("target required in query")

pp "Action:#{action}"
pp "Target:#{target}"
pp "Query:#{query}"

cmd = "./#{action}.rb '#{query}'"

pid = fork {
	exec(cmd)
	exit(0)
}

pp Process.detach(pid)
exit 0
