#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'pp'

def die(text)
	puts text
	exit(1)
	return false
end

query =ARGV[0]
pp "Query:#{query}"
query || die("Query string requeired: ./youtube.rb <query>")

params = CGI::parse(query)
params.include?('target') || die("Target key required ./youtube.rb target=http://file.txt")

target=params['target'].join
cd = params.include?('cd') ? params['cd'].join : "/tmp/down"
path = params.include?('path') ? params['path'].join : ""

pp "Target:#{target}"
pp "Cd:#{cd}"
pp "Path:#{path}"

`mkdir -p #{cd}`
Dir.chdir(cd) || dir("Can't create/chdir folder #{cd}")

cmd = "youtube-dl -t #{target} 2>&1"
pp "Command:#{cmd}"
out = []
IO.popen(cmd, "r+") do |pipe|
	while true do
		line = pipe.gets
		break if !line
		puts line
		out << line
	end
end

result = $?
if (result.success?) 
	match = /Destination:(.*)/.match(out.grep(/Destination/).join)
	match = /\[download\](.*) has already been downloaded/.match(out.grep(/has already been downloaded/).join)
	file = match[1].strip
	file || die("Can't obtain result file: #{output}")
	cmd = "curl https://webdav.yandex.ru/#{path}/ -u USER:PASSWD -X PUT -T \"#{file}\""
	pp cmd
	system(cmd) ? exit(0) : exit(1)
else
	die("Can't execute command: #{cmd}")
end

exit(1)
