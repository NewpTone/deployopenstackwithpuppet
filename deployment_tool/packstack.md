# Packstack


## 简介
Packstack主要是由Redhat推出的用于概念验证（PoC）环境快速部署的工具。Packstack是一个命令行工具，它使用Python封装了Puppet模块，通过SSH在服务器上部署OpenStack。

Packstack支持三种运行模式：
 - 快速运行
 - 交互式运行
 - 非交互式运行

Packstack支持两种部署架构：

 - All-in-One，即所有的服务部署到一台服务器上
 - Multi-Node，即控制节点和计算机分离
 
 
 因为Redhat官方有详细的使用文档，因此本文将简要介绍Packstack的快速运行以及交互式运行方式来部署All-in-One的Openstack。
 
 
 ## 部署前准备
 
 在开始部署前，我们需要准备一台虚拟机，它的规格如下：
 
 |名称|要求|
 | -- | -- |
 |处理器|推荐2核以上|
 |内存|推荐4G以上 |
 |磁盘|推荐20G以上|
 |网卡|至少一块1G网卡|
 |操作系统|CentOS7.2|
 
 
 在完成虚拟机的配置和启动后，在终端下输入以下指令： 
 ```shell
$ sudo yum install -y https://www.rdoproject.org/repos/rdo-release.rpm
$ sudo yum update -y
$ sudo yum install -y openstack-packstack
```
 
 
### 快速运行
 
 快速运行模式，表示用户可以对参数不做任何配置即可开始部署，用户只需要决定是单节点还是多节点的部署方式。
 
#### 单节点
 
 在packstack命令后，使用--allinonec参数在本机上部署所有服务。
 
 ```shell
$ packstack --allinone
 ```
 
#### 多节点
 
 使用--install-hostsc参数来运行packstack，该参数值是由一个逗号隔开的IP地址列表。
 
 ```shell
$ packstack --install-hosts=CONTROLLER_ADDRESS,NODE_ADDRESSES
 ```
 
 Packstack在部署完成后在终端上会输出以下信息：
 ```
 **** Installation completed successfully ******
 ```
 
### 交互式运行
 
1.如果希望以交互式的方式来配置集群的部署，可以在终端下输入：

```shell
# packstack
```

2.packstack会提示你输入一个用于保存公共密钥的路径，输入`Enter`，则
会使用默认的`~/.ssh/id_rsa.pub`：

```
Enter the path to your ssh Public key to install on servers:
```


3.packstack提示输入一个默认密码，该密码将作为admin user密码，
不输入则随机生成：

```
Enter a default password to be used. Leave blank for a randomly generated one. :
``` 

4.输入每个wsgi服务的进程数，默认等于cpu的核数：

```
Enter the amount of service workers/threads to use for each service. Leave blank to use the default. [%{::processorcount}] :
```

5.确认是否要安装MariaDB数据库,默认为y：

```
Should Packstack install MariaDB [y|n]  [y] :
```

6.确认是否安装Openstack组件，可以根据需要定制服务：

```
Should Packstack install OpenStack Image Service (Glance) [y|n]  [y] :
Should Packstack install OpenStack Block Storage (Cinder) [y|n]  [y] :
Should Packstack install OpenStack Shared File System (Manila) [y|n]  [n] :
Should Packstack install OpenStack Compute (Nova) [y|n]  [y] :
Should Packstack install OpenStack Networking (Neutron) [y|n]  [y] :
Should Packstack install OpenStack Dashboard (Horizon) [y|n]  [y] :
Should Packstack install OpenStack Object Storage (Swift) [y|n]  [y] :
Should Packstack install OpenStack Metering (Ceilometer) [y|n]  [y] :
Should Packstack install OpenStack Telemetry Alarming (Aodh) [y|n]  [y] :
Should Packstack install OpenStack Resource Metering (Gnocchi) [y|n]  [y] :
Should Packstack install OpenStack Clustering (Sahara). If yes it'll also install Heat. [y|n]  [n] :
Should Packstack install OpenStack Orchestration (Heat) [y|n]  [n] :
Should Packstack install OpenStack Database (Trove) [y|n]  [n] :
Should Packstack install OpenStack Bare Metal (Ironic) [y|n]  [n] :
Should Packstack install OpenStack client tools [y|n]  [y] :
```

7.Packstack为所有服务配置NTP服务来校准系统时间，NTP的设置只对多节点有意义：
```
Enter a comma separated list of NTP server(s). Leave plain if Packstack should not install ntpd on instances:
```

