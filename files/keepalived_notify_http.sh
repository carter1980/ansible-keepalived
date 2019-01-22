#!/bin/bash
# requirement: curl command

if [ $# -lt 1 ]; then
    echo "Usage: $0 content " | tee -a /etc/keepalived/keepalived_notify_http.log
        exit 1
fi

WEIXIN_URL="http://10.10.62.16:8080/wechat/message"
MSG="HostName: $HOSTNAME \nService: DNS-MYSQL-KEEPALIVED \nStatus: $1"
shift

MSG="$MSG \nOTHERS: $* "

# while (( "$#" )); do
#     MSG="$MSG \n $1"
# shift
# done

echo -e "`date "+%F  %H:%M:%S"` --- $MSG" >>  /etc/keepalived/keepalived_notify_http.log
curl -l -H "Content-type: application/json" -X POST $WEIXIN_URL -d '{"from": "zabbix","to": "17479314581385055317","content": "'"${MSG}"'"}'