#!/bin/bash

source /root/.bash_profile
 
###判断如果上次检查的脚本还没执行完，则退出此次执行
if [ `ps -ef|grep -w "$0"|grep -v "grep"|wc -l` -gt 2 ];then
    exit 0
fi
# mysql_con='mysql -uroot '
# mysql user/password must config in file /etc/my.cnf section [clinet]
mysql_con = 'mysql '
error_log="/etc/keepalived/check_mysql_log.err"

###定义一个简单判断mysql是否可用的函数
function excute_query {
    ${mysql_con} -e "show status;" 2>> ${error_log}
}

###定义无法执行查询，且mysql服务异常时的处理函数
function service_error {
    echo -e "`date "+%F  %H:%M:%S"`    -----mysql service error，now stop keepalived-----" >> ${error_log}
    systemctl stop  keepalived &>> ${error_log}
    # echo "$HOSTNAME keepalived 已停止" | mail -s "$HOSTNAME keepalived 已停止, 请及时处理！" sucheng@finupgroup.com 2>> ${error_log}
    echo "$HOSTNAME keepalived 已停止" >> ${error_log}
    echo -e "\n---------------------------------------------------------\n" >> ${error_log}
}

###定义无法执行查询,但mysql服务正常的处理函数
function query_error {
    echo -e "`date "+%F  %H:%M:%S"`    -----query error, but mysql service ok, retry after 30s-----" >> ${error_log}
    sleep 30
    excute_query
    if [ $? -ne 0 ];then
        echo -e "`date "+%F  %H:%M:%S"`    -----still can't execute query-----" >> ${error_log}
 
        ###对DB1设置read_only属性
        # echo -e "`date "+%F  %H:%M:%S"`    -----set read_only = 1 on $HOSTNAME-----" >> ${error_log}
        # ${mysql_con} -e "set global read_only = 1;" 2>> ${error_log}
 
        ###kill掉当前客户端连接
        echo -e "`date "+%F  %H:%M:%S"`    -----kill current client thread-----" >> ${error_log}
        rm -f /tmp/kill.sql &>/dev/null
        ###这里其实是一个批量kill线程的小技巧
        ${mysql_con} -e 'select concat("kill ",id,";") from information_schema.PROCESSLIST where command="Query" or command="Execute" into outfile "/tmp/kill.sql";'
        ${mysql_con} -e "source /tmp/kill.sql"
        sleep 2    ###给kill一个执行和缓冲时间
        ###关闭本机keepalived       
        echo -e "`date "+%F  %H:%M:%S"`    -----stop keepalived-----" >> ${error_log}
        systemctl stop keepalived &>> ${error_log}
        # echo "$HOSTNAME keepalived 已停止" | mail -s "$HOSTNAME keepalived 已停止, 请及时处理！" sucheng@finupgroup.com 2>> ${error_log}
        echo "$HOSTNAME keepalived 已停止" >> ${error_log}
        echo -e "\n---------------------------------------------------------\n" >> ${error_log}
    else
        echo -e "`date "+%F  %H:%M:%S"`    -----query ok after 30s-----" >> ${error_log}
        echo -e "\n---------------------------------------------------------\n" >> ${error_log}
    fi
}

###检查开始: 执行查询
excute_query
if [ $? -ne 0 ];then
    systemctl status mysqld &>/dev/null
    if [ $? -ne 0 ];then
        service_error
    else
        query_error
    fi
fi
