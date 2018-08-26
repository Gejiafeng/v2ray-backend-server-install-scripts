#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
cat << "EOF"
 _      __     ______   _      __  
| | /| / /__ _/ / / /  (_)__  / /__
| |/ |/ / _ `/ / / /__/ / _ \/  '_/
|__/|__/\_,_/_/_/____/_/_//_/_/\_\ 
Author: YihanH
Github: https://github.com/YihanH/v2ray-backend-server-install-scripts
EOF
echo "V2Ray proxy node installation script for Ubuntu 18.04 x64"
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
echo "Press Y for continue the installation process, or press any key else to exit."
read is_install
if [[ is_install =~ ^[Y,y,Yes,YES]$ ]]
if [[ ${is_install} != "y" && ${is_install} != "Y" ]]; then
    echo -e "Installation has been canceled..."
    exit 0
fi
echo "Updatin exsit package..."
apt clean all && apt autoremove -y && apt update && apt upgrade -y && apt dist-upgrade -y
echo "Install necessary package..."
apt install ntp screen -y
echo "Please select correct system timezone for your node."
dpkg-reconfigure tzdata
echo "Downloading bin file..."
mkdir -p /soft/v2ray && cd /soft/v2ray
wget -O v2ray-agent https://cdn.leezf.com/V2Ray/bin && chmod +x v2ray-agent
echo "Downloading config file..."
wget  https://raw.githubusercontent.com/YihanH/v2ray-backend-server-install-scripts/master/agent.yaml
echo -n "Please enter DB username:"
read db_user
echo -n "DB password:"
read db_password
echo -n "Server node ID:"
read node_id
echo "Writting config..."
sed -i -e "s/nodeId: xxxx/nodeId: ${node_id}/g" -e "s/user: xxxx/user: ${db_user}/g" -e "s/pass: xxxx/pass: ${db_password}/g" agent.yaml
echo "Running system optimization and enable Google BBR..."
echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
cat >> /etc/security/limits.conf << EOF
* soft nofile 51200
* hard nofile 51200
EOF
ulimit -n 51200
cat >> /etc/sysctl.conf << EOF
fs.file-max = 51200
net.core.default_qdisc = fq
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
EOF
sysctl -p
echo "Setting startup script..."
ln -fs /lib/systemd/system/rc-local.service /etc/systemd/system/rc-local.service
wget -O rc.local https://raw.githubusercontent.com/YihanH/v2ray-backend-server-install-scripts/master/rc.local_ubuntu_18 && chmod +x rc.local
mv -f rc.local /etc
echo "Installation complete, please run "/soft/v2ray/v2ray-agent" to test."
