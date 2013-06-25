#!/usr/bin/ruby


def log(text)
	puts "[ #{`date '+%Y-%m-%d %H:%M:%S'`.strip} ] #{$0}: #{text}"
end

def die(text)
	log("Error: #{text}")
	exit(1)
	return false
end
