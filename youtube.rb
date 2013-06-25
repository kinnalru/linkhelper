#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'common'

$curpid="#{ENV["RUNNING"]}.#{$$}"
File.rename(ENV["RUNNING"], $curpid)

begin
	$stdout = File.open(ENV["LOG"], 'a') if ENV["LOG"]
	$stdout.sync = true

	$stderr = File.open(ENV["LOG"], 'a') if ENV["LOG"]
	$stderr.sync = true

	query =ARGV[0]
	log "Query:#{query}"
	query || die("Query string requeired: ./youtube.rb <query>")

	params = CGI::parse(query)
	params.include?('target') || die("Target key required ./youtube.rb target=http://file.txt")

	target=params['target'].join
	cd = params.include?('cd') ? params['cd'].join : "/tmp/down"
	path = params.include?('path') ? params['path'].join : ""

	log "Target:#{target}"
	log "Cd:#{cd}"
	log "Path:#{path}"

	puts system("mkdir -p #{cd}")
	Dir.chdir(cd) || dir("Can't create/chdir folder #{cd}")

	cmd = "youtube-dl -c -t #{target} 2>&1"
	log "Command:#{cmd}"
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
		match = /\[download\](.*) has already been downloaded/.match(out.grep(/has already been downloaded/).join) if !match
		file = match[1].strip
		file || die("Can't obtain result file: #{output}")
		log "Result: #{file}"
		cmd = "curl https://webdav.yandex.ru/#{path}/ -u USER:PASSWD -X PUT -T \"#{file}\""
		log "Run:#{cmd}"
		if system(cmd)
			log "Completed"
			exit(0)
		else 
			log "Failed"
			exit(1)
		end
	else
		die("Can't execute command: #{cmd}")
	end

	exit(1)

ensure
	File.delete($curpid)
end