8.是否安装Nagios监控服务：

```
Should Packstack install Nagios to monitor OpenStack hosts [y|n]  [y] :
```

9.哪些服务器在本次安装中被排除在外：

```
Enter a comma separated list of server(s) to be excluded. Leave plain if you don't need to exclude any server.:
```
10.是否启用调试模式：

```
Do you want to run OpenStack services in debug mode [y|n]  [n] :
```

11.指定控制器的地址:

```
Enter the controller host  [10.211.55.8] :
```
12.指定计算节点的地址：

```
Enter list of compute hosts  [10.211.55.8] :
```

13.指定网络节点的地址：

```
Enter list of network hosts  [10.211.55.8] :
```

14.是否使用VMWare vCenter作为hypervisor和datastore的后端：

```
Do you want to use VMware vCenter as hypervisor and datastore [y|n]  [n] :
```

15.指定是否使用不支持的参数，推荐使用默认设置：

```
Enable this on your own risk. Do you want to use unsupported parameters [y|n]  [n] :
```

16.网卡名称是否被自动识别为子网+CIDR的格式：
```
Should interface names be automatically recognized based on subnet CIDR [y|n]  [n] :
```
17.是否为每个服务器订阅Extra Packstacks for Enterprise Linux(EPEL)，建议使用默认设置：
```
To subscribe each server to EPEL enter "y" [y|n]  [n] :
```

18.是否启用自定义的软件包仓库:

```
Enter a comma separated list of URLs to any additional yum repositories to install:
```

19.是否启用rdo test：

```
To enable rdo testing enter "y" [y|n]  [n] :
```

20.是否启用Red Hat订阅，跳过即可：
```
To subscribe each server to Red Hat enter a username :
To subscribe each server with RHN Satellite enter RHN Satellite server URL:
```

21.ssl证书相关的操作：
```
Enter the filename of the SSL CAcertificate, if the CONFIG_SSL_CACERT_SELFSIGN is set to y the path will be CONFIG_SSL_CERT_DIR/certs/selfcert.crt  [/etc/pki/tls/certs/selfcert.crt] :
Enter the filename of the SSL CAcertificate Key file, if the CONFIG_SSL_CACERT_SELFSIGN is set to y the path will be CONFIG_SSL_CERT_DIR/keys/selfkey.key  [/etc/pki/tls/private/selfkey.key] :
Enter the path to use to store generated SSL certificates in  [~/packstackca/] :
Should packstack use selfsigned CAcert. [y|n]  [y] :
Enter the ssl certificates subject country.  [--] :
Enter the ssl certificates subject state.  [State] :
Enter the ssl certificate subject location.  [City] :
Enter the ssl certificate subject organization.  [openstack] :
Enter the ssl certificate subject organizational unit.  [packstack] :
Enter the ssl certificaate subject common name.  [centos-7.1.shared] :
Enter the ssl certificate subject admin email.  [admin@centos-7.1.shared] :
```

22.配置AMQP服务，默认会使用RabbitMQ作为backend，不启用身份验证和SSL：

```
Set the AMQP service backend [rabbitmq]  [rabbitmq] :
Enter the host for the AMQP service  [10.211.55.8] :
Enable SSL for the AMQP service? [y|n]  [n] :
Enable Authentication for the AMQP service? [y|n]  [n] :
```

23.配置MariaDB服务

```
Enter the IP address of the MariaDB server  [10.211.55.8] :
Enter the password for the MariaDB admin user :
Confirm password :
```

24.配置Identity服务，包括设置数据库连接的密码，创建默认的admin,demo用户等基本操作：

```
Enter the password for the Keystone DB access :
Confirm password :
Enter y if cron job for removing soft deleted DB rows should be created [y|n]  [y] :
Confirm password [y|n]  [y] :
Region name  [RegionOne] :
Enter the email address for the Keystone admin user  [root@localhost] :
Enter the username for the Keystone admin user  [admin] :
Enter the password for the Keystone admin user :
Confirm password :
Enter the password for the Keystone demo user :
Confirm password :
Enter the Keystone identity backend type. [sql|ldap]  [sql] :
```
25.配置Image服务，包括设置数据库连接密码，glance用户密码，后端存储：

```
Enter the password for the Glance DB access :
Confirm password :
Enter the password for the Glance Keystone access :
Confirm password :
Glance storage backend [file|swift]  [file] :
```

