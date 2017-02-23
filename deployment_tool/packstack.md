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

## 深入理解Packstack

Packstack的使用非常简单，关于如何使用的介绍就到此结束。接下来才是重点，我们要深入到Packstack的核心逻辑: Plugin，并且举例说明如何编写Plugin来完成对Packstack的功能扩展。

### 什么是Plugin

在前面两章对于PuppetOpenstack modules的介绍中，所有服务的部署工作实际是由每个modules完成的。
在使用Packstack的时候，我们发现Packstack支持大量的服务部署，例如:nova,glance,maridb,amqp等等。在其背后每个服务的配置项管理都是由plugin实现的，其路径是在: packstack/plugins，它看起来是这样的：

  - __init__.py              
  - amqp_002.py              
  - aodh_810.py
  - ...
  - trove_850.py

每个plugin的名称都是由服务名称+下划线+三位数字编码组成，那么这些数字有什么作用？

我们来看一下packstack代码入口`packstack/installer/run_setup.py`是怎么加载plugins的:

在主函数入口，可以看到第一步调用了loadPlugins函数来加载插件：
```python
def main():
    options = ""

    try:
        # Load Plugins
        loadPlugins()   
        initPluginsConfig()
```

接着，我们跳转到了loadPlugins函数的定义，可以看到其中使用了sorted函数对由plugin文件组成的列表进行排序：
```python
def loadPlugins():
    """
    Load All plugins from ./plugins
    """
    sys.path.append(basedefs.DIR_PLUGINS)
    sys.path.append(basedefs.DIR_MODULES)

    fileList = [f for f in os.listdir(basedefs.DIR_PLUGINS) if f[0] != "_"]
    fileList = sorted(fileList, cmp=plugin_compare)  #使用plugin_compare函数作为key进行排序
    for item in fileList:
        # Looking for files that end with ###.py, example: a_plugin_100.py
        match = re.search("^(.+\_\d\d\d)\.py$", item)
        if match:
            try:
                moduleToLoad = match.group(1)
                logging.debug("importing module %s, from file %s", moduleToLoad, item)
                moduleobj = __import__(moduleToLoad)
                moduleobj.__file__ = os.path.join(basedefs.DIR_PLUGINS, item)
                globals()[moduleToLoad] = moduleobj
                checkPlugin(moduleobj)
                controller.addPlugin(moduleobj)
            except:
                logging.error("Failed to load plugin from file %s", item)
                logging.error(traceback.format_exc())
                raise Exception("Failed to load plugin from file %s" % item)
```

查看函数plugin_compare的定义，我们终于找到了关键，plugin_compare使用每个plugin文件尾缀的三位数字用于排序比较：

```python
def plugin_compare(x, y):
    """
    Used to sort the plugin file list
    according to the number at the end of the plugin module
    """
    x_match = re.search(".+\_(\d\d\d)", x)
    x_cmp = x_match.group(1)
    y_match = re.search(".+\_(\d\d\d)", y)
    y_cmp = y_match.group(1)
    return int(x_cmp) - int(y_cmp)
```

在了解了plugin的加载顺序后，我们再看看Plugin的代码结构。实际上，每个plugin的代码结构是一致的，由两个函数组成：

  - `initConfig(controller)`    用于初始化Plugin的配置，主要是参数和参数组。
  - `initSequences(controller)` 用于定义该plugin执行的任务。

在这些plugin中，必然会有一些与众不同的plugin，比如说第一个被加载的plugin，，倒数第二个被加载的plugin，以及最后一个被加载的plugin:

 - `prescript_000.py`是第一个被加载的plugin，顾名思义它提供了一些全局的初始化设置，比如ssh public key，default_password，workers的进程数量，是否开启各个OpenStack服务的设置等等，同时它会在被管理的主机上执行一些预备任务：生成authorized_keys文件，安装并开启epel源和rdo源，安装puppet软件包依赖和module依赖等等。
 - `puppet_950.py`是一个重要的plugin，顾名思义它提供了与puppet相关的任务，例如：生成最终的manifest文件，拷贝puppet modules到指定主机，生成hieradata文件，以standalone方式运行puppet：执行`puppet apply`，获取puppet运行中的输出等等。
 - `postscript_951.py`是最后一个呗加载的plugin，它只做了一件事情，就是运行Tempest跑测试任务。

### 动手写一个Plugin

在了解了plugin的运行机制后，我们来动手写一个plugin，我们称之为NOOP：这是一个空Plugin，默认只输出一行信息: NOOP Plugin.


#### 创建一个Plugin文件

在packstack/plugins目录下，我们创建一个plugin文件: noop_840.py。

#### 设置Import和Plugin定义

```python
# -*- coding: utf-8 -*-

"""
Installs and configures NOOP
"""

from packstack.installer import basedefs
from packstack.installer import validators
from packstack.installer import processors
from packstack.installer import utils

from packstack.modules.common import filtered_hosts
from packstack.modules.documentation import update_params_usage
from packstack.modules.ospluginutils import generate_ssl_cert

# ------------- NOOP Packstack Plugin Initialization --------------

PLUGIN_NAME = "NOOP"
PLUGIN_NAME_COLORED = utils.color_text(PLUGIN_NAME, 'blue')
```

每个Plugin的import可能会有所不同，但大多数都会用到packstack.installer和packstack.modules。

此外，这里有两个和plugin相关的变量：

 |变量|说明|
 | -- | -- |
 |PLUGIN_NAME|plugin名称，全部大写字母|
 |PLUGIN_NAME_COLORED|plugin显示的颜色，默认使用blue即可。|

