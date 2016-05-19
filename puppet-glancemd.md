# puppet-glance

# puppet-glance

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理glance服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 1小时**
## 先睹为快
学习本章前，先“触（kai）摸(you)”一下神秘模块glance软件部署资源环节，这只是冰山的一角，更多的冰山请继续阅读核心代码章节。撸起你的袖子，开始吧。

> 本示例依赖面部署的 keystone/myql/ceph/rabbitmq 4个服务


编写puppet_glance.pp

**1.定义一个Glance节点**
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
```
**2.设置一个Glance的数据库**
```puppet
class { 'glance::db::mysql':
  password      => '12345',
  allowed_hosts => '%',
}
```
**3.添加glance的认证服务**
```puppet
class { 'glance::keystone::auth':
  password         => '12345'
  email            => 'glance@example.com',
  public_address   => '172.17.0.3',
  admin_address    => '172.17.0.3',
  internal_address => '172.17.1.3',
  region           => 'example-west-1',
}
```
**4.配置Glance使用多节点的rabbitMQ**

```puppet
class { 'glance::notify::rabbitmq':
  rabbit_password               => 'pass',
  rabbit_userid                 => 'guest',
  rabbit_hosts                  => [
    'localhost:5672', 'remotehost:5672'
  ],
  rabbit_use_ssl                => false,
}
```
在终端执行以下命令:
```puppet
puppet apply -v puppet_glance.pp
```

## 核心代码讲解
### Class glance
class glance的逻辑非常简单，简单到没有逻辑
安装glance软件包和openstackclient软件包
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
### Class glance::api
这个类可不那么简单喽,我们只挑几个关键部分进行讲解

**配置policy\db\logging\cache**
```puppet
  include ::glance::policy
  include ::glance::api::db
  include ::glance::api::logging
  include ::glance::cache::logging
```
**管理/etc/glance/glance-api.conf**
```puppet
  # basic service config
  glance_api_config {
    'DEFAULT/bind_host':               value => $bind_host;
    'DEFAULT/bind_port':               value => $bind_port;
    'DEFAULT/backlog':                 value => $backlog;
    'DEFAULT/workers':                 value => $workers;
    'DEFAULT/show_image_direct_url':   value => $show_image_direct_url;                                                               'DEFAULT/show_multiple_locations': value => $show_multiple_locations;                                                             'DEFAULT/location_strategy':       value => $location_strategy;
    'DEFAULT/scrub_time':              value => $scrub_time;
    'DEFAULT/delayed_delete':          value => $delayed_delete;
    'DEFAULT/image_cache_dir':         value => $image_cache_dir;
    'DEFAULT/auth_region':             value => $auth_region;
    'glance_store/os_region_name':     value => $os_region_name;
  }
```
**管理/etc/glance/glance-cache.conf**
在glance api中我们可以打开glance的缓存功能来加速镜像的下载速度(在我们使用ceph作为glance,cinder,nova的后端时，这个功能没有必要)
```puppet
  glance_cache_config {
    'DEFAULT/image_cache_stall_time': value => $image_cache_stall_time;
    'DEFAULT/image_cache_max_size':   value => $image_cache_max_size;
    'glance_store/os_region_name':    value => $os_region_name;
  }
```
**服务的管理**
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
**验证服务部署是否成功**
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
### Class glance::registry
### Class glance::client
### Class glance::notify::rabbitmq
### Class glance::backend::rbd

## 小结

## 动手练习
1. 配置glance使用file作为存储后端
2. 设置token的缓存时间为5分钟

