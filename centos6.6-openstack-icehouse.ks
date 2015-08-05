# kickstart template for Fedora 8 and later.
# (includes %end blocks)
# do not use with earlier distros
#
#Maintained by Ananthan and Phijo
#
#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
bootloader --location=mbr
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --disabled
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here
repo --name=epel --baseurl=https://dl.fedoraproject.org/pub/epel/6/x86_64/
repo --name=updates --baseurl=http://mirror.rackspace.com/CentOS/6.6/updates/x86_64/
repo --name=extras --baseurl=http://mirror.rackspace.com/CentOS/6.6/extras/x86_64/
repo --name=rdo --baseurl=http://repos.fedorapeople.org/repos/openstack/openstack-icehouse/epel-6/
# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot

#Root password
rootpw 1
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  America/New_York
bootloader --location=mbr --driveorder=sda --append="crashkernel=auto elevator=deadline quiet"
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr

# Disk  partition with a disk size of 300G Min
part /boot --fstype=ext4 --size=500
part pv.01 --size=1 --grow
volgroup VGCompute --pesize=4096 pv.01
logvol /home --fstype=ext4 --name=LV_Home --vgname=VGCompute --size=4096
logvol / --fstype=ext4 --name=LV_Root --vgname=VGCompute --size=31248
logvol swap --name=LV_Swap --vgname=VGCompute --size=4096
logvol /var --fstype=ext4 --name=LV_Var --vgname=VGCompute --size=207872

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages --nobase
@core
ntp
epel-release
rdo-release-icehouse-4
wget

##required for ansible
libselinux-python

##helpful for troubleshooting:
tcpdump
dstat

##Openstack packages
openstack-selinux
openstack-nova-compute
openstack-nova-network
openstack-nova-api

#$SNIPPET('func_install_if_enabled')
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
#/sbin/chkconfig libvirtd  on
#/sbin/chkconfig dbus on

##Disable SElinux
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

##Enable IP Forwarding
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf

##Required for Ansible password less login.Pulling Public Key
mkdir -p /root/.ssh ; chmod 700 /root/.ssh ; wget $key/authorized_keys --directory-prefix=/root/.ssh;chmod 400 /root/.ssh/authorized_keys

##Getting /etc/hosts of controller which needs to be pre populated to cobbler server webdirectory simillar to above:
rm -rf /etc/hosts
wget $key/hosts --directory-prefix=/etc

##Updating NTP to use local NTP server:
rm -rf /etc/ntp.conf
wget $key/ntp.conf  --directory-prefix=/etc

##Updating openstack configurations:
mv /etc/nova/nova.conf /etc/nova/nova.conf-org
wget $key/nova.conf  --directory-prefix=/etc/nova

##setting service to start in next boot
/sbin/chkconfig ntpd on
/sbin/chkconfig libvirtd on
/sbin/chkconfig dbus on

$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps
%end
