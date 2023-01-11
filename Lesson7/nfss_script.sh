#!/bin/bash
sudo su
yum install -y \
  redhat-lsb-core \
  wget \
  rpmdevtoools \
  rpm-build \
  createrepo \
  yum-utils \
  gcc \
  vim

#download and extract
wget http://nginx.org/packages/mainline/centos/7/SRPMS/nginx-1.23.3-1.el7.ngx.src.rpm
wget --no-check-certificate https://www.openssl.org/source/old/1.1.1/openssl-1.1.1q.tar.gz
tar -xvf openssl-1.1.1q.tar.gz --directory /usr/lib
rpm -ivh nginx-1.23.3-1.el7.ngx.src.rpm 

#Install dependencies
yum-builddep /root/rpmbuild/SPECS/nginx.spec -y


#Add options for build
sed -i "s|--with-stream_ssl_preread_module|--with-stream_ssl_preread_module --with-openssl=/usr/lib/openssl-1.1.1q --with-openssl-opt=enable-tls1_3|g" /root/rpmbuild/SPECS/nginx.spec

#Compile
rpmbuild -ba /root/rpmbuild/SPECS/nginx.spec


#Install and Start

yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.23.3-1.el7.ngx.x86_64.rpm 
sed -i '/index  index.html index.htm;/a autoindex on;' /etc/nginx/conf.d/default.conf
systemctl enable --now nginx

# create rpm repo
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/nginx-1.23.3-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/
createrepo /usr/share/nginx/html/repo/


# add rpm repo to available list
cat >> /etc/yum.repos.d/custom.repo << EOF
[custom]
name=custom-repo
baseurl=http://192.168.50.10/repo
gpgcheck=0
enabled=1
EOF






yum clean all



