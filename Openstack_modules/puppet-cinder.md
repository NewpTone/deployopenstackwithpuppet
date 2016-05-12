# puppet-cinder模块介绍

1. 先睹为快－一言不和，立马动手？
2. 核心代码讲解－如何管理cinder服务
3. 小结
4. 动手联系－光看不练假把式

**建议阅读时间 1小时**

## 先睹为快
在讲解cinder模块之前让我们先部署一个cinder服务先

> 本示例依赖面部署的 keystone/myql/ceph/rabbitmq 4个服务


编写learn_cinder.pp
```puppet
class { 'cinder':
  database_connection     => 'mysql://cinder:secret_block_password@openstack-controller.example.com/cinder',
  rabbit_password         => 'secret_rpc_password_for_blocks',
  rabbit_host             => 'openstack-controller.example.com',
  verbose                 => true,
}

class { 'cinder::api':
  keystone_password       => $keystone_password,
  keystone_enabled        => $keystone_enabled,
  keystone_user           => $keystone_user,
  keystone_auth_host      => $keystone_auth_host,
  keystone_auth_port      => $keystone_auth_port,
  keystone_auth_protocol  => $keystone_auth_protocol,
  service_port            => $keystone_service_port,
  package_ensure          => $cinder_api_package_ensure,
  bind_host               => $cinder_bind_host,
  enabled                 => $cinder_api_enabled,
}

class { 'cinder::scheduler': }

class { 'cinder::volume': }

cinder::backend::rbd {'rbd-images':
  rbd_pool => 'images',
  rbd_user => 'images',
}

cinder_type {'rbd-images':
  ensure     => present,
  properties => ['volume_backend_name=rbd-images'],
}

class { 'cinder::backends':
  enabled_backends => ['iscsi1', 'iscsi2', 'rbd-images']
}
```
在终端执行以下命令:
```puppet
puppet apply -v learn_cinder.pp
```
ok，恭喜你，已经有了一个使用ceph作为后端的cinder服务，敢紧来试试吧
```bash
# source openrc
# openstack volume create test_cinder --size 1
```
你已经创建了一个1G大小的cinder卷


## 核心代码讲解
### Class cinder
class cinder非常简单主要做了两件核心工作
* 安装cinder基础包
* 配置cinder.conf中的核心参数


#### cinder软件包管理
这里有一个非常有用的参数是$package_ensure，我们可以指定软件包的版本，或者将其标记为总是安装最新版本，我们将会在最佳实践部分去介绍它。
```puppet
  package { 'cinder':
    ensure  => $package_ensure,
    name    => $::cinder::params::package_name,
    tag     => ['openstack', 'cinder-package'],
    require => Anchor['cinder-start'],
  }
```
#### cinder核心参数管理
class cinder里管理了大量的配置参数，比如db,rpc,az设置等相关参数，这里不一一列举。
这里只一个代码片段为例来解释cinder_config的用法。和前面介绍的keystone_config类似cinder_config是一个自定义的resource type，其源码路径位于：
lib/puppet/type/cinder_config.rb 定义
lib/puppet/provider/cinder_config/ini_setting.rb 实现
在这里我们关注如何使用，在Advanced Puppet一书中我们将讲解如何编写custom resource type。
keystone_config有多种使用方法:
对指定参数赋值：
```puppet
cinder_config { 'section_name/option_name': value => option_value}
```
对指定参数赋值，并设置为加密：
```puppet
cinder_config { 'section_name/option_name': value => option_value， secret => true}
```
我们知道puppet agent的所有输出默认都会被syslog打到系统日志/var/log/messages中，那么有心人只要用grep就能从中搜到许多敏感信息，例如：admin_token, user_password, keystone_db_password等等。只要设置了secret为true后，那么就不会把该参数的相关日志打到系统日志中。
OK，讲解就到这里，我们来看代码。
```puppet
  cinder_config {
    'DEFAULT/enable_v1_api':        value => $enable_v1_api;
    'DEFAULT/enable_v2_api':        value => $enable_v2_api;
    'DEFAULT/enable_v3_api':        value => $enable_v3_api;
  }
```

### Class cinder::api
class cinder::api 主要配置和管理cinder的api服务

