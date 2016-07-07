# puppet-manila

0. [基础知识 - 快速了解 manila 服务 ](##基础知识)
1. [先睹为快 - 一言不合，立马动手?](##先睹为快)
2. [核心代码讲解 - 如何管理 manila 服务？](##核心代码讲解)
    - [class manila](###class manila)
    - [class manila::db](###class manila::db)
    - [class manila::api](###class manila::api)
    - [class manila::scheduler](###class manila::scheduler)
    - [class manila::share](###class manila::share)
    - [class manila::backends](###class manila::backends)
    - [define manila::backend::glusternfs](###define manila::backend::glusternfs)
3. [小结](#小结)
4. [动手练习](##动手练习)

**本节作者：周维宇**    
**阅读级别：选读 **  
**阅读时间:2h**

##基础知识

manila 是一个 ''Shared Filesystems as a service” 服务，通过driver不同的后端共享存储系统来给提供共享文件存储

manila 服务有下面这些组件：

- manila-api，对外提供 REST-ful 的 API
- manila-scheduler，根据预定的策略选择合适的manila-share节点来处理用户请求
- manila-share，通过driver处理实际的创建创建共享卷等请求

## 先睹为快

部署 manila 服务需要依赖于其他的 OpenStack 组件，因此建议先部署核心的 OpenStack 组件，最后部署 manila 服务。另外由于我们选用nfs作为存储后端，所以你要先部署一个nfs server。

```puppet
  # 请根据你的实际部署情况修改参数
  class { 'manila':
    sql_connection  => 'mysql://manila:secret_manila_password@openstack-controller.example.com/manila',
    rpc_backend     => 'rabbit',
    rabbit_password => 'secret_rpc_password_for_manila',
    rabbit_host     => 'openstack-controller.example.com',
    verbose         => true,
  }
  
  class {'manila::api':
    keystone_password  => $keystone_password,
    keystone_auth_host => $keystone_auth_host,
    os_region_name     => 'DEFAULT'
  }
  class {'manila::scheduler':
    scheduler_driver => 'manila.scheduler.filter_scheduler.FilterScheduler',
  }
  class {'::manila::share':
    package_ensure => $package_ensure
  }
  manila::backend::glusternfs {'nfs':
    glusterfs_target              => [remoteuser@]<volserver>:/<volid>,
    glusterfs_mount_point_base    => '/nfs',
    glusterfs_nfs_server_type     => 'Gluster',
    glusterfs_path_to_private_key => 'ssh_private_key_path',
    glusterfs_ganesha_server_ip,  => 'ganesha_server_ip',

```


## 核心代码讲解
### class manila

manila 这个类用于安装 openstack-manila 基础包，同时使用 manila_config来管理日志/消息队列/SSL等参数

例如，下面的代码使用 manila_config 配置了SSL相关的参数：

```puppet
  # SSL Options
  if $use_ssl {
    manila_config {
      'DEFAULT/ssl_cert_file' : value => $cert_file;
      'DEFAULT/ssl_key_file' :  value => $key_file;
    }
    if $ca_file {
      manila_config { 'DEFAULT/ssl_ca_file' :
        value => $ca_file,
      }
    } else {
      manila_config { 'DEFAULT/ssl_ca_file' :
        ensure => absent,
      }
    }
  } else {
    manila_config {
      'DEFAULT/ssl_cert_file' : ensure => absent;
      'DEFAULT/ssl_key_file' :  ensure => absent;
      'DEFAULT/ssl_ca_file' :   ensure => absent;
    }
  }
```

### class manila::db
调用`manila_config`来进行数据库相关的配置,比较有意思的是下面这段代码
```puppet
  validate_re($database_connection_real,
    '^(sqlite|mysql(\+pymysql)?|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  # 根据不同的数据库后端来执行不同的操作
  if $database_connection_real {
    case $database_connection_real {
      /^mysql(\+pymysql)?:\/\//: {
        require 'mysql::bindings'
        require 'mysql::bindings::python'
        if $database_connection_real =~ /^mysql\+pymysql/ {
          $backend_package = $::manila::params::pymysql_package_name
        } else {
          $backend_package = false
        }
      }
      /^postgresql:\/\//: {
        $backend_package = false
        require 'postgresql::lib::python'
      }
      /^sqlite:\/\//: {
        $backend_package = $::manila::params::sqlite_package_name
      }
      default: {
        fail('Unsupported backend configured')
      }
    }
```
### class manila::api
除了传统的装软件包/改配置/启动服务三板斧,没有别的好讲的

### class manila::scheduler
同上
### class manila::share
同上
### class manila::backends
配置开启哪些存储后端
```puppet
class manila::backends (
  $enabled_share_backends = undef
) {

  # Maybe this could be extented to dynamicly find the enabled names
  manila_config {
    'DEFAULT/enabled_share_backends': value => join($enabled_share_backends, ',');
  }

}
```
### define manila::backend::glusternfs
```puppet
  # 通过manila_config来修改manila配置
  manila_config {
    "${share_backend_name}/share_backend_name":            value => $share_backend_name;
    "${share_backend_name}/share_driver":                  value => $share_driver;
    "${share_backend_name}/glusterfs_target":              value => $glusterfs_target;
    "${share_backend_name}/glusterfs_mount_point_base":    value => $glusterfs_mount_point_base;
    "${share_backend_name}/glusterfs_nfs_server_type":     value => $glusterfs_nfs_server_type;
    "${share_backend_name}/glusterfs_path_to_private_key": value => $glusterfs_path_to_private_key;
    "${share_backend_name}/glusterfs_ganesha_server_ip":   value => $glusterfs_ganesha_server_ip;
  }
```

##小结
manila 服务的部署比较简单，使用 puppet 能够方便的部署起 manila 服务起来，如果想进一步学习 manila 服务的使用，可以参考 openstack 官方的文档。

##动手练习
- 部署 manila 服务，创建两台云主机和一个共享卷并挂载
