#!/bin/sh

WORK=/tmp/linkhelper
HISTORY=${WORK}/history/
RUNNING=${WORK}/running/
SRV_LOG=${WORK}/server.log

mkdir -p $HISTORY
mkdir -p $RUNNING

RESPONSE=${WORK}/webresp
[ -p $RESPONSE ] || mkfifo $RESPONSE


while true ; do
#    ( cat $RESPONSE ) | nc -l -p 8080 | (
#    ( cat $RESPONSE ) | socat tcp-l:8080,shut-null - | (
    ( cat $RESPONSE ) | ssh kinnalru@develplace.dyndns.org -C socat tcp-l:11015,shut-null - | (
    REQUEST=`while read L && [ " " "<" "$L" ] ; do echo "$L" ; done`
    REQ=`echo "$REQUEST" | head -n 1`

    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] $REQ" >> $SRV_LOG

    QUERY=`echo $REQ | cut -d " " -f 2`

	CODE="200 OK"

	export LOG=`mktemp`
	CUR_HISTORY="${HISTORY}/`date '+%Y-%m-%d_%H_%M_%S'`.log"
	export RUNNING="${RUNNING}/`date '+%Y-%m-%d_%H_%M_%S'`"

	ln $LOG $CUR_HISTORY
	ln $LOG $RUNNING

	./linkhelper.rb "${QUERY}" 2>&1

	if [[ $? -ne 0 ]]; then
		CODE="500 Internal Server Error"
	fi
    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] ${CODE}: ${CUR_HISTORY}" >> $SRV_LOG

	RESP=`cat $LOG`
	rm $LOG

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

    sleep 1
done
