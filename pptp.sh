#!/bin/bash

#yum -y update
yum -y install epel-release
yum -y install firewalld net-tools ppp pptpd

# 开启内核转发
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p

#添加pptp的登录账号密码
echo "$1 * $2 *" >> /etc/ppp/chap-secrets

#开启虚拟IP分配
cat >>/etc/pptpd.conf <<END
localip 192.168.22.1
remoteip 192.168.22.10-100
END

#添加 pptp 的DNS解析服务器 格式：ms-dns 8.8.8.8 ，ip改为你自己的可以了
cat >>/etc/ppp/options.pptpd <<END
ms-dns 8.8.8.8
ms-dns 8.8.4.4
END

# Firewall 通过防火墙规则
# ens=$(ls /etc/sysconfig/network-scripts/ | grep 'ifcfg-e.*[0-9]' | cut -d- -f2)
ens=eth0
systemctl restart firewalld.service
systemctl enable firewalld.service
firewall-cmd --set-default-zone=public
firewall-cmd --add-interface=m=$ens
firewall-cmd --add-port=1723/tcp --permanent
firewall-cmd --add-masquerade --permanent
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -i $ens -p gre -j ACCEPT
firewall-cmd --reload
#
cat > /etc/ppp/ip-up.local << END
/sbin/ifconfig $1 mtu 1400
END
chmod +x /etc/ppp/ip-up.local
systemctl restart pptpd.service
systemctl enable pptpd.service

