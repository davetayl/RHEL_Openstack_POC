# The server should have two interfaces, the first should be configured and used for initial setup
# the second should be free and will become a bridge interface with an IP and all the OS services
# bound to it, the details below are for the second interface
bash --rcfile /home/stack/.bashrc

sudo subscription-manager register \
--username=$RHNACC \
--password="$RHNPASS" \
--release=8.1

sudo subscription-manager repos \
--disable=*

sudo subscription-manager repos \
--enable=rhel-8-for-x86_64-baseos-eus-rpms \
--enable=rhel-8-for-x86_64-appstream-rpms \
--enable=rhel-8-for-x86_64-highavailability-eus-rpms \
--enable=ansible-2.8-for-rhel-8-x86_64-rpms \
--enable=openstack-16-for-rhel-8-x86_64-rpms \
--enable=fast-datapath-for-rhel-8-x86_64-rpms

sudo dnf -y install dnf-utils net-tools tmux python3-tripleoclient

cat > /home/stack/standalone_parameters.yaml << EOF
parameter_defaults:
  CloudName: $IP
  ControlPlaneStaticRoutes: []
  Debug: true
  DeploymentUser: $STACKUSER
  DnsServers:
    - $NAMESERVER
  DockerInsecureRegistryAddress:
    - $IP:8787
  NeutronPublicInterface: $INTERFACE
  NeutronDnsDomain: lab
  NeutronBridgeMappings: datacentre:br-ctlplane
  NeutronPhysicalBridge: br-ctlplane
  StandaloneEnableRoutedNetworks: true
  StandaloneHomeDir: /home/stack
  StandaloneLocalMtu: 1500
EOF

cat > /home/stack/containers-prepare-parameters.yaml << EOF
#
#   openstack tripleo container image prepare default --output-env-file /home/stack/containers-prepare-parameters.yaml
#

parameter_defaults:
  ContainerImageRegistryCredentials:
    registry.redhat.io:
      $RHNACC: "$RHNPASS"
  ContainerImagePrepare:
  - set:
      ceph_alertmanager_image: ose-prometheus-alertmanager
      ceph_alertmanager_namespace: registry.redhat.io/openshift4
      ceph_alertmanager_tag: 4.1
      ceph_grafana_image: rhceph-3-dashboard-rhel7
      ceph_grafana_namespace: registry.redhat.io/rhceph
      ceph_grafana_tag: 3
      ceph_image: rhceph-4-rhel8
      ceph_namespace: registry.redhat.io/rhceph
      ceph_node_exporter_image: ose-prometheus-node-exporter
      ceph_node_exporter_namespace: registry.redhat.io/openshift4
      ceph_node_exporter_tag: v4.1
      ceph_prometheus_image: ose-prometheus
      ceph_prometheus_namespace: registry.redhat.io/openshift4
      ceph_prometheus_tag: 4.1
      ceph_tag: latest
      ContainerImageRegistryLogin: true
      name_prefix: openstack-
      name_suffix: ''
      namespace: registry.redhat.io/rhosp-rhel8
      neutron_driver: ovn
      rhel_containers: false
      tag: '16.0'
    tag_from_label: '{version}-{release}'
EOF

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
EOF

# Configure name resolution
sudo cat >> /etc/resolv.conf << EOF
nameserver $NAMESERVER
EOF

# Update the system and reboot
sudo dnf -y update

sudo podman login registry.redhat.io -u $RHNACC -p $RHNPASS

sudo openstack tripleo deploy \
  --templates \
  --local-ip=$IP/$NETMASK \
  -e /usr/share/openstack-tripleo-heat-templates/environments/standalone/standalone-tripleo.yaml \
  -r /usr/share/openstack-tripleo-heat-templates/roles/Standalone.yaml \
  -e $HOME/containers-prepare-parameters.yaml \
  -e $HOME/standalone_parameters.yaml \
  --output-dir $HOME \
  --standalone
  
export OS_CLOUD=standalone
openstack endpoint list
