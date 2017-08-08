# `puppet-glance`模块

0. [项目简介 - 理解Glance](#基础知识)
1. [先睹为快](#先睹为快)
2. [核心代码讲解 - 如何管理Glance服务？](#核心代码讲解)
3. [动手练习 - 光看不练假把式](##动手练习)

# 0. 项目简介

Glance是OpenStack Image Service项目，用于注册、管理和检索虚拟机镜像。
Glance并不负责实际的镜像存储。它提供了对接简单文件系统，对象存储，块存储等多种存储后端的能力。除了磁盘镜像信息，它还能够存储描述镜像的元数据和状态信息。

## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
创建puppet_glance.pp文件并输入:

```puppet
class { 'glance::api':
  verbose             => true,
  keystone_tenant     => 'services',
  keystone_user       => 'glance',
  keystone_password   => '12345',
  database_connection => 'mysql://glance:12345@127.0.0.1/glance',
}

class { 'glance::registry':
  verbose             => true,
  keystone_tenant     => 'services',
  keystone_user       => 'glance',
  keystone_password   => '12345',
  database_connection => 'mysql://glance:12345@127.0.0.1/glance',
}

class { 'glance::backend::file': }

class { 'glance::db::mysql':
  password      => '12345',
  allowed_hosts => '%',
}

class { 'glance::keystone::auth':
  password         => '12345'
  email            => 'glance@example.com',
  public_address   => '127.0.0.1',
  admin_address    => '127.0.0.1',
  internal_address => '172.17.1.3',
  region           => 'example-west-1',
}

rabbitmq_user { 'glance':
  admin    => true,
  password => 'an_even_bigger_secret',
  provider => 'rabbitmqctl',
  require  => Class['::rabbitmq'],
}

rabbitmq_user_permissions { 'glance@/':
  configure_permission => '.*',
  write_permission     => '.*',
  read_permission      => '.*',
  provider             => 'rabbitmqctl',
  require              => Class['::rabbitmq'],
} 
```
在终端执行以下命令:
```puppet
$ puppet apply -v puppet_glance.pp
```

## 2.核心代码讲解
### 2.1 `class glance`

`class glance`用于管理Glance软件包和Openstackclient软件包:

```puppet
  include ::glance::params

  if ( $glance::params::api_package_name == $glance::params::registry_package_name ) {
    package { $::glance::params::api_package_name :
      ensure => $package_ensure,
      name   => $::glance::params::api_package_name,
      tag    => ['openstack', 'glance-package'],
    }
    include '::openstacklib::openstackclient'
  }
```
### 2.2 `class glance::api`

`glance::api`类用于管理以下配置：

1. **policy\db\logging\cache**
```puppet
  include ::glance::policy
  include ::glance::api::db
  include ::glance::api::logging
  include ::glance::cache::logging
```
2. **/etc/glance/glance-api.conf**
```puppet
  # basic service config
  glance_api_config {
    'DEFAULT/bind_host':               value => $bind_host;
    'DEFAULT/bind_port':               value => $bind_port;
    'DEFAULT/backlog':                 value => $backlog;
    'DEFAULT/show_image_direct_url':   value => $show_image_direct_url;
     ...
    'DEFAULT/image_cache_dir':         value => $image_cache_dir;
    'DEFAULT/auth_region':             value => $auth_region;
    'glance_store/os_region_name':     value => $os_region_name;
  }
```
3.**管理/etc/glance/glance-cache.conf**

在Glance-api中,启用Glance的缓存功能可以加速镜像的二次下载速度(注：在使用Ceph作为Glance, Cinder, Nova的后端时，此功能无效)
```puppet
  glance_cache_config {
    'DEFAULT/image_cache_stall_time': value => $image_cache_stall_time;
    'DEFAULT/image_cache_max_size':   value => $image_cache_max_size;
    'glance_store/os_region_name':    value => $os_region_name;
  }
```
4.**glance-api服务的管理**
```puppet
  service { 'glance-api':
    ensure     => $service_ensure,
    name       => $::glance::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    tag        => 'glance-service',
  }
```
5.**验证glance-api服务部署是否成功**
通过调用`glance image-list`命令来验证glance-api的返回值是否符合预期。
```puppet
  if $validate {
    $defaults = {
      'glance-api' => {
        'command'  => "glance --os-auth-url ${auth_uri} --os-tenant-name ${keystone_tenant} --os-username ${keystone_user} --os-password ${keystone_password} image-list",
      }
    }
    $validation_options_hash = merge ($defaults, $validation_options)
    create_resources('openstacklib::service_validation', $validation_options_hash, {'subscribe' => 'Service[glance-api]'})
  }
```
### 2.3 Class glance::registry
`glance::registry`用于安装和配置`glance-registry`服务，其代码结构与`glance::api`类似，在此不做赘述。

### Class glance::notify::rabbitmq
在glance-api和glance-registry中启用notifications功能可以在创建镜像，更新镜像源数据等事件发生时发送通知到rabbitmq给其他服务使用。

**调用puppet-oslo来配置glance-api.conf和glance-registry**
```puppet
  oslo::messaging::rabbit { ['glance_api_config', 'glance_registry_config']:
    rabbit_password             => $rabbit_password,
    rabbit_userid               => $rabbit_userid,
    rabbit_host                 => $rabbit_host,
    rabbit_port                 => $rabbit_port,
    rabbit_hosts                => $rabbit_hosts,
    rabbit_virtual_host         => $rabbit_virtual_host,
    rabbit_ha_queues            => $rabbit_ha_queues,
    heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
    heartbeat_rate              => $rabbit_heartbeat_rate,
    rabbit_use_ssl              => $rabbit_use_ssl,
    kombu_ssl_ca_certs          => $kombu_ssl_ca_certs,
    kombu_ssl_certfile          => $kombu_ssl_certfile,
    kombu_ssl_keyfile           => $kombu_ssl_keyfile,
    kombu_ssl_version           => $kombu_ssl_version,
    kombu_reconnect_delay       => $kombu_reconnect_delay,
    amqp_durable_queues         => $amqp_durable_queues,
    kombu_compression           => $kombu_compression,
  }


  oslo::messaging::notifications { ['glance_api_config', 'glance_registry_config']:
    driver => $notification_driver,
    topics => $rabbit_notification_topic,
  }

```
### 2.4 `Class glance::backend::rbd`

Glance支持多种存储后端，比如cinder,swift,file,ceph,s3，本节将介绍如何使用`glance::backend::rbd`配置Ceph作为Glance后端存储：

```puppet
  #修改glance_store下的配置项
  glance_api_config {
    'glance_store/rbd_store_ceph_conf':    value => $rbd_store_ceph_conf;
    'glance_store/rbd_store_user':         value => $rbd_store_user;
    'glance_store/rbd_store_pool':         value => $rbd_store_pool;
    'glance_store/rbd_store_chunk_size':   value => $rbd_store_chunk_size;
    'glance_store/rados_connect_timeout':  value => $rados_connect_timeout;
  }

  if !$multi_store {
    glance_api_config { 'glance_store/default_store': value => 'rbd'; }
    if $glare_enabled {
      glance_glare_config { 'glance_store/default_store': value => 'rbd'; }
    }
  }

  #安装python-ceph软件包
  package { 'python-ceph':
    ensure => $package_ensure,
    name   => $::glance::params::pyceph_package_name,
  }

```

## 3.动手练习

1. 配置Glance使用Swift作为存储后端
2. 设置token的缓存时间为5min

