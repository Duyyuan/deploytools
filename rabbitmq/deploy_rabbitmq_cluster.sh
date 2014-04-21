#!/bin/bash
# NOTICE: RabbitMQ should use hostname instead of ip address
# Author dysj4099@gmail.com
# April 15, 2014

# Read config
. ./deploy_rabbitmq_cluster.cfg

# Get MY_IP
if [ "${MY_IP}" == "" ];then
    MY_IP=$(python -c "import socket;socket=socket.socket();socket.connect(('8.8.8.8',53));print socket.getsockname()[0];")
fi

# Get ROOT_PASS from keyboard
if [ $# -ne 2 ];then
    echo "Usage:"
    echo "      `basename $0` -p password"
    exit 0
fi
while getopts 'p:l:' OPT; do
case $OPT in
    p)
	ROOT_PASS="$OPTARG";;
    ?)
	echo "Usage:"
	echo "      `basename $0` -p password"
        exit 0
esac
done

# Step 1. install sshpass
apt-get install sshpass -y

# Step 2. install and configure
cat > /tmp/tmp_install_rabbitmq.sh << _wrtend_
#!/bin/bash
# Get install parameter
while getopts 'h:r' OPT; do
    case $OPT in
        h)
	    HOSTNAME_ROOT="$OPTARG";;
	r)
	    RAM_MODE=true;;												   esac
done
# Remove old version
apt-get -y purge rabbitmq-server
# Install new version
echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/source.list
sudo apt-key add rabbitmq-signing-key-public.asc
apt-get update
apt-get -y install rabbitmq-server
# Stop service
service rabbitmq-server stop
# Set erlang cookie
echo 'CNICCSDBRABBITMQECCP' > /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie
# Start service
service rabbitmq-server start
# Set up rabbitmq cluster
/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management
/usr/sbin/rabbitmqctl stop_app
/usr/sbin/rabbitmqctl reset
if $RAM_MODE;then
    /usr/sbin/rabbitmqctl join_cluster --ram rabbit@${HOSTNAME_ROOT}
else
    /usr/sbin/rabbitmqctl join_cluster rabbit@${HOSTNAME_ROOT}
fi
/usr/sbin/rabbitmqctl start_app
_wrtend_

for i in ${!NODES[@]}; do
    #idx=`expr $i + 1`

done
