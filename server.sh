#!/bin/sh

export LH_LOG=/tmp/lh.log

RESPONSE=/tmp/webresp
[ -p $RESPONSE ] || mkfifo $RESPONSE

while true ; do
    ( cat $RESPONSE ) | nc -l -p 8080 | (
    REQUEST=`while read L && [ " " "<" "$L" ] ; do echo "$L" ; done`
    REQ=`echo "$REQUEST" | head -n 1`

    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] $REQ" >> /tmp/lh-access.log

    QUERY=`echo $REQ | cut -d " " -f 2`

	CODE="200 OK"
	#RESP=`./linkhelper.rb "${QUERY}" 2>&1`
	./linkhelper.rb "${QUERY}" 2>&1

	if [[ $? -ne 0 ]]; then CODE="404 Error"; fi
	echo -e $RESP
	echo CODE ${CODE}
	RESP=`echo "${RESP}" | sed s/\$/\<br\>/`

    cat >$RESPONSE <<EOF
HTTP/1.0 ${CODE}
Cache-Control: private
Content-Type: text/html
Server: bash/2.0
Connection: Close
Content-Length: ${#RESP}

$RESP
EOF
    )
done
