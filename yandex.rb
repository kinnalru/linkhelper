#!/usr/bin/ruby

require 'uri'
require 'cgi'
require 'pp'


output = `/bin/sh -c 'wget #{ARGV[0]} |& grep saved'`
result = $?
if (result.success?) 
	file = /«(.*)»/.match(output)[1]
	pp "file:#{file}"
end