#### 定义Plugin的配置信息

我们定义一个initConfig函数，其中包含了两个变量:
 - params
 - group

```python
def initConfig(controller):
    params = [
               {"CMD_OPTION": "enable-noop",
                "USAGE": "To set up noop service set this to 'y'",
                "PROMPT": "Would you like to set up noop service",
                "OPTION_LIST": ["y", "n"],
                "VALIDATORS": [validators.validate_options],
                "DEFAULT_VALUE": "n",
                "MASK_INPUT": False,
                "LOOSE_VALIDATION": True,
                "CONF_NAME": "CONFIG_ENABLE_NOOP",
                "USE_DEFAULT": False,
                "NEED_CONFIRM": False,
                "CONDITION": False},
             ]
    group = {"GROUP_NAME": "NOOP",
             "DESCRIPTION": "NOOP Config parameters",
             "PRE_CONDITION": "CONFIG_NOOP_INSTALL",
             "PRE_CONDITION_MATCH": "y",
             "POST_CONDITION": False,
             "POST_CONDITION_MATCH": True}
    controller.addGroup(group, params)
```

params是NOOP plugin定义的配置项，每个配置项的数据类型是字典。这些配置项可以作为顺序执行的一部分，或者作为Puppet模板的变量。

|选项|说明|
| -- | -- |
|CMD_OPTION|被命令行使用的选项名称|
|USAGE|选项的使用说明，同时作为answer file的注释|
|PROMPT|交互模式下给用户的提示|
|OPTION_LIST|可选值列表，可以设置为[]或移除该选项，表示对选项值无限制|
|VALIDATORS|验证器函数列表，用于检查输入是否符合要求|
|DEFAULT_VALUE|选项的默认值|
|PROCESSORS|处理器函数列表，处理器函数对用户的输入做了处理，比如processors.process_host将主机名转变为IP地址等等|
|MASK_INPUT| 是否隐藏用户的输入，如password|
|LOOSE_VALIDATION|若为true，则即使验证器返回为false，仍然使用用户输入的选项值|
|CONF_NAME|在answer file中的配置项名称，你同时可以在controller.CONF dict中找到|
|USE_DEFAULT|若为true,在交互模式下，将不会要求用户输入此变量的值，而直接DEFAULT_VALUE|
|NEED_CONFIRM|若为true，则要求用户确认其输入（比如password)|
|CONDITION|enable/disable该选项的条件,总是设置为False即可|
|DEPRECATES|弃用的CONF_NAME选项列表，通常在新版本时使用|

group表示组的概念，在Packstack中，会把相关的配置项分组，这样就可以通过组的方式来管理和使用。group的数据类型是字典:

|选项|说明|
| -- | -- |
|GROUP_NAME|组名，全局唯一|
|DESCRIPTION|组的描述，在命令行的帮助命令下会显示此信息|
|PRE_CONDITION|前提条件，可以是一个配置项的值或函数的返回值匹配预期。若为False，那么该配置组处于启用状态|
|PRE_CONDITION_MATCH|前提条件的预期匹配值|
|POST_CONDITION|配置组所有参数是正确的后置条件，若设置为False，则表示不做检查。通常设置为False|
|POST_CONDITION_MATCH|后置条件的预期匹配值，通常设置为True|

这里最重要的是PRE_CONDITION和PRE_CONDITION_MATCH，可能有些晦涩，我们以部署Cinder服务为例，只有当PRE_CONDITION中的变量CONFIG_CINDER_INSTALL为"y"时，才会显示"Cinder"组的配置选项:

```json
    {"GROUP_NAME": "CINDER",
     "DESCRIPTION": "Cinder Config parameters",
     "PRE_CONDITION": "CONFIG_CINDER_INSTALL",
     "PRE_CONDITION_MATCH": "y",
     "POST_CONDITION": False,
     "POST_CONDITION_MATCH": True
    }
```

最后一步，把这些已定义的选项添加controller的组中：

```python
controller.addGroup(group, params)
```

#### 定义函数执行顺序

前面我们说到每个plugin除了定义一组相关的选项之外，还会执行一些任务，比如：从用户给定的变量值来渲染template，从而生成该服务的Puppet manifest文件。这些任务是由一个个函数组成，函数之间有执行的先后顺序，这个顺序就是由initSeqeuence函数来决定。

我们假设NOOP服务的安装需要数据库服务MariaDB，以及在Keystone中创建endpoint等操作:

```python
def initSequences(controller):
    if controller.CONF['CONFIG_NOOP_INSTALL'] != 'y':
    return
    steps = [{'title': 'Adding MariaDB manifest entries',
             'functions': [create_mariadb_manifest]},
            {'title': 'Adding NOOP manifest entries',
             'functions': [create_manifest]},
            {'title': 'Adding NOOP Keystone manifest entries',
             'functions': [create_keystone_manifest]}]
controller.addSequence('Installing NOOP service', [], [], steps)
```

setps是一个列表，其中每个元素的数据类型都是字典，它的格式如下：                                                                                                   

|选项|说明|
| -- | -- |
|title|函数的简单描述信息|
|functions| 函数列表|

最后，我们调用controller.addSequence()方法把plugin的steps添加到将要被执行的序列列表中。
通常情况下，第二个和第二个选项为空。


#### 生成manifest文件
每个函数都是接受固定的两个参数:
 - config
 - messages


