# puppet-aodh

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理aodh服务？](#核心代码讲解)
    - [class aodh](##class aodh)
    - [class aodh::db](##class aodh::db)
    - [class aodh::keystone](##class aodh::keystone)
    - [class aodh::api](##class aodh::api)
    - [class aodh::evaluator](##class aodh::evaluator)
    - [class aodh::notifier](##class aodh::notifier)
    - [class aodh::listener](##class aodh::listener)
3. [小结](#小结)
4. [动手练习 - 光看不练假把式](#动手练习)

**本节作者：陆源**

**建议阅读时间 1h**

## Aodh简述
Aodh是Openstack基础架构团队贡献（此团队提供持续集成测试和代码审查服务），但此模块不是openstack核心项目。aodh主要提供配置和管理OpenStack告警服务。注意：在Mitaka版本中原先的ceilometer-alarm组件全部被清除，由aodh来代替。
## Aodh架构图
![](../images/03/aodh.png)
## Aodh服务
---
| 名称 | 说明 |
|--------|:-----:|
| openstack-aodh-api |为告警数据的存储和访问提供接口  |
| openstack-aodh-evaluator| 根据统计的数据，来评估是否需要触发告警 |
| openstack-aodh-notifier | 根据配置的告警方式，发出告警 |
| openstack-aodh-listener | 监听事件，触发事件相关的告警 |

## 先睹为快
部署Aodh，服务依赖于keystone服务和http服务。
```puppet
class { '::aodh': }
class { '::aodh::keystone::authtoken':
#需要自定义密码
  password => 'puppetopenstack',
}
class { '::aodh::api':
  enabled      => true,
  service_name => 'httpd',
}
include ::apache
class { '::aodh::wsgi::apache':
  ssl => false,
}
class { '::aodh::auth':
#需要自定义密码
  auth_password => 'puppetopenstack',
}
class { '::aodh::evaluator': }
class { '::aodh::notifier': }
class { '::aodh::listener': }
class { '::aodh::client': }
```
然后执行以下命令

```bash
# puppet apply examples/site.pp
```
aodh就安装完成了。`puppet-aodh`模块中，我们主要介绍`class aodh`和`class aodh::三大组件`：

## 核心代码讲解
### class aodh
```puppet
    package { 'aodh':
    ensure => $ensure_package,
    name   => $::aodh::params::common_package_name,
    #tag属性
    tag    => ['openstack', 'aodh-package'],
  }
```
puppet-aodh中对rpc的选择主要提供了两种：RabbitMQ和AMQP，所提供的参数如下:
```puppet
  if $rpc_backend == 'rabbit' {
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
  }
    elsif $rpc_backend == 'amqp' {
    oslo::messaging::amqp { 'aodh_config':
      server_request_prefix  => $amqp_server_request_prefix,
      broadcast_prefix       => $amqp_broadcast_prefix,
      group_request_prefix   => $amqp_group_request_prefix,
      container_name         => $amqp_container_name,
      idle_timeout           => $amqp_idle_timeout,
      trace                  => $amqp_trace,
      ssl_ca_file            => $amqp_ssl_ca_file,
      ssl_cert_file          => $amqp_ssl_cert_file,
      ssl_key_file           => $amqp_ssl_key_file,
      ssl_key_password       => $amqp_ssl_key_password,
      allow_insecure_clients => $amqp_allow_insecure_clients,
      sasl_mechanisms        => $amqp_sasl_mechanisms,
      sasl_config_dir        => $amqp_sasl_config_dir,
      sasl_config_name       => $amqp_sasl_config_name,
      username               => $amqp_username,
      password               => $amqp_password,
    }
  }
```
tag属性的定义：资源、类和自定义define类型实例可以有任意数量的标签，加上他们可以自动收到一些标签。标签用处很多：
* 可以收集资源
* 根据标签分析报告
* 限制catalog运行

### class aodh::db
class aodh::db应该和db目录下的几个文件放在一起看，aodh默认使用MySQL数据库，首先aodh::db::mysql调用::openstacklib::db::mysql创建aodh的数据库，代码如下:
```puppet
  ::openstacklib::db::mysql { 'aodh':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
  }
```
触发dbsync.而class aodh::db则调用oslo::db配置aodh中db相关参数。
```puppet
  oslo::db { 'aodh_config':
    db_max_retries => $database_db_max_retries,
    connection     => $database_connection,
    idle_timeout   => $database_idle_timeout,
    min_pool_size  => $database_min_pool_size,
    max_retries    => $database_max_retries,
    retry_interval => $database_retry_interval,
    max_pool_size  => $database_max_pool_size,
    max_overflow   => $database_max_overflow,
  }
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
