#! /bin/bash

set -e
set -x

echo "Exporting env variables"
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/config.sh

echo "Configuring /etc/hosts ..."
echo "127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1 	localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
echo "$CLIENT_IP_ADDR    $CLIENT_FQDN $CLIENT_NAME" >> /etc/hosts

echo "Configuring /etc/resolv.conf"
echo "search $IPA_DOMAIN" > /etc/resolv.conf
echo "nameserver $SERVER_IP_ADDR" >> /etc/resolv.conf

echo "Disabling updates-testing repo ..."
sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-updates-testing.repo

echo "Downloading packages ..."
yum install freeipa-client freeipa-admintools mod_auth_kerb -y

echo "Configuring firewalld ..."
yum install -y firewalld
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --zone=public --add-port  80/tcp
firewall-cmd --permanent --zone=public --add-port 443/tcp
firewall-cmd --permanent --zone=public --add-port 389/tcp
firewall-cmd --permanent --zone=public --add-port 636/tcp
firewall-cmd --permanent --zone=public --add-port  88/tcp
firewall-cmd --permanent --zone=public --add-port 464/tcp
firewall-cmd --permanent --zone=public --add-port  53/tcp
firewall-cmd --permanent --zone=public --add-port  88/udp
firewall-cmd --permanent --zone=public --add-port 464/udp
firewall-cmd --permanent --zone=public --add-port  53/udp
firewall-cmd --permanent --zone=public --add-port 123/udp

firewall-cmd --zone=public --add-port  80/tcp
firewall-cmd --zone=public --add-port 443/tcp
firewall-cmd --zone=public --add-port 389/tcp
firewall-cmd --zone=public --add-port 636/tcp
firewall-cmd --zone=public --add-port  88/tcp
firewall-cmd --zone=public --add-port 464/tcp
firewall-cmd --zone=public --add-port  53/tcp
firewall-cmd --zone=public --add-port  88/udp
firewall-cmd --zone=public --add-port 464/udp
firewall-cmd --zone=public --add-port  53/udp
firewall-cmd --zone=public --add-port 123/udp

echo "Installing IPA client ..."
ipa-client-install --enable-dns-updates --ssh-trust-dns -p admin -w $PASSWORD -U --force-join
 
echo "Testing kinit"
echo $PASSWORD | kinit admin

echo "Enrolling Apache as a service on the IPA Server"
ipa service-add HTTP/$CLIENT_FQDN

echo "Getting keytab from IPA Server to Client"
ipa-getkeytab -s $SERVER_FQDN -p HTTP/$CLIENT_FQDN -k /vagrant/http.keytab

echo "Changing ownership of keytab"
chown vagrant:vagrant /vagrant/http.keytab

echo "Testing  keytab"
kinit -kt /vagrant/http.keytab -p HTTP/$CLIENT_FQDN

echo "Re-kiniting as admin"
echo $PASSWORD | kinit admin
