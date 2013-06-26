#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'pp'
require 'common'

merge_channels()

url = ARGV[0]
url || die("URL string requeired: linkhelper.rb")

log "Processing URL:#{url}"
uri, path, query = nil

begin 
	uri = URI(url)
	path = uri.path
	log "Path:#{uri.path}"
	query = uri.query
	log "Query:#{uri.query}"
	if (url.empty? || !query || query.empty?)
		log "empty request skipped"
		File.delete(ENV["RUNNING"])
		exit 0
	end

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

cmd = "#{Dir.pwd}/#{action}.rb '#{query}'"
log "Starting #{cmd}"

pid = fork {
	merge_channels()
	ENV["RUBYLIB"] = "#{ENV["RUBYLIB"]}:#{Dir.pwd}"
	cd = ENV["DOWNLOADS"] ? ENV["DOWNLOADS"] : "/tmp/down"
	puts system("mkdir -p #{cd}")
	Dir.chdir(cd) || dir("Can't create/chdir folder #{cd}")
	log "Exec: #{cmd}"
	exec(cmd)
}

sleep 1
unusedpid, status = Process.waitpid2(pid, Process::WNOHANG)
exit status.exitstatus if status && !status.success?

Process.detach(pid)
exit 0
