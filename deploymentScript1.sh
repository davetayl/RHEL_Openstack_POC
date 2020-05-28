#!/usr/bin/env bash
# There are two sets of variables that need to be configured, then copy this to the server and run

# Variables for the first half of teh deployment
export HZNUSER=<user> # The Horizon user
export HZNPASS=<password> # The Horizon user password
export RHNACC=<account> # The redhat subscription account
export RHNPASS=<password> # The redhat subscription account password
export NAMESERVER=<ip address> # Address of the name server to use

# Variables for second half of the deployment
export IP=<man IP>
export NETMASK=<man mask>
export INTERFACE=<man interface>
export STACKUSER=stack # The Openstack linux user
export STACKPASS=stackpass # The Openstack linux user password

# Set up login banner
cat > /etc/motd << EOF
  #%%%%%%%%%#    
 ,%%/          (%%%%%%%%%%%%%%%%%%%%  
 %%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%% 
 %%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%,
 %%%%%%%%% %%%%%%%%%%%%      %%%%%%%%%
 %%%%%%%%% %%. %%%%%%%%      %%%%%%%%%
 %%%%%%%%%      %%%%%%%      #%%%%%%%%
 %%%%%%%%%          %%%      (%%%%%%%%
 %%%%%%%%%     %*            %%%%%%%%%
 %%%%%%%%%     %%%%%         %%%%%%%%%
 %%%%%%%%%     %%%%%%%%      %%%%%%%%.
 %%%%%%%%%     %%%%%%%%      %%%%%%%% 
---------------------------------------
         Redhat OpenStack PoC
---------------------------------------

EOF

# Set up stack user
useradd $STACKUSER
echo "$STACKPASS" | passwd --stdin $STACKUSER

echo "$STACKUSER ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/$STACKUSER
chmod 0440 /etc/sudoers.d/$STACKUSER

cat >> /home/stack/.bashrc << EOF
# Common openstack envs
export OS_USERNAME=$HZNUSER  
export OS_PASSWORD=$HZNPASS
export OS_PROJECT_NAME=admin 
export OS_AUTH_URL=http://$IP:5000
export OS_AUTH_STRATEGY=keystone
export OS_PROJECT_DOMAIN_NAME="Default"
export OS_USER_DOMAIN_NAME="Default"
export OS_IDENTITY_API_VERSION=3
export OS_CLOUD=standalone
export OS_NO_CACHE=1
export HZNUSER=$HZNUSER
export HZNPASS=$HZNPASS
export RHNACC=$RHNACC
export RHNPASS=$RHNPASS
export NAMESERVER=$NAMESERVER
export IP=$IP
export NETMASK=$NETMASK
export INTERFACE=$INTERFACE

EOF

curl -s https://raw.githubusercontent.com/davetayl/RHEL_Openstack_POC/master/deploymentScript2.sh | sudo stack > /dev/null 2>&1
curl -s https://raw.githubusercontent.com/davetayl/RHEL_Openstack_POC/master/deploymentScript3.sh | sudo stack > /dev/null 2>&1

