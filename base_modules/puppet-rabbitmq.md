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

`class rabbitmq`是一个入口类，用于声明当前模块中的所有资源，比如：判断参数值得类型是否符合预期、调用其它类（include）、继承params类、判断参数是否启用LADP验证等等。
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
`validate_re`函数是用于检查参数传入值是否与给定的正则表达式匹配。

`class rabbitmq`核心的代码是声明了4个类：
- rabbitmq::install
- rabbitmq::config
- rabbitmq::service
- rabbitmq::management


## class rabbitmq::install
此类主要负责rabbitmq服务端的软件部署。
```puppet

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
## class rabbitmq::config
config类主要是负责rabbitmq服务目录、配置文件、文件内容的写入等配置
```puppet
class rabbitmq::config {

  $admin_enable               = $rabbitmq::admin_enable
  $cluster_node_type          = $rabbitmq::cluster_node_type
  $cluster_nodes              = $rabbitmq::cluster_nodes
  $config                     = $rabbitmq::config
  }
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
```

## Class rabbitmq::service
上面我们说了软件包的安装、软件包配置文件的下发，既然准备工作已经做好，那么咱们需要让这个服务启动，service 这个类就是来负责触发服务的管理。
```puppet
class rabbitmq::service(
  $service_ensure = $rabbitmq::service_ensure,
  $service_manage = $rabbitmq::service_manage,
  $service_name   = $rabbitmq::service_name,
) inherits rabbitmq {

  validate_re($service_ensure, '^(running|stopped)$')
  validate_bool($service_manage)

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
#小结
rabbitmq 模块也比较简单，需要注意是默认安装的时候有guest用户，一般情况下我们会删除此用户。
#动手练习
1.如何删除rabbitmq中guest用户？
2.如何使用自定义资源rabbitmq_user来创建用户？