26.配置块存储服务，包括设置数据库连接密码，cinder用户和密码:

```
Enter the password for the Cinder DB access :
Confirm password :
Enter y if cron job for removing soft deleted DB rows should be created [y|n]  [y] :
Confirm password [y|n]  [y] :
Enter the password for the Cinder Keystone access :
Confirm password :
Enter the Cinder backend to be configured [lvm|gluster|nfs|vmdk|netapp|solidfire]  [lvm] :
Should Cinder's volumes group be created (for proof-of-concept installation)? [y|n]  [y] :
Enter Cinder's volumes group usable size  [20G] :
Enter y if cron job for removing soft deleted DB rows should be created [y|n]  [y] :
Confirm password [y|n]  [y] :
```

27.配置计算服务，包括flavor,资源虚拟比，迁移，虚拟化软件等参数的设置：

```
Should Packstack manage default Nova flavors [y|n]  [y] :
Enter the CPU overcommitment ratio. Set to 1.0 to disable CPU overcommitment  [16.0] :
Enter the RAM overcommitment ratio. Set to 1.0 to disable RAM overcommitment  [1.5] :
Enter protocol which will be used for instance migration [tcp|ssh]  [tcp] :
Enter the compute manager for nova migration  [nova.compute.manager.ComputeManager] :
Enter the path to a PEM encoded certificate to be used on the https server, leave blank if one should be generated, this certificate should not require a passphrase:
Enter the SSL keyfile corresponding to the certificate if one was entered:
Enter the PCI passthrough array of hash in JSON style for controller eg. [{'vendor_id':'1234', 'product_id':'5678', 'name':'default'}, {...}] :
Enter the PCI passthrough whitelist as array of hash in JSON style for controller eg. [{'vendor_id':'1234', 'product_id':'5678', 'name':'default'}, {...}]:
The nova hypervisor that should be used. Either qemu or kvm. [qemu|kvm]  [%{::default_hypervisor}] :
Confirm password [qemu|kvm]  [%{::default_hypervisor}] :
```

28.配置网络服务，包括从组件，接口，网络驱动等细节的设置：
```
Enter the password for Neutron Keystone access :
Confirm password :
Enter the password for Neutron DB access :
Confirm password :
Enter the ovs bridge the Neutron L3 agent will use for external traffic, or 'provider' if using provider networks.  [br-ex] :
Enter Neutron metadata agent password :
Confirm password :
Should Packstack install Neutron LBaaS [y|n]  [n] :
Should Packstack install Neutron L3 Metering agent [y|n]  [y] :
Would you like to configure neutron FWaaS? [y|n]  [n] :
Would you like to configure neutron VPNaaS? [y|n]  [n] :
Enter a comma separated list of network type driver entrypoints [local|flat|vlan|gre|vxlan]  [vxlan] :
Enter a comma separated ordered list of network_types to allocate as tenant networks [local|vlan|gre|vxlan]  [vxlan] :
Enter a comma separated ordered list of networking mechanism driver entrypoints [logger|test|linuxbridge|openvswitch|hyperv|ncs|arista|cisco_nexus|mlnx|l2population|sriovnicswitch]  [openvswitch] :
Enter a comma separated  list of physical_network names with which flat networks can be created  [*] :
Enter a comma separated list of physical_network names usable for VLAN:
Enter a comma separated list of <tun_min>:<tun_max> tuples enumerating ranges of GRE tunnel IDs that are available for tenant network allocation:
Enter a multicast group for VXLAN:
Enter a comma separated list of <vni_min>:<vni_max> tuples enumerating ranges of VXLAN VNI IDs that are available for tenant network allocation  [10:100] :
Enter the name of the L2 agent to be used with Neutron [linuxbridge|openvswitch]  [openvswitch] :
Enter a comma separated list of supported PCI vendor devices, defined by vendor_id:product_id according to the PCI ID Repository.  [['15b3:1004', '8086:10ca']] :
Set to y if the sriov agent is required [y|n]  [n] :
Enter a comma separated list of interface mappings for the Neutron ML2 sriov agent:
Enter a comma separated list of bridge mappings for the Neutron openvswitch plugin:
Enter a comma separated list of OVS bridge:interface pairs for the Neutron openvswitch plugin:
Enter a comma separated list of bridges for the Neutron OVS plugin in compute nodes. They must be included in os-neutron-ovs-bridge-mappings and os-neutron-ovs-bridge-interfaces.:
Enter interface with IP to override the default tunnel local_ip:
Enter comma separated list of subnets used for tunneling to make them allowed by IP filtering.:
Enter VXLAN UDP port number  [4789] :
```
29.设置Dashboard服务，是否开启Https服务：

