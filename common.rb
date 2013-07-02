#!/usr/bin/ruby

require "base64"

def log(text)
	puts "[ #{`date '+%Y-%m-%d %H:%M:%S'`.strip} ] #{$0}: #{text}"
end

def die(text)
	log("Error: #{text}")
	exit(1)
	return false
end

def get_output(cmd)
	cmd = "#{cmd} 2>&1" if !cmd["2>&1"]

	log "Run: #{cmd}"

	out = []
	pipe = IO.popen(cmd)
	if pipe
		while true do
			line = pipe.gets
			break if !line
			puts line
			out << line
		end
		pipe.close
		status = $?
		raise "Process exit with error" if !status.success? 
		return out
	else
		log("Error: can't start #{cmd}")
		return nil
	end
end

def match_impl(text)
	match = /Destination:(.*)/.match(text)
	match = /\[download\](.*) has already been downloaded/.match(text) if !match
	match = /«(.*)»/.match(text) if !match
	match = /'(.*)'/.match(text) if !match

	return (match) ? match[1].strip : nil
end

def generic_match(out)
	file = match_impl(out.grep(/Destination/).join)
	file = match_impl(out.grep(/has already been downloaded/).join) if !file
	file = match_impl(out.grep(/saved/).join) if !file

	log "File matched: #{file}"

	return file
end


def put_to_webdav(host, path, file, options)
	cmd = "curl #{host}/#{path}/ --netrc-optional -X PUT -T \"#{file}\""
	return get_output(cmd)
end

def merge_channels()
	if (ENV["LOG"])
		$stdout = File.open(ENV["LOG"], 'a')
		$stderr = File.open(ENV["LOG"], 'a')
	else
		$stderr = $stdout
	end

	$stdout.sync = true
	$stderr.sync = true
end

def make_query(hash) 
	return hash.to_a.map { |x| "#{x[0]}=#{x[1]}" }.join("&")
end
