# `puppet-rabbitmq`模块

1. [先睹为快](#1.先睹为快)
2. [代码讲解](#2.代码讲解)
3. [扩展阅读](#3.扩展阅读) 
4. [动手练习](#4.动手练习)

RabbitMQ是RabbitMQ Technologies Ltd开发的AMQP（Advanced Message Queue Protocol）的开源实现。RabbitMQ组件也是此书的重点章节，因为它与每个OpenStack服务息息相关，那么RabbitMQ解决了什么问题？
 
对于一个复杂的分布式系统而言，它包含了大量的组件或者子系统，那么这些组件之间是如何进行通信的呢？

分布式系统，顾名思义，其组件是运行在不同的服务器上，而传统的应用软件往往使用管道，信号，报文等方式来解决进程间的协作，这些进程间通讯IPC通常只是运行在单个操作系统上，不具备扩展的能力；如果使用Socket将服务组件部署到不同的服务器，需要解决以下问题：

 1）消息的发送方和接收方如何维持连接，如果连接中断，如何处理这期间的已接收的数据？

 2）如何解耦发送方和接收方？

 3）如何有效地分发和接收消息？

 4）如何实现消息处理能力的水平扩展？

 5）如何保证接收方接收到了完整，正确的数据？

高级消息队列协议(AMQP)解决了上述问题，而RabbitMQ用Erlang实现了一个异步，模块化，可扩展的高级消息队列协议。

`puppet-rabbitmq`是由Puppet官方维护的模块，用于管理RabbitMQ服务的安装，配置。

`puppet-rabbitmq`项目地址：https://github.com/voxpupuli/puppet-rabbitmq


## 1.先睹为快

不想看下面大段的代码说明，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
$ puppet apply -e "class { 'rabbitmq': }"
```

等待上述命令执行完成，Puppet完成了对RabbitMQ服务的安装和配置。

# 2.代码讲解
### 2.1 `class rabbitmq`

`class rabbitmq`是一个入口类，用于声明当前模块中的相关资源，同时也会包含一些逻辑判断和声明，如：判断参数值类型是否符合预期、调用其它类（include）、继承params类、判断参数是否启用LADP验证等等。
``` puppet
class rabbitmq(
  $admin_enable               = $rabbitmq::params::admin_enable,
  $cluster_nodes              = $rabbitmq::params::cluster_nodes,
  $config                     = $rabbitmq::params::config,
  $config_cluster             = $rabbitmq::params::config_cluster,
  ...
)inherits rabbitmq::params {
  validate_re($package_apt_pin, '^(|\d+)$')
  ...
  include '::rabbitmq::install'
  include '::rabbitmq::config'
  include '::rabbitmq::service'
  include '::rabbitmq::management'
  
  if $admin_enable and $service_manage {
    include '::rabbitmq::install::rabbitmqadmin'

    rabbitmq_plugin { 'rabbitmq_management':
      ensure   => present,
      require  => Class['rabbitmq::install'],
      notify   => Class['rabbitmq::service'],
      provider => 'rabbitmqplugins',
    }

    Class['::rabbitmq::service'] -> Class['::rabbitmq::install::rabbitmqadmin']
    Class['::rabbitmq::install::rabbitmqadmin'] -> Rabbitmq_exchange<| |>
  }
  ...

}
```
在代码块首有一些类似于```validate_re($package_apt_pin, '^(|\d+)$')```的代码，其实`validate_re`函数接收两个参数：参数名，正则表达式。用于检查指定参数的传入值是否与给定的正则表达式匹配。
因此，在应用catalog前对输入数据进行检查，可以提前发现的用户错误传参。

`class rabbitmq`作为一个入口类，声明了4个类：

- rabbitmq::install
- rabbitmq::config
- rabbitmq::service
- rabbitmq::management


### 2.2 class rabbitmq::install
`rabbitmq::install`用于管理RabbitMQ Server的软件部署和配置, 注意其参数的默认值是`$rabbitmq::param_name`的格式，说明该类在被声明时，`class rabbitmq`也需同时被声明。
```puppet
class rabbitmq::install {
  $package_ensure   = $rabbitmq::package_ensure
  $package_name     = $rabbitmq::package_name
  $package_provider = $rabbitmq::package_provider
  $package_require  = $rabbitmq::package_require
  $package_source   = $rabbitmq::real_package_source

  package { 'rabbitmq-server':
    ensure   => $package_ensure,
    name     => $package_name,
    provider => $package_provider,
    notify   => Class['rabbitmq::service'],
    require  => $package_require,
  }

  if $package_source {
    Package['rabbitmq-server'] {
      source  => $package_source,
    }
  }

  if $rabbitmq::environment_variables['MNESIA_BASE'] {
    file { $rabbitmq::environment_variables['MNESIA_BASE']:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'rabbitmq',
      mode    => '0775',
      require => Package['rabbitmq-server'],
    }
  }
}
```
### 2.3 `class rabbitmq::config`

`rabbitmq::config`类用于统一管理RabbitMQ服务的目录和配置文件。可能会有读者有疑问，为什么要将软件包的安装和配置文件的管理分拆为
两个类。原因很简单，为了代码可读性，`rabbitmq::config`的代码长度有两百多行，若与其他代码合并在一起，阅读起来会非常痛苦。
这也是Puppet的最佳实践之一：尽可能保持代码的简洁和可读性。
```puppet
class rabbitmq::config {

  $admin_enable               = $rabbitmq::admin_enable
  $cluster_node_type          = $rabbitmq::cluster_node_type
  $cluster_nodes              = $rabbitmq::cluster_nodes
  $config                     = $rabbitmq::config
  ...
  }
  ...
  file { '/etc/rabbitmq':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0644',
  }
  file { '/etc/rabbitmq/ssl':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0644',
  }
  ...
```

### 2.4 `class rabbitmq::service`
`rabbitmq::install`和`rabbitmq::config`分别完成了软件包的安装、配置文件的生成，准备工作已经完成，`rabbitmq::service`类用于管理服务状态。
```puppet
class rabbitmq::service(
  Enum['running', 'stopped'] $service_ensure  = $rabbitmq::service_ensure,
  Boolean $service_manage                     = $rabbitmq::service_manage,
  $service_name                               = $rabbitmq::service_name,
) inherits rabbitmq {

  if ($service_manage) {
    if $service_ensure == 'running' {
      $ensure_real = 'running'
      $enable_real = true
    } else {
      $ensure_real = 'stopped'
      $enable_real = false
    }

    service { 'rabbitmq-server':
      ensure     => $ensure_real,
      enable     => $enable_real,
      hasstatus  => true,
      hasrestart => true,
      name       => $service_name,
    }
  }
}
```

读者可能已经注意到参数$service_ensure和$service_manage被声明了数据类型，其中Boolean被称为是数据类型(Data types)，在Puppet中有以下数据类型:

  - Strings
  - Numbers
  - Booleans
  - Arrays
  - Hashes
  - Regular Expressions
  - Sensitive
  - Undef
  - Resource References
  - Default

此外，Enum称为是抽象数据类型(abstract data types)，可以灵活地匹配/限制指定参数的数据类型。

例如，`Boolean $service_manage`严格地限定了$service_manage的数据类型为布尔型，而使用`Optional[String, Boolean] $service_manage`则可以指定$service_manage的数据类型可以是布尔型或者字符串。


## 3.扩展阅读

- 数据类型 https://docs.puppet.com/puppet/4.10/lang_data.html
- 抽象数据类型 https://docs.puppet.com/puppet/4.10/lang_data_abstract.html

## 4.动手练习

1.默认安装的时候有guest用户，出于安全考虑，会删除此用户，请使用puppet-rabbitmq完成此操作。
2.如何使用自定义资源rabbitmq_user来创建用户？
3.在OpenStack中，fanout类型的队列应在程序退出时删除，RabbitMQ中可以使用Policy设置Queue的TTL，请使用rabbitmq_policy将.*上所有queue的ttl设置为18000s。


