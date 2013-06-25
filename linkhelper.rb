#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'pp'
require 'common'

$stdout = File.open(ENV["LOG"], 'a') if ENV["LOG"]
$stdout.sync = true

$stderr = File.open(ENV["LOG"], 'a') if ENV["LOG"]
$stderr.sync = true

url = ARGV[0]
url || die("URL string requeired: linkhelper.rb")


log "Processing URL:#{url}"
uri, path, query = nil

begin 
	uri = URI(url)
	path = uri.path
	log "Path:#{uri.path}"
	if (path == "/favicon.ico")
		log "favicon skipped"
		File.delete(ENV["RUNNING"])
		exit 0
	end
	query = uri.query
	log "Query:#{uri.query}"

	params = CGI::parse(query)
rescue => e
	die("Can't process query #{query} : #{e}")
end


action = params['action']
target = params['target']

action || die("action required in query")
target || die("target required in query")

log "Action:#{action}"
log "Target:#{target}"

Dir.entries(Dir.pwd).grep("#{action}.rb").empty? && die("There is no such action")

cmd = "./#{action}.rb '#{query}'"
log "Starting #{cmd}"

pid = fork {
	$stdout = File.open(ENV["LOG"], 'a') if ENV["LOG"]
	$stdout.sync = true

	$stderr = File.open(ENV["LOG"], 'a') if ENV["LOG"]
	$stderr.sync = true
	exec(cmd)
}

sleep 1
unusedpid, status = Process.waitpid2(pid, Process::WNOHANG)
exit status.exitstatus if status && !status.success?

Process.detach(pid)
exit 0