####管理服务
cinder可以作为一个服务启动，也可以启动在apache下
```puppet
  if $service_name == $::cinder::params::api_service {
    service { 'cinder-api':
      ensure    => $ensure,
      name      => $::cinder::params::api_service,
      enable    => $enabled,
      hasstatus => true,
      require   => Package['cinder'],
      tag       => 'cinder-service',
    }

  } elsif $service_name == 'httpd' {
    include ::apache::params
    service { 'cinder-api':
      ensure => 'stopped',
      name   => $::cinder::params::api_service,
      enable => false,
      tag    => ['cinder-service'],
    }
```
服务检查，调用cinder list命令来确确认cinder服务是否ready
```puppet
  if $validate {
    $defaults = {
      'cinder-api' => {
        'command'  => "cinder --os-auth-url ${auth_uri} --os-tenant-name ${keystone_tenant} --os-username ${keystone_user} --os-password ${keystone_password} list",
      }
    }
    $validation_options_hash = merge ($defaults, $validation_options)
    create_resources('openstacklib::service_validation', $validation_options_hash, {'subscribe' => 'Service[cinder-api]'})
  }
```

###Class cinder::scheduler
这个class没什么好讲的，无非是装包，改配置，起服务三板斧

###Class cinder::volume
同上
###Class cinder::backup
同上
###Class cinder::backends && Define cinder::backend::
由于cinder支持多后端，这个类主要用来管理开启哪些cinder后端，而这些后端由cinder::backend::*backend_name* 来定义

调用cinder_config来修改cinder.conf
```puppet
class cinder::backends (
  $enabled_backends    = undef,
) {

  # Maybe this could be extented to dynamicly find the enabled names
  cinder_config {
    'DEFAULT/enabled_backends': value => join($enabled_backends, ',');
  }
}
```
后端的定义由很多define组成，我们举例我们用到的cinder::backend::rbd,比较值得注意的是用define来实现后端定义，因为在cinder中可能有多个同一类型的后端,比如一个cinder配置两个ceph作为cinder存储后端，这时候用class实现显然是不合适的
主要也是调用cinder_config 来修改cinder.conf文件
```puppet
  cinder_config {
    "${name}/volume_backend_name":              value => $volume_backend_name;
    "${name}/volume_driver":                    value => 'cinder.volume.drivers.rbd.RBDDriver';
    "${name}/rbd_ceph_conf":                    value => $rbd_ceph_conf;
    "${name}/rbd_user":                         value => $rbd_user;
    "${name}/rbd_pool":                         value => $rbd_pool;
    "${name}/rbd_max_clone_depth":              value => $rbd_max_clone_depth;
    "${name}/rbd_flatten_volume_from_snapshot": value => $rbd_flatten_volume_from_snapshot;
    "${name}/rbd_secret_uuid":                  value => $rbd_secret_uuid;
    "${name}/rados_connect_timeout":            value => $rados_connect_timeout;
    "${name}/rados_connection_interval":        value => $rados_connection_interval;
    "${name}/rados_connection_retries":         value => $rados_connection_retries;
    "${name}/rbd_store_chunk_size":             value => $rbd_store_chunk_size;
  }

```
###Define cinder::type
cinder开启多后端后，如何确定要将卷创建到哪个后端呢，这就要有type来决定.
```puppet
define cinder::type (
  $set_key        = undef,
  $set_value      = undef,
  # DEPRECATED PARAMETERS
  $os_password    = undef,
  $os_tenant_name = undef,
  $os_username    = undef,
  $os_auth_url    = undef,
  $os_region_name = undef,
  ) {

  if $os_password or $os_region_name or $os_tenant_name or $os_username or $os_auth_url {
    warning('Parameters $os_password/$os_region_name/$os_tenant_name/$os_username/$os_auth_url are not longer required')
    warning('Auth creds will be used from env or /root/openrc file or cinder.conf')
  }

  if ($set_value and $set_key) {
    if is_array($set_value) {
      $value = join($set_value, ',')
    } else {
      $value = $set_value
    }
    cinder_type { $name:
      ensure     => present,
      properties => ["${set_key}=${value}"],
    }
  } else {
    cinder_type { $name:
      ensure     => present,
    }
  }
}
```
这个关键的是cinder_type,其源码路径为
lib/puppet/type/cinder_type.rb
lib/puppet/provider/cinder_type/openstack.rb

##小结
ok，核心代码的解析就到这里，后面的像cinder::quota,cinder::policy,cinder::logging等配置就不在一一解析,留给读者课后去学习.总之puppet-cinder除了多后端配置和其他模块略有不同之外,其余部分都十分相似，是一个比较容易学习的模块.


##动手练习
1.配置LVM作为cinder后端
2.同时使LVM和ceph作为cinder的后端
3.将cinder运行在apache下






