# puppet-designate

1. [基础知识—快速了解designate](＃基础知识)

2. [先睹为快—一言不合，立马动手？](＃先睹为快)

3. [核心代码－如何管理designate服务](＃核心代码讲解)

4. [小结](#小结)

5. [动手练习](#动手练习)


**本节作者：薛飞扬**

**阅读级别：选读**

**建议阅读时间 2小时**

## 基础知识

### Designate介绍

OpenStack Designate提供了DNSaaS（DNS即服务）的功能，其目标就是要赋予OpenStack提供这种云域名系统的能力，云服务商可以使用Designate就能够很容易建造一个云域名管理系统来托管租户的公有域名。

Designate的架构图如下：

![](../images/designate/designate-architecture.png)

| 包含的服务 | 简 |
| --- | --- |
| designate-api | 接收来自远端用户的HTTP/HTTPS请求，通过Keystone验证远端用户的合法性，将HTTP/HTTPS请求传递给Central模块。 |
| designate-central | 业务逻辑处理核心。响应API请求以及处理Sink所监听到的来自Nova和Neutron的特定通知事件。同时会存取数据库，对业务逻辑处理所产生的数据进行持久化存储。 |
| designate-mdns | 实现了标准的DNS Notify和Zone Transfer的处理。 |
| designate-pool-manager | 连接后端驱动，管理DNS服务器池，与MiniDNS配合同步DNS服务器的域名以及资源记录等数据。 |
| designate-sink | 监听来自Nova和Neutron的某些事件，用于自动生成域名资源记录，比如当监听到Nova的compute.instance.create.end事件通知后，自动创建一条对应于刚创建的实例的A记录；当监听到Nuetron的floatingip.update.end事件通知后，自动更新一条相应的A记录。 |

### DNS服务器的池划管理

Designate kilo版本所引入的pool manager机制将DNS服务器群划分成多个服务器池（pool），如下图所示，每个服务器池可以配置包含1台或多台DNS服务器。而且，池中的DNS服务器选型还可以不同，也就是说在一个服务器池中，可以有1台BIND服务器，还可以有1台PowerDNS服务器，这是完全支持的。

![](../images/designate/designate-pool.png)

服务器池的引入目的：

1. 细化域名托管的颗粒度。用户请求托管的域名可以委派到某一个服务器池，而不需要在所有服务器上管理用户的域名和资源记录，降低了管理和运维的复杂度。例如，abc.com委派给pool 1的DNS服务器来管理，xyz.com委派到pool N的DNS服务器来管理，……
2. 每个服务器池可以包含多台DNS服务器，实现了高可用性和冗余备份。
3. 服务器池的划分不受地域的限制，可以将分布在不同地域的DNS服务器划归到同一个池中，通过GLB和anycast路由技术可以实现就近DNS查询和负载均衡，加快DNS查询速度。

官方文档上给了一个多个池的使用场景：

The idea is that we’ll configure our pools to support different usage levels. We’ll define a gold and standard level and put zones in each based on the tenant.

Our gold level will provide 6 nameservers that users have access to where our standard will only provide 2. Both pools will have one master target we write to.
即通过配置不同的池来支持不同的用户等级。

黄金等级的池提供6个nameservers ，而标准等级的池只提供两个。

在mitaka版本，实现了CLI的方法来更新池,即通过创建一个yaml文件来定义池,然后通过desigante-manage来更新池，这里贴出一个池的yaml文件,仅供参考：

```
- name: default

 # The name is immutable. There will be no option to change the name after

 # creation and the only way will to change it will be to delete it

 # (and all zones associated with it) and recreate it.

 description: Default PowerDNS Pool


 # Attributes are Key:Value pairs that describe the pool. for example the level

 # of service (i.e. service_tier:GOLD), capabilities (i.e. anycast: true) or

 # other metadata. Users can use this information to point their zones to the

 # correct pool

 attributes: {}


 # List out the NS records for zones hosted within this pool

 ns_records:

 - hostname: ns1-1.example.org.

 priority: 1

 - hostname: ns1-2.example.org.

 priority: 2


 # List out the nameservers for this pool. These are the actual PowerDNS

 # servers. We use these to verify changes have propagated to all nameservers.

 nameservers:

 - host: 192.0.2.2

 port: 53

 - host: 192.0.2.3

 port: 53


 # List out the targets for this pool. For PowerDNS, this is the database

 # (or databases, if you deploy a separate DB for each PowerDNS server)

 targets:

 - type: powerdns

 description: PowerDNS Database Cluster


 # List out the designate-mdns servers from which PowerDNS servers should

 # request zone transfers (AXFRs) from.

 masters:

 - host: 192.0.2.1

 port: 5354


 # PowerDNS Configuration options

 options:

 host: 192.0.2.1

 port: 53

 connection: 'mysql+pymysql://designate:password@127.0.0.1/designate_pdns?charset=utf8'


 # Optional list of additional IP/Port's for which designate-mdns will send

 # DNS NOTIFY packets to

 also_notifies:

 - host: 192.0.2.4

 port: 53


```

## 先赌为快

在讲解designate模块之前让我们先使用puppet把我们的实验环境部署起来,请根据你的具体环境修改learn_designate.pp

```puppet

 include '::rabbitmq'

 include '::mysql::server'

＃创建database和user
 class {'::designate::db::mysql':

   password => $designate_db_password,

 }
＃创建designate group 和user,安装openstack-designate-common包,修改配置文件中rabbitmq的相关内容
 class {'::designate':

   rabbit_host     => $rabbit_host,

   rabbit_userid   => $rabbit_userid,

   rabbit_password => $rabbit_password,

 }

 include '::designate::dns'

 ＃配置designate的后端DNS服务器为bind9，安装bind9包，运行named服务，更改rndc的相关配置

 include '::designate::backend::bind9'

 class {'::designate::db':

   database_connection => "mysql://designate:${designate_db_password}@${db_host}/designate"

 }

 ＃populate designate database 

 include '::designate::db::sync'

＃下面四个class对应desigante的api,central,mdns,pool-manager四个服务

 class {'::designate::api':

   auth_strategy => $auth_strategy,

 }

 class {'::designate::central':

   backend_driver => $backend_driver,

 }

 include '::designate::mdns'

 class {'::designate::pool_manager': 

   pool_id => $pool_id, 

 }

```

在终端执行以下命令:

```
puppet apply -v learn_designate.pp
```

ok，接下来快创建一个domain试试吧。

```bash
designate domain-create --name example.com. --email root@example.com

designate domain-list
```

## 核心代码讲解

### backend

Designate backend支持如BIND，PowerDNS等多种类型的DNS服务器，下面只以BIND为例来讲解

Designate backend 如果使用应用最为广泛的bind，designate会利用RNDC指令来管理DNS伺服器，所以需要更改rndc的相关配置

```puppet
class designate::backend::bind9 (

 $rndc_host = '127.0.0.1',

 $rndc_port = '953',

 $rndc_config_file = '/etc/rndc.conf',

 $rndc_key_file = '/etc/rndc.key'

) {

 include ::designate
＃安装bind相关的包，更改bind相关配置项
 include ::dns

＃配置rndc监听的host,port,config和key的目录
 designate_config {

 'backend:bind9/rndc_host' : value => $rndc_host;

 'backend:bind9/rndc_port' : value => $rndc_port;

 'backend:bind9/rndc_config_file' : value => $rndc_config_file;

 'backend:bind9/rndc_key_file' : value => $rndc_key_file;

 }


＃更改named.conf(或者named.options)文件，允许创建新的zone
 concat::fragment { 'dns allow-new-zones':

 target => $::dns::optionspath,

 content => 'allow-new-zones yes;',

 order => '20',

 }

}

```

puppet-designate的安装简单来说做了三件事：

* 后端DNS服务器的安装和配置，这一点上面已经有过讲解
* designate相关软件包的安装

```puppet

package { 'designate-common':

 ensure => $package_ensure,

 name => $common_package_name,

 tag => ['openstack', 'designate-package'],

 }

designate::generic_service { 'api':

 enabled => $enabled,

 manage_service => $service_ensure,

 ensure_package => $package_ensure,

 package_name => $api_package_name,

 service_name => $::designate::params::api_service_name,

 }
...

```

* desingate配置文件的管理
  除了权限的相关配置，其它的配置项都在/etc/designate/designate.conf中
  [oslo_messaging_rabbit]下面是rabbitmq的相关参数，由class designate管理：

```

designate_config {

 'oslo_messaging_rabbit/rabbit_userid' : value => $rabbit_userid;

 'oslo_messaging_rabbit/rabbit_password' : value => $rabbit_password, secret => true;

 'oslo_messaging_rabbit/rabbit_virtual_host' : value => $rabbit_virtual_host_real;

 'oslo_messaging_rabbit/rabbit_use_ssl' : value => $rabbit_use_ssl;

 'oslo_messaging_rabbit/kombu_ssl_ca_certs' : value => $kombu_ssl_ca_certs;

 'oslo_messaging_rabbit/kombu_ssl_certfile' : value => $kombu_ssl_certfile;

 'oslo_messaging_rabbit/kombu_ssl_keyfile' : value => $kombu_ssl_keyfile;

 'oslo_messaging_rabbit/kombu_ssl_version' : value => $kombu_ssl_version;

 'oslo_messaging_rabbit/kombu_reconnect_delay' : value => $kombu_reconnect_delay;

 }
```

［service:api］  [service:central]  [serivce:mdns] [service:pool_manager] 中的配置项分别由class designate::api designate::central designate::mdns designate::manager管理

## 小结

puppet-designate需要配置的文件仅有designate.conf，为了方便管理与配置，puppet把使用到的四个服务都分别写为了一个.pp的类，这样也方便我们管理这些配置项。这里讲解到功能没有涉及到跟nova，neutron的集成，集成之后的效果是当创建虚拟机或创建浮动IP后，创建的虚拟机或浮动ip的A记录记录会自动同步相应的zone 中 ，有兴趣的同学可以在官网查看。

## 动手练习

1.部署分布式的backend后端，并使用不同的DNS Server（BIND,PowerDNS,MysqlBIND）作存储后端。

2.手动配置多个pool,不同的pool管理的各自的DNS Server(通过创建yaml文件，使用designate-manage命令实现)。

3.安装designate-sink服务，修改nova.conf和neutron.conf相应配置，创建虚拟机或floating ip  ，观察designate record的变化。

