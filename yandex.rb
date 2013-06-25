#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'common'

$curpid="#{ENV["RUNNING"]}.#{$$}"
File.rename(ENV["RUNNING"], $curpid)

ENV["LANG"]="C"
ENV["LC_ALL"]="C"

begin
	$stdout = File.open(ENV["LOG"], 'a') if ENV["LOG"]
	$stdout.sync = true

	$stderr = File.open(ENV["LOG"], 'a') if ENV["LOG"]
	$stderr.sync = true

	query =ARGV[0]
	log "Query:#{query}"

	params = CGI::parse(query)
	params.include?('target') || die("Target key required ./yandex.rb target=http://file.txt")

	target=params['target'].join
	cd = params.include?('cd') ? params['cd'].join : "/tmp/down"
	path = params.include?('path') ? params['path'].join : ""

	log "Target:#{target}"
	log "Cd:#{cd}"
	log "Path:#{path}"

	puts system("mkdir -p #{cd}")
	Dir.chdir(cd) || dir("Can't create/chdir folder #{cd}")

	cmd = "wget #{target} 2>&1"
	log "Run:#{cmd}"
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
		match = /«(.*)»/.match(out.grep(/saved/).join)
		match = /'(.*)'/.match(out.grep(/saved/).join) if !match
		file = match[1]
		file || die("Can't obtain result file: #{output}")
		cmd = "curl https://webdav.yandex.ru/#{path}/ -u USER:PASSWD -X PUT -T #{file}"
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
