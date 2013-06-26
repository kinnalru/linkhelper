#!/usr/bin/ruby

require "socket"

work="/tmp/linkhelper"
history="#{work}/history/"
running="#{work}/running/"
srv_log="#{work}/server.log"
downloads="/tmp/down"

lport="8383"
rhost="develplace.dyndns.org"
ruser="kinnalru"
rport="11020"

system("mkdir -p #{history}")
system("mkdir -p #{running}")
system("mkdir -p #{downloads}")

ENV["DOWNLOADS"]=downloads
 
webserver = TCPServer.new('localhost', 8080)
while (session = webserver.accept)

	request = session.gets

    query=`echo '#{request}' | cut -d ' ' -f 2`.strip

	code = "200 OK"

	ENV["LOG"]=`mktemp`.strip
	ENV["CURHISTORY"]="#{history}/" + `date '+%Y-%m-%d_%H_%M_%S'`.strip + ".log"
	ENV["RUNNING"]="#{running}/" + `date '+%Y-%m-%d_%H_%M_%S'`.strip

	system("ln #{ENV["LOG"]} #{ENV["CURHISTORY"]}")
	system("ln #{ENV["LOG"]} #{ENV["RUNNING"]}")

	system("./linkhelper.rb \"#{query}\" 2>&1")

	resp=`cat '#{ENV["LOG"]}'`.gsub("\n", "<br>")

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
  	session.close
end
