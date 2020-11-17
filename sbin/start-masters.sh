#!/bin/env bash

#在A上运行命令:
# ssh-keygen -t rsa (连续三次回车,即在本地生成了公钥和私钥,不设置密码)
# ssh root@B "mkdir .ssh" (需要输入密码)
# scp ~/.ssh/id_rsa.pub root@B:.ssh/id_rsa.pub (需要输入密码)
#在B上的命令:
# touch /root/.ssh/authorized_keys (如果已经存在这个文件, 跳过这条)
# cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys (将id_rsa.pub的内容追加到authorized_keys 中)
#回到A机器:
# exit
# ssh root@B (不需要密码, 登录成功)

cat "${MOONBOX_HOME}/conf/nodes" | grep master | awk '{print $2 " " $3}' | cut -d '/' -f 3 | while read line
do
    hostname=`echo $line | awk '{print $1}' |cut -d ':' -f 1`
    akka_port=`echo $line | awk '{print $1}' |cut -d ':' -f 2`
    ssh_port=`echo $line | awk '{print $2}' `
    if [ -z "$ssh_port" ]; then
        ssh_port=22
    fi

    akka_ip=`cat /etc/hosts | grep $hostname | awk '{print $1}'`

    echo "ssh $hostname $ssh_port ..."

    ssh -o Port=${ssh_port} ${hostname}  << EEOF
        work_home=\${MOONBOX_HOME}
        echo "work home is \${MOONBOX_HOME}  ip ${akka_ip}   port ${akka_port}"
        if [ -z \$work_home  ]; then
            echo 'NOTICE: Not found MOONBOX_HOME env in remote machine: ${hostname}, please set MOONBOX_HOME and MOONBOX_JAVA_HOME firstly'
        else
            cd \${work_home}
            \${work_home}/sbin/start-master.sh
	fi
EEOF
    if [ $? -ne 0 ] ;then
        echo "ERROR: ssh ${hostname} and run command failed, please check"
        echo ""
    else
        echo "all in ${hostname} done"
        echo ""
    fi
done

