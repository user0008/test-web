#!/bin/sh

yum -y clean all
yum -y update
yum -y install epel-release
yum -y install https://centos7.iuscommunity.org/ius-release.rpm
yum -y install httpd24u php56u git

systemctl enable httpd
systemctl start httpd

rm -rf /tmp/git-tmp
mkdir -p /tmp/git-tmp
cd /tmp/git-tmp

git clone https://github.com/user0008/test-web.git
mkdir -p /var/www/html
install -m 644 /tmp/git-tmp/test-web/web-app/index.php /var/www/html/

cd
rm -rf /tmp/git-tmp