```
Would you like to set up Horizon communication over https [y|n]  [n] :
```

30.配置对象存储服务,包括设备逻辑，zone，replicas,文件系统和块设备大小的配置：

```
Enter the Swift Storage devices e.g. /path/to/dev:
Enter the number of swift storage zones, MUST be no bigger than the number of storage devices configured  [1] :
Enter the number of swift storage replicas, MUST be no bigger than the number of storage zones configured  [1] :
Enter FileSystem type for storage nodes [xfs|ext4]  [ext4] :
Enter the size of the storage device (eg. 2G, 2000M, 2000000K)  [2G] :
```

31.是否启用Tempest服务:

```
Would you like to provision for demo usage and testing [y|n]  [y] :
Would you like to configure Tempest (OpenStack test suite). Note that provisioning is only supported for all-in-one installations. [y|n]  [n] :
```

32.设置Floating IP网段

```
Enter the network address for the floating IP subnet  [172.24.4.224/28] :
```

33.设置测试镜像的名称，源地址，格式等配置：

```
Enter the name to be assigned to the demo image  [cirros] :
Enter the location of an image to be loaded into Glance  [http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img] :
Enter the format of the demo image  [qcow2] :
Enter the name of a user to use when connecting to the demo image via ssh  [cirros] :
Enter the name to be assigned to the uec image used for tempest  [cirros-uec] :
Enter the location of a uec kernel to be loaded into Glance  [http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-kernel] :
Enter the location of a uec ramdisk to be loaded into Glance  [http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-initramfs] :
Enter the location of a uec disk image to be loaded into Glance  [http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img] :
Would you like to configure the external ovs bridge [y|n]  [y] :
```

34.设置Ceilometer,Aodh,Gnocchi服务：

```
Enter the password for Gnocchi DB access :
Confirm password :
Enter the password for the Gnocchi Keystone access :
Confirm password :
Enter the password for the Ceilometer Keystone access :
Confirm password :
Enter the Ceilometer service name. [ceilometer|httpd]  [httpd] :
Enter the host for the MongoDB server  [10.211.55.8] :
Enter the host for the Redis server  [10.211.55.8] :
Enter the port of the redis server(s)  [6379] :
Enter the password for the Aodh Keystone access :
Confirm password :
```

35.设置nagios用户的密码:

```
Enter the password for the nagiosadmin user :
```

36.最后一步，确认生成的配置是否符合期望，输入`yes`，并按`回车`键开始执行操作：
```
Packstack will be installed using the following configuration:
==============================================================
ssh-public-key:                /root/.ssh/id_rsa.pub
default-password:
service-workers:               %{::processorcount}
mariadb-install:               y
......
aodh-ks-passwd:                ********
nagios-passwd:                 ********
Proceed with the configuration listed above? (yes|no):
```

### 非交互式方式运行

使用下述命令生成一个answer file:

```shell
# packstack --gen-answer-file=my_file
```

使用vim打开文件,每个配置项都含有详细的说明：
```
[general]

# Path to a public key to install on servers. If a usable key has not
# been installed on the remote servers, the user is prompted for a
# password and this key is installed so the password will not be
# required again.
CONFIG_SSH_KEY=/root/.ssh/id_rsa.pub

# Default password to be used everywhere (overridden by passwords set
# for individual services or users).
CONFIG_DEFAULT_PASSWORD=

# The amount of service workers/threads to use for each service.
# Useful to tweak when you have memory constraints. Defaults to the
# amount of cores on the system.
CONFIG_SERVICE_WORKERS=%{::processorcount}

# Specify 'y' to install MariaDB. ['y', 'n']
CONFIG_MARIADB_INSTALL=y

# Specify 'y' to install OpenStack Image Service (glance). ['y', 'n']
CONFIG_GLANCE_INSTALL=y

......
```
例如，我们不希望配置MariaDB，只需要将`CONFIG_MARIADB_INSTALL`设置为`n`:

```
CONFIG_MARIADB_INSTALL=n
```
保存并退出my_file，在终端下运行以下命令指定相应的配置文件：

```shell
# packstack --answer-file=my_file
```
