#!/bin/bash

# replace url
cp /etc/apt/sources.list /etc/apt/sources.list_bak
sed -i 's/mirrors.tuna.tsinghua.edu.cn/mirrors.aliyun.com/g' /etc/apt/sources.list
apt-get update

# install sudo vim
for i in 'sudo' 'vim' 
do
	if ! type $i >/dev/null 2>&1;then
		echo "$i 未安装"
		echo "开始安装"$i"……"
		apt-get install $i
		echo $i"安装完成"
	else
		echo "$i 已安装"
	fi
done
sudo apt update && sudo apt install snapd -y
sudo snap install core
sudo snap install shadowsocks-libev
sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
# config ss
cat>/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json<<EOF
{
    "server":["::0","0.0.0.0"],
    "server_port":8091,
    "local_port":1080,
    "password":"sm12345",
    "timeout":60,
    "method":"aes-256-gcm",
    "mode":"tcp_and_udp",
    "fast_open":false
}

EOF
# config service
cat>/etc/systemd/system/shadowsocks-libev-server@.service<<EOF
[Unit]
Description=Shadowsocks-Libev Custom Server Service for %I
After=network-online.target
 
[Service]
Type=simple
LimitNOFILE=65536
ExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/%i.json
 
[Install]
WantedBy=multi-user.target

EOF

sudo systemctl enable shadowsocks-libev-server@config
sudo systemctl start shadowsocks-libev-server@config
sudo systemctl status shadowsocks-libev-server@config
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
lsmod | grep bbr
echo "config end!"
