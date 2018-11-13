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
echo "V2Ray proxy node installation script for CentOS 7 x64"
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
echo "Press Y for continue the installation process, or press any key else to exit."
read is_install
if [[ ${is_install} != "y" && ${is_install} != "Y" ]]; then
    echo -e "Installation has been canceled..."
    exit 0
fi
echo "Updatin exsit package..."
yum clean all && rm -rf /var/cache/yum && yum update -y
echo "Install necessary package..."
yum install epel-release -y && yum makecache
yum install screen net-tools htop ntp -y
echo "Disabling firewalld..."
systemctl stop firewalld && systemctl disable firewalld
echo "Setting system timezone..."
timedatectl set-timezone Asia/Taipei && systemctl stop ntpd.service && ntpdate us.pool.ntp.org
echo "Creating V2Ray agent's directory in /soft..."
mkdir -p /soft/v2ray && cd /soft/v2ray
echo -n "Please enter your site ID:"
read site_id
echo -n "Please enter your API key:"
read api_key
echo "Sending build request..."
curl https://api.v2ray.page/$site_id/build -X POST -H 'x-key: $api_key' -SL
echo "Waiting for build server's response..."
sleep 20
echo "Trying download V2Ray agent's build file..."
curl https://api.v2ray.page/$site_id/download -H 'x-key: $api_key' -SL -o v2ray-agent && chmod +x v2ray-agent
echo "Downloading V2Ray agent's config file..."
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
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum remove kernel-headers -y
yum --enablerepo=elrepo-kernel install kernel-ml kernel-ml-headers -y
grub2-set-default 0
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
echo "System require a reboot to complete the installation process, press Y to continue, or press any key else to exit this script."
read is_reboot
if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
    reboot
else
    echo -e "${green}Info:${plain} Reboot has been canceled..."
    exit 0
fi