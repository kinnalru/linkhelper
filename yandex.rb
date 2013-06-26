#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'common'

if (ENV["RUNNING"])
	$curpid="#{ENV["RUNNING"]}.#{$$}"
	File.rename(ENV["RUNNING"], $curpid)
else
	$curpid = nil
end

ENV["LANG"]="C"
ENV["LC_ALL"]="C"

begin
	merge_channels()
	query =ARGV[0]
	log "Query:#{query}"
	raise "Query string requeired: ./youtube.rb <query>" if !query

	params = CGI::parse(query)
	raise "Target key required ./yandex.rb target=http://file.txt" if !params.include?('target') 

	target=params['target'].join
	path = params.include?('path') ? params['path'].join : ""

	log "Target:#{target}"
	log "Path:#{path}"

	cmd = "wget -c #{target}"
	out = get_output(cmd)

    raise "Can't execute command: #{cmd}" if !out

	file = generic_match(out)
    raise "Can't obtain result file: #{output}" if !file

	out = put_to_webdav("https://webdav.yandex.ru", path, file, "")
    raise "Can't put to webdav" if !out

	log "Completed"
	exit(0)
rescue => e
    log "Failed: #{e}"
	exit 1
ensure
	File.delete($curpid) if $curpid
end
