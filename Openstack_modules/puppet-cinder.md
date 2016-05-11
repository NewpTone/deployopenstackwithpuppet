# puppet-cinder

cinder项目是openstack项目的核心组件，puppet-keystone 是 openstack 官方的 puppet 项目，用来部署和管理cinder组件，包括一些初始化工作创建keystone endpoint、初始化RPC、初始化数据库等,配置文件管理，软件包安装，和服务管理这几个部分.

*学习本章，需要阅读前面的章节包括keystone/mysql/rabbitmq三个章节，并且需要对cinder有些了解。*
puppet-cinder主要由以下几个类组成:
## class cinder
入口类，安装cinder基础包并配置cinder配置文件,ok，该类介绍完成(zen me ke neng)，我们马上来上手使用吧
编写一个 learn_cinder.pp

``` puppet
class { 'cinder':
  database_connection => 'mysql://cinder:secret_block_password@openstack-controller.example.com/cinder',
  rabbit_password     => 'secret_rpc_password_for_blocks',
  rabbit_host         => 'openstack-controller.example.com',
  verbose             => true,
}
```
来测试下吧，在终端下输入:

```puppet apply learn_cinder.pp```

不出一秒钟(zen me ke neng),puppet 已经帮你安装好的cinder的基础包，并对cinder的通用配置进行了配置.接下来我们看看这是如何实现的吧
我们来分析下cinder 目录下的init.pp文件，看下几个重要部分

``` puppet

  include ::cinder::db
  include ::cinder::logging

```
配置数据库和日志

---

``` puppet
  package { 'cinder':
    ensure  => $package_ensure,
    name    => $::cinder::params::package_name,
    tag     => ['openstack', 'cinder-package'],
    require => Anchor['cinder-start'],
  }
```
安装软件包

---

``` puppet
  if $rpc_backend == 'cinder.openstack.common.rpc.impl_kombu' or $rpc_backend == 'rabbit' {

    if ! $rabbit_password {
      fail('Please specify a rabbit_password parameter.')
    }

    oslo::messaging::rabbit { 'cinder_config':
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
      amqp_durable_queues         => $amqp_durable_queues,
    }

    oslo::messaging::default { 'cinder_config':
      control_exchange => $control_exchange
    }

    cinder_config {
      'DEFAULT/report_interval':   value => $report_interval;
      'DEFAULT/service_down_time': value => $service_down_time;
    }
  }
  ```
  RPC相关的配置
 
  ---
  
  ``` puppet
  cinder_config {
    'DEFAULT/api_paste_config':          value => $api_paste_config;
    'DEFAULT/storage_availability_zone': value => $storage_availability_zone;
    'DEFAULT/default_availability_zone': value => $default_availability_zone_real;
    'DEFAULT/image_conversion_dir':      value => $image_conversion_dir;
    'DEFAULT/host':                      value => $host;
  }
  ```
  调用自定义的 cinder_config type 配置cinder配置文件

  ---
  
 ``` puppet
  if $use_ssl {
    cinder_config {
      'DEFAULT/ssl_cert_file' : value => $cert_file;
      'DEFAULT/ssl_key_file' :  value => $key_file;
      'DEFAULT/ssl_ca_file' :   value => $ca_file;
    }
  } else {
    cinder_config {
      'DEFAULT/ssl_cert_file' : ensure => absent;
      'DEFAULT/ssl_key_file' :  ensure => absent;
      'DEFAULT/ssl_ca_file' :   ensure => absent;
    }
  }
}
```
ssl相关配置



## class cinder::api
安装和配置cinder-api服务
## class cinder::scheduler
安装和配置cinder-scheduler服务
## class cinder::volume
安装和配置cinder-volume服务
## class cinder::backends
配置cinder-volume后端
## class cinder::backup
安装和配置cinder-backup服务
