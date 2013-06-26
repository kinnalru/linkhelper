#!/bin/sh

WORK=/tmp/linkhelper
HISTORY=${WORK}/history/
RUNNING=${WORK}/running/
SRV_LOG=${WORK}/server.log
DOWNLOADS=/tmp/down

LPORT="8383"
RHOST="develplace.dyndns.org"
RUSER="kinnalru"
RPORT="11020"

mkdir -p $HISTORY
mkdir -p $RUNNING
mkdir -p $DOWNLOADS

export DOWNLOADS=$DOWNLOADS

RESPONSE=${WORK}/webresp
[ -p $RESPONSE ] || mkfifo $RESPONSE

echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] Forwarding port localhost:$LPORT <- $RPORT..." | tee -a $SRV_LOG
ssh -f -R *:$RPORT:localhost:$LPORT ${RUSER}@${RHOST} -o ExitOnForwardFailure=yes -N

while true ; do
    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] Start listening on port $LPORT..." | tee -a $SRV_LOG
    ( cat $RESPONSE ) | nc -l -p ${LPORT} | (
#    ( cat $RESPONSE ) | socat tcp-l:${LPORT},shut-null,null-eof - | (
#    ( cat $RESPONSE ) | ssh kinnalru@develplace.dyndns.org -C socat -T 5 tcp-l:${RPORT},shut-null,null-eof - | (

    sleep 1
    REQUEST=`while read L && [ " " "<" "$L" ] ; do echo "$L" ; done`
    REQ=`echo "$REQUEST" | head -n 1`

    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] $REQ" | tee -a $SRV_LOG

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
    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] ${CODE}: ${CUR_HISTORY}" | tee -a $SRV_LOG

	RESP=`cat "${LOG}" | sed s/\$/\<br\>/`
	rm $LOG

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
