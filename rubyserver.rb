#!/usr/bin/ruby

require "socket"
require "common"

work="/tmp/linkhelper"
history="#{work}/history/"
running="#{work}/running/"
srv_log="#{work}/server.log"
downloads="/tmp/down"

port=8383

system("mkdir -p #{history}")
system("mkdir -p #{running}")
system("mkdir -p #{downloads}")

class Tee
	def initialize(f1,f2)
		@f1,@f2 = f1,f2
	end
	def method_missing(m,*args,&b)
		@f1.send(m,*args,&b)
	    @f2.send(m,*args,&b)
	end

	def write(string)
		@f1.write(string)
		return @f2.write(string)
	end
end

logfile = File.open(srv_log, "a")
logfile.sync = true
$stdout = Tee.new(logfile, $stdout)
$stderr = Tee.new(logfile, $stderr)

ENV["DOWNLOADS"]=downloads
 
webserver = TCPServer.new('localhost', port)
while (session = webserver.accept)
	sleep 1

	request = session.gets
	log(request)

    query=`echo '#{request}' | cut -d ' ' -f 2`.strip

	code = "200 OK"

	if (query == "/favicon.ico")
		resp = "favicon skipped"
		log resp
	else
		ENV["LOG"]=`mktemp`.strip
		ENV["CURHISTORY"]="#{history}/" + `date '+%Y-%m-%d_%H_%M_%S'`.strip + ".log"
		ENV["RUNNING"]="#{running}/" + `date '+%Y-%m-%d_%H_%M_%S'`.strip

		system("ln #{ENV["LOG"]} #{ENV["CURHISTORY"]}")
		system("ln #{ENV["LOG"]} #{ENV["RUNNING"]}")

		ret = system("./linkhelper.rb \"#{query}\" 2>&1")
		code = "500 Internal Server Error" if ret

		log("#{code}: #{ENV["CURHISTORY"]}")
		resp=`cat '#{ENV["LOG"]}'`.gsub("\n", "<br>")
		File.delete(ENV["LOG"])
	end
	
	begin
		session.puts("HTTP/1.0 #{code}")
		session.puts("Cache-Control: private")
		session.puts("Content-Type: text/html")
		session.puts("Server: bash/2.0")
		session.puts("Connection: Close")
		session.puts("Content-Length: #{resp.length}")
		session.puts("")
		session.puts("#{resp}")
		session.puts("")
		session.puts("")
	rescue => e
		log "Can't send response: #{e}"
	end
	session.close
end
