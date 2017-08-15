# puppet-aodh模块

0. [基础知识 - 理解Aodh](#基础知识)
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何管理Aodh服务？](#核心代码讲解)
    - [class aodh](##class aodh)
    - [class aodh::db](##class aodh::db)
    - [class aodh::keystone](##class aodh::keystone)
    - [class aodh::api](##class aodh::api)
    - [class aodh::evaluator](##class aodh::evaluator)
    - [class aodh::notifier](##class aodh::notifier)
    - [class aodh::listener](##class aodh::listener)
3. [小结](#小结)
4. [动手练习 - 光看不练假把式](#动手练习)


## 0.理解Aodh

Aodh是Openstack告警项目，最初在Havana版本中作为Ceilometer项目的一个组件(ceilometer-alarm)出现在Ceilometer项目中，在Liberty版本中演变成了独立项目Aodh，用户可以为独立事件或者样本设置阈值和告警机制。

Aodh服务由以下组件组成：
---
| 名称 | 说明 |
|--------|:-----:|
| openstack-aodh-api |为告警数据的存储和访问提供接口  |
| openstack-aodh-evaluator| 根据统计的数据，来评估是否需要触发告警 |
| openstack-aodh-notifier | 根据配置的告警方式，发出告警 |
| openstack-aodh-listener | 监听事件，触发事件相关的告警 |

各个组件之间的关系如下图所示:
![](../images/03/aodh.png)


## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
$ puppet apply examples/aodh.pp
```
等待命令执行完成，Puppet完成了对Aodh服务的安装。

注：部署Aodh服务，依赖于Keystone服务。

## 2.核心代码讲解
### `class aodh`
`class aodh`完成了以下三项任务:

  - Aodh common包的安装
  - Aodh配置文件的清理
  - RabbitMQ和AMQP选项的管理

其中rabbit和AMQP相关的选项管理均是通过oslo::messaging::rabbit和oslo::messaging::amqp来管理，关于puppet-oslo模块，将会在下一个章节详细介绍。
```puppet
  oslo::messaging::rabbit { 'aodh_config':
    rabbit_userid               => $rabbit_userid,
    rabbit_password             => $rabbit_password,
    rabbit_virtual_host         => $rabbit_virtual_host,
    rabbit_host                 => $rabbit_host,
    rabbit_port                 => $rabbit_port,
    rabbit_hosts                => $rabbit_hosts,
    rabbit_ha_queues            => $rabbit_ha_queues,
    heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
    heartbeat_rate              => $rabbit_heartbeat_rate,
    rabbit_use_ssl              => $rabbit_use_ssl,
    kombu_reconnect_delay       => $kombu_reconnect_delay,
    kombu_ssl_version           => $kombu_ssl_version,
    kombu_ssl_keyfile           => $kombu_ssl_keyfile,
    kombu_ssl_certfile          => $kombu_ssl_certfile,
    kombu_ssl_ca_certs          => $kombu_ssl_ca_certs,
    kombu_compression           => $kombu_compression,
    amqp_durable_queues         => $amqp_durable_queues,
  }
```

在package资源中，有一个元属性tag:
```
package { 'aodh':
  ensure => $package_ensure_real,
  name   => $::aodh::params::common_package_name,
  tag    => ['openstack', 'aodh-package'],
}
```
`tag`顾名思义就是标签，资源、类和定义都可以对其标记，一个资源可以有任意数量的标记。有多种标记资源的方式，以上代码是使用了元参数tag，对aodh package资源
添加了2个tag：'openstack','aodh-package'。这些tag会在`aodh::deps`中使用，用于收集标记为`aodh-package`的package资源:

```puppet
 anchor { 'aodh::install::begin': }
  -> Package<| tag == 'aodh-package'|>
  ~> anchor { 'aodh::install::end': }
```


### class aodh::keystone::auth
aodh::keystone::auth模块是用来创建aodh的endpoint和role，其中有这么一段代码：
```puppet
  ::keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => $service_description,
    service_name        => $service_name_real,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    roles               => ['admin', 'ResellerAdmin'],
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }
```
### class aodh::api
api的主要是提供数据的接口，为告警数据的提供存储和访问。在class aodh::api中先是定义了以下几个依赖关系：
```puppet
   if $auth_strategy == 'keystone' {
    include ::aodh::keystone::authtoken
  }

  Aodh_config<||> ~> Service[$service_name]
  Class['aodh::policy'] ~> Service[$service_name]

  Package['aodh-api'] -> Service[$service_name]
  Package['aodh-api'] -> Service['aodh-api']
  Package['aodh-api'] -> Class['aodh::policy']
  package { 'aodh-api':
    ensure => $package_ensure,
    name   => $::aodh::params::api_package_name,
    tag    => ['openstack', 'aodh-package'],
  }
```
代码中两种符号'->'和'~>'，这两者都是描述资源间的依赖，前面已经介绍过。同时在模块中都同样使用keystone作为认证。API类中其余代码则是对参数进行配置，略过。

### class aodh::evaluator
```puppet
  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }
  Package['aodh'] -> Service['aodh-evaluator']
  service { 'aodh-evaluator':
    ensure     => $service_ensure,
    name       => $::aodh::params::evaluator_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    tag        => ['aodh-service','aodh-db-sync-service']
  }
  )
```
aodh-evaluator 服务的部署和 aodh-api 类似，配置一些基础配置和 oslo 相关配置，就可以启动服务了。
### class aodh::notifier
```puppet
  Package['aodh'] -> Service['aodh-notifier']
  service { 'aodh-notifier':
    ensure     => $service_ensure,
    name       => $::aodh::params::notifier_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    tag        => 'aodh-service',
  }
}
```
### class aodh::listener
```puppet
  Package['aodh'] -> Service['aodh-listener']
  service { 'aodh-listener':
    ensure     => $service_ensure,
    name       => $::aodh::params::listener_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    tag        => 'aodh-service',
  }
}
```

## 小结
从上述的代码中，咱们可清晰看到aodh的安装、数据库创建与同步、认证、api、evaluator、notifier、listener服务的配置、启动、管理。源于aodh手动部署文档。
## 动手练习
1. 配置Aodh运行在httpd下运行
2. 使用AMQP替换RabbitMQ
