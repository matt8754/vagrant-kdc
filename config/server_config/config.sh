#! /bin/bash
 
set -e
set -x
 
SERVER_IP_ADDR=192.168.19.15
SERVER_FQDN=`hostname`
SERVER_NAME=`hostname | cut -d. -f 1 | tr '[:upper:]' '[:lower:]'`
IPA_REALM=EXAMPLE.COM
IPA_DOMAIN=example.com
FORWARDER=10.64.63.6
PASSWORD=aaaAAA111
