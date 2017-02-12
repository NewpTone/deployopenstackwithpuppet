# Puppet-sahara模块介绍

1. [基础知识 - 欲知部署之必先了解之](#基础知识)
    - [1.1 Why Sahara?](##Why Sahara)
    - [1.2 Sahara的几个概念](##Sahara的几个概念)
    - [1.3 Sahara组件介绍](##Sahara组件介绍)
    - [1.4 谈谈Sahara部署](##谈谈Sahara部署)
2. [先睹为快 - 一言不合，立马动手?](#先睹为快)
3. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
    - [3.1 Openstack服务部署套路](##Openstack服务部署套路)
    - [3.2 数据库配置](##数据库配置)
    - [3.3 Sahara服务认证配置](##Sahara服务认证配置)
    - [3.4 Sahara配置管理](##Sahara配置管理)
    - [3.5 Sahara服务安装和启动](##Sahara服务安装和启动)
4. [小结](#小结)
5. [动手练习 - 光看不练假把式](#动手练习)

**本节作者：付广平**

**建议阅读时间 2h**

#基础知识

##Why Sahara

近年来大数据可谓如火如荼，哪个企业不说搞大数据都要被嘲讽技术落后，程序员不张口闭口MapReduce、Nosql都不敢说自己学计算机的。而谈到大数据就必然提到Hadoop/Spark，似乎谈大数据就等价于说Hadoop/Spark。

如今Hadoop再也不是当初的HDFS、MapReduce、Hbase这么简单了，现在大家谈的Hadoop往往表示的是一个庞大的Hadoop生态圈，包括了YARN、Spark、Sqoop、Hive、Impara、Alluxio等组件。面对如此庞大复杂的分布式系统，面临的首要挑战问题就是如何快速、高效部署和维护。

当面临小规模集群时，我们也许并不需要构建一套复杂的自动化部署工具，只需要从官方下载jar包分发到集群的各个节点，手动一一配置即可完成简单Hadoop集群部署。Hadoop部署非常灵活的同时也造成部署架构复杂，并且一旦规模大时，手动部署方式往往捉襟见肘，调试和维护难度系数直线上升。

面临以上集群部署和维护的诸多痛点问题，很多公司基于社区版本开发了自己的Hadoop产品发行版以及一套完整的自动化部署工具，这些工具不仅能够支持节点自动发现以及可视化部署，还能实时监控集群的健康状态。主流的包括Cloudera公司开发的cloudera-manager工具，支持在Web页面快速部署大规模CDH集群，Hortonworks公司开发的Ambari工具也支持在Web页面上交互来完成HDP集群的部署。这些工具大大简化了部署和监控流程，降低了维护成本。

以上工具虽然很好地完成了Hadoop集群的自动化部署和监控，但其部署工具本身往往还需要手动部署，并且直接构建在物理集群之上，难以实现资源的按需使用以及弹性扩展，也不利于通过云服务的形式快速交付。

Openstack Sahara旨在基于IaaS之上自动化部署Hadoop集群，不仅支持原生Hadoop、Spark、Storm的快速部署，还集成了目前主流的部署工具，比如前面提到的cloudera-manager以及Ambari。也就是说，通过Sahara能够分分钟部署一个CDH或者HDP集群。

不仅如此，Sahara还实现了MapReduce即服务的接口，通过Sahara API能够在Web页面上方便地创建DataSource，然后通过表单上传Jar包即可提交Hadoop Job，使开发者只需要专注于业务开发本身，而不需要关注底层实现，大大提高了开发效率。

Sahara是Openstack的高层服务，构建在Nova、Cinder、Neutron、Heat等服务之上。本章接下来将重点讨论如何在Openstack平台上部署Sahara组件。

##Sahara的几个概念

本小节简单介绍下Sahara涉及的几个概念，主要针对感兴趣的读者能够快速了解Sahara，这些内容和部署关系不大，读者可直接跳过本节。

Sahara主要包含以下几个概念:

* Plugin：即Hadoop集群插件，不同的发行版和版本插件不同，如创建CDH集群使用cdh插件、创建Spark使用spark插件等，类似于驱动（driver）的概念。
* Image：Sahara创建集群的每一个节点其实都是一台虚拟机，Image即指定虚拟机使用的镜像，不同的插件对应的镜像不同，使用前必须和插件绑定，即注册镜像。通常每个插件的镜像都会包含CentOS和Ubuntu两种版本镜像。
* Node Group Template：节点模板，即定义虚拟机模板，主要包含以下内容:
  * 插件：定义使用的Hadoop集群发行版和版本。
  * 资源：该节点使用的Flavor、Availability Zone、volume卷大小、安全组等。
  * 进程组：定义该节点启动什么服务，比如namenode，datanode，spark-master,spark-slave,hue。
  * Hadoop配置参数：比如hdfs_client_java_heapsize,hadoop_job_history_dir等，不同的发行版配置项不同。
* Cluster Template：集群模板，定义集群拓扑和规模大小，集群模板由Node Group Template组合而成，定义一个集群由几个datanode、几个spark-worker构成等，同时还定义Hadoop的一些配置信息，比如HDFS副本数等。
* Cluster：集群实例，已经创建的实例，集群实例由集群模板创建。集群实例还支持扩容和缩容操作，增加或者减少node个数。

##Sahara组件介绍

欲知如何部署Sahara，首先需要了解Sahara包含的组件以及模块。和Openstack其它大多数服务一样，Sahara同样需要依赖于消息队列、数据库等基础组件。

最开始Sahara只包含sahara-api一个服务，负责响应用户请求、访问数据库、创建集群等所有工作，造成单服务负载过高并且缺乏HA支持。社区于是提出了下一代架构(https://wiki.openstack.org/wiki/Sahara/NextGenArchitecture)，新架构把sahara-api拆分成两个服务:

* sahara-api: 和大多数Openstack API服务类似，主要为用户提供RESTFul API接口。
* sahara-engine: 负责执行用户的各项任务，包括创建集群和提交用户提交的Job等。

访问数据库也单独分离出了一个独立的模块，称之为sahara-conductor，但注意和nova-conductor不一样，它只是一个模块，而不是一个服务，后期可能会发展成一个独立的服务来接管数据库访问工作。

Sahara官方的新架构图如下:

![sahara architecture](../images/sahara/sahara_architecture.png)

Sahara服务相对来说还是比较简单的，只包含sahara-api和sahara-engine两个服务。下一小节中将开始介绍sahara的部署问题。

##谈谈Sahara部署

前面提到sahara服务相对简单，但不得不说，部署起来却大小坑不计其数。Sahara的工作原理本不应该在这里提及，但在不了解其工作原理的前提下部署Sahara，可以毫不夸张地说: No Way!

由于篇幅有限，对Sahara工作原理感兴趣的读者可以参考官方文档或者阅读源码，本文给出的简化工作流程仅供参考:

* 验证集群。主要检查集群模板是否合法，比如HDFS没有部署namenode、datanode数少于HDFS副本数等都属于不合法的集群。
* 调用Heat创建资源，比如虚拟机、网络、volume、安全组等。
* 通过ssh配置集群并启动集群服务，配置工作包括更新hosts文件、修改Hadoop xml文件等，启动服务如ResourceManager、NodeManager、Datanode、Namenode等等。
* 若集成的是厂商部署工具，则还需要调用其API部署集群，比如调用Cloudera-manager RESTFul API创建集群等。
* 等待所有服务启动完成后，集群创建完成。

从以上步骤可知，**Sahara部署前必须先部署Heat服务**，在M版本后这是必需的，M版之前可以使用direct engine，目前已经被彻底废弃。

sahara-engine是通过ssh连接虚拟机完成集群配置的，**因此sahara-engine必须能够和虚拟机所在网络连通。**

目前sahara-engine连通虚拟机的方式有以下几种:

* flat private network，这种方式不支持Neutron网络，不考虑。
* floating IPs，即给所有虚拟机分配公有IP，通过公有IP访问虚拟机。
* network namespace，通过网络命名空间访问虚拟机，sahara-engine必须部署在网络节点，且不支持多网络节点情况(想想为什么？)。
* agent模式，这个尚未实现，主要想参考Trove的agent模式，通过消息队列通信。

以上4种方式其实只有中间两种方式可用，但若集成厂商的Hadoop发行版部署工具并且需要调用厂商工具API部署集群的情况，不支持network namespace模式，因为即使能通过进入netns方式ssh连接虚拟机，也不可能调用虚拟机内部的API服务（除非打通管理网和虚拟机网络）。**简而言之，CDH和HDP不支持netns模式。**

**因此，若要通过Sahara部署CDH或者HDP集群，请使用floating IPs模式，并开启虚拟机自动分配floating ip功能。**

Sahara大多数配置项和其它服务类似，比如日志配置、RabbitMQ配置、认证配置等等，Sahara专有的需要注意的配置项如下(均在`/etc/sahara/sahara.conf`的`DEFAULT`配置组):

* `use_floating_ips`: 若sahara-engine配置使用浮动IP访问虚拟机，则需要设置为`True`，此时建议配置nova配置项`auto_assign_floating_ip`为`True`，否则创建集群时堵塞直到用户手动分配浮动IP。
* `use_neutron`: 使用Neutron网络设置为`True`，否则若使用废弃的`nova-network`设置为`False`。
* `use_namespaces`: 若sahara-engine使用network namespace方式访问虚拟机，需要设置该配置项为`True`。
* `use_rootwrap`: 该配置项需要设置为`True`，否则ssh连接虚拟机时出错。
* `rootwrap_command`： 设置为`"sudo sahara-rootwrap /etc/sahara/rootwrap.conf"`，原因同上。
* `plugins`: 开启的插件列表，N版本前插件列表是静态配置的，N版本后可以动态配置。
* `proxy_command`: sahara-engine使用net ns访问虚拟机时ssh的ProxyCommand参数，默认值为`'ip netns exec ns_for_{network_id} nc {host} {port}'`。

关于Sahara的高可用，sahara-api由于是HTTP服务，高可用肯定是没有问题的，创建多个实例并放在LB之上即可。

但sahara-engine虽然和nova-conductor、nova-scheduler等服务一样都是消息消费服务，你可以通过部署多实例来提高服务的可用性，但并不能说实现了高可用。Sahara的任务通常都是分阶段的长任务，比如创建一个集群大概需要数分钟时间，但一个任务只能由一个sahara-engine实例全程负责，如果中途挂了，其它sahara-engine实例并不能接管工作。**尤其注意在集群扩容操作时，如果sahara-engine奔溃了，将导致集群可能永远处于中间状态，甚至导致集群瘫痪。**

OK，以上啰嗦了那么多，无非是想引导读者自己想明白Sahara应该怎么部署。Sahara只有两个服务，sahara-api通常部署在控制节点，而sahara-engine部署在哪个节点取决于连接虚拟机使用何种访问模式，相信读者已经有自己的答案了。OK，Let the elephant fly on our Openstack!

##先睹为快

前面介绍了Sahara基(ku)础(zao)知识，提到Sahara部署时需要注意的几个问题。我们已经知道若sahara-engine使用浮动ip连接虚拟机，则sahara-engine无所谓部署在哪个节点了，只要保证能够连通虚拟机即可，通常我们会部署在控制节点上。社区为此在puppet-sahara中实现了专门的类同时在一个节点中部署sahara-api和sahara-engine，使一键部署sahara测试环境成为可能:

```
puppet apply -v puppet-sahara/examples/basic.pp
```

以上命令执行完毕，一个单节点Sahara环境就已经部署完成了。

不过正如前面所说，**Sahara是一个高层服务，依赖于底层Openstack基础服务，因此在部署Sahara前请务必保证Keystone、Nova、Cinder、Glance、Heat、Neutron等能够正常工作。**

#核心代码讲解

##Openstack服务部署套路

在使用自动化工具部署任何系统之前，首先你得了解需要部署系统的工作原理，并能手动部署之。手动部署过Openstack的一定知道部署Openstack服务的套路，无论你部署Nova，还是部署Cinder、Glance甚至Heat，基本都是这个套路:

1. 创建数据库。
2. 通过Keystone创建用户、服务、endpoint等。
3. 下载必要包。
4. 修改配置，主要包括RabbitMQ、数据库连接等配置。
5. 调用xxxx-manager创建数据库的表。
6. 启动服务。

值得庆幸的是，Sahara部署也完全遵循Openstack服务的部署套路，除了套路里包含的东西，几乎没有其它任何额外新鲜工作。这里就不再重复介绍手动部署过程了，感兴趣的读者可以参考[Openstack大数据项目Sahara实践总结](http://int32bit.me/2016/07/27/Openstack%E5%A4%A7%E6%95%B0%E6%8D%AE%E9%A1%B9%E7%9B%AESahara%E5%AE%9E%E8%B7%B5%E6%80%BB%E7%BB%93/#sahara-3)。

无论采用何种方式部署，万变不如其中，其实自动化部署工具就是替代我们手动敲的命令，实现步骤是完全一样的，接下来将分析puppet-sahara各个模块实现以及与我们手动部署时对应的步骤如何关联起来的。

##数据库配置

首先看`sahara::db`这个类，该类位于项目根路径下，主要定义数据库的一些全局通用配置，这些配置是脱离于使用mysql还是postsql的，类定义的原型如下:

```puppet
class sahara::db (
  $database_db_max_retries = $::os_service_default,
  $database_connection     = 'mysql+pymysql://sahara:secrete@localhost:3306/sahara',
  $database_idle_timeout   = $::os_service_default,
  $database_min_pool_size  = $::os_service_default,
  $database_max_pool_size  = $::os_service_default,
  $database_max_retries    = $::os_service_default,
  $database_retry_interval = $::os_service_default,
  $database_max_overflow   = $::os_service_default,
)
```

接下来在`sahara::db::mysql`是专门针对使用mysql数据库的配置，源码如下:

```puppet
class sahara::db::mysql(
  $password,
  $dbname        = 'sahara',
  $user          = 'sahara',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
) {

  validate_string($password)

  ::openstacklib::db::mysql{ 'sahara':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
  }

  ::Openstacklib::Db::Mysql['sahara'] ~> Exec<| title == 'sahara-dbmanage' |>
}
```

以上相当于调用`::openstacklib::db::mysql`创建数据库，对应部署套路第一条。

最后我们通知执行`Exec<| title == 'sahara-dbmanage'`，这其实就相对于对应套路第5条，源代码为:

```
class sahara::db::sync(
  $extra_params = '--config-file /etc/sahara/sahara.conf',
) {

  include ::sahara::params

  Package <| tag == 'sahara-package' |> ~> Exec['sahara-dbmanage']
  Exec['sahara-dbmanage'] ~> Service <| tag == 'sahara-service' |>

  Sahara_config <||> -> Exec['sahara-dbmanage']
  Sahara_config <| title == 'database/connection' |> ~> Exec['sahara-dbmanage']

  exec { 'sahara-dbmanage':
    command     => "sahara-db-manage ${extra_params} upgrade head",
    path        => '/usr/bin',
    user        => 'sahara',
    refreshonly => true,
    try_sleep   => 5,
    tries       => 10,
    logoutput   => on_failure,
    tag         => 'openstack-db',
  }

}
```

以上几个类共同协作完成了Sahara数据库表的初始化。

##Sahara服务认证配置

认证配置对应部署套路第2步，主要包括调用Keystone API创建sahara用户、服务、endpoint等，puppet-sahara代码实现在`sahara::keystone::auth`，该类的实现和前面几个服务非常类似，如Nova、Cinder等，再次不再重复，有兴趣的读者可以直接阅读源码。

##Sahara配置管理

Sahara配置文件主要包括`/etc/sahara/sahara.conf`和`/etc/sahara/api-paste.ini`两个文件，其中`/etc/sahara/sahara.conf`绝大多数配置项由`init.pp`下的`sahara`类管理，使用形如`xyz/key:value`的键值对保存,其中`xyz`表示所在的配置组，`key`表示配置项名称，后面的`value`是配置项的值，样例如下:

```puppet
sahara_config {
    'DEFAULT/plugins':            value => join(any2array($plugins),',');
    'DEFAULT/use_neutron':        value => $use_neutron;
    'DEFAULT/use_floating_ips':   value => $use_floating_ips;
    'DEFAULT/host':               value => $host;
    'DEFAULT/port':               value => $port;
    'DEFAULT/default_ntp_server': value => $default_ntp_server;
  }
```

除了`sahara`类中定义的配置参数，在`sahara::config`中可定义一些额外配置项，通常通过hieradata定义。

另外除了基本配置外，和大多数其它服务一样，还需要配置policy，对应类为`sahara::policy`，该类实现和其它服务类似，这里不再重复介绍。

该步骤对应手动部署套路第4条。

##Sahara服务安装和启动

前面我们已经知道Sahara由sahara-api和sahara-engine两个服务，分别对应的类为`sahara::service::api`和`sahara::service::engine`，这两个类都定义了包的安装、服务配置等。以api服务为例，其核心代码为:

```puppet
class sahara::service::api (
  $api_workers    = $::os_workers,
  $enabled        = true,
  $manage_service = true,
  $package_ensure = 'present',
) {

  include ::sahara::policy
  include ::sahara::params

  Sahara_config<||> ~> Service['sahara-api']
  Class['sahara::policy'] ~> Service['sahara-api']

  package { 'sahara-api':
    ensure => $package_ensure,
    name   => $::sahara::params::api_package_name,
    tag    => ['openstack', 'sahara-package'],
    notify => Service['sahara-api'],
  }
  service { 'sahara-api':
    ensure     => $service_ensure,
    name       => $::sahara::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['sahara-api'],
    tag        => 'sahara-service',
  }

}
```


以上可以很清晰地从代码看出，该类就是对应部署套路的第3条和第6条。

#小结

在这里，我们介绍了puppet-sahara的核心代码实现以及各个模块完成的工作，通过和手动部署套路联系在一起，相信读者能更容易理解代码的原理。当然该module还有许多重要的class我们并没有涉及，例如：`sahara::logging`，`sahara::nofity`等等。这些就留给读者自己去阅读代码了，当然在后期的版本中，我也会进一步去完善puppet-sahara的核心代码内容。

#动手练习

1. 使用puppet-sahara部署Sahara，要求sahara-engine支持`net_ns`访问模式。
2. 想想为什么sahara-engine使用`net_ns`访问虚拟机不支持多网络节点情况。


