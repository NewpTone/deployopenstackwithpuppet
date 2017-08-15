# OpenStack模块代码结构

## 1.简介

在开始介绍各个OpenStack服务的Puppet模块前，先观察一下所有OpenStack module的目录结构，你会发现所有的模块的部分代码目录结构和命名方式几乎是一致的，这是经过了长期迭代和开发中形成的规范和统一，代码结构统一带来的好处有两点：

1. 易于维护人员理解和管理
2. 减少冗余代码，提高代码复用

那么我们就来看看一个OpenStack服务的Module中包含了哪些目录：

* examples/      放置示例代码   
* ext/           放置external代码，和主要代码无关，但是一些有用的脚本
* lib/           放置library代码，例如自定义facter,resource type
* manifests/     放置puppet代码
* releasenotes/  放置releasenote
* spec/          放置class,unit,acceptance测试
* tests/         已弃用，使用examples替代


以上目录中最重要的是manifests目录，用于放置Puppet代码，在该目录下包含了以下通用代码文件：

| 名称 | 说明 |
| -- | -- |
| init.pp | 主类，也称为入口类，通常仅用于管理公共参数（如MQ参数） |
| params.pp | 用于特定操作系统的参数值设置 |
| client.pp | 管理客户端的配置 |
| config.pp | 用于管理自定义的参数配置 |
| policy.pp | policy设置 |
| db/ | 支持多种数据库后端的配置 |
| keystone/ | keystone endpoint,service,user,role的设置 |


## 2.数据库管理

### 2.1 `class <service>::db`

`class <service>::db`用于管理各OpenStack服务中的数据库相关配置，`<service>`是OpenStack服务的名称，以Aodh为例：

```puppet 
class aodh::db (
  $database_db_max_retries = $::os_service_default,
  $database_connection     = 'sqlite:////var/lib/aodh/aodh.sqlite',
  $database_idle_timeout   = $::os_service_default,
  $database_min_pool_size  = $::os_service_default,
  $database_max_pool_size  = $::os_service_default,
  $database_max_retries    = $::os_service_default,
  $database_retry_interval = $::os_service_default,
  $database_max_overflow   = $::os_service_default,
) {

  include ::aodh::deps

  $database_connection_real = pick($::aodh::database_connection, $database_connection)
  $database_idle_timeout_real = pick($::aodh::database_idle_timeout, $database_idle_timeout)
  $database_min_pool_size_real = pick($::aodh::database_min_pool_size, $database_min_pool_size)
  $database_max_pool_size_real = pick($::aodh::database_max_pool_size, $database_max_pool_size)
  $database_max_retries_real = pick($::aodh::database_max_retries, $database_max_retries)
  $database_retry_interval_real = pick($::aodh::database_retry_interval, $database_retry_interval)
  $database_max_overflow_real = pick($::aodh::database_max_overflow, $database_max_overflow)

  oslo::db { 'aodh_config':
    db_max_retries => $database_db_max_retries,
    connection     => $database_connection_real,
    idle_timeout   => $database_idle_timeout_real,
    min_pool_size  => $database_min_pool_size_real,
    max_pool_size  => $database_max_pool_size_real,
    max_retries    => $database_max_retries_real,
    retry_interval => $database_retry_interval_real,
    max_overflow   => $database_max_overflow_real,
  }
}
```

`class aodh::db`管理了与数据库相关的配置项，其中通过调用`oslo::db`来实现，关于`puppet-oslo`模块，本书会在下一章节详细说明。

### 2.2 `class <service>::db::mysql`

`class <service>::db::mysql`用于创建相关服务的MySQL数据库，用户和授权等。以Aodh为例:

```puppet
class aodh::db::mysql(
  $password,
  $dbname        = 'aodh',
  $user          = 'aodh',
  $host          = '127.0.0.1',
  $charset       = 'utf8',
  $collate       = 'utf8_general_ci',
  $allowed_hosts = undef
) {

  include ::aodh::deps

  validate_string($password)

  ::openstacklib::db::mysql { 'aodh':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
  }

  Anchor['aodh::db::begin']
  ~> Class['aodh::db::mysql']
  ~> Anchor['aodh::db::end']

}
```
`class aodh::db::mysql`管理了MySQL aodh数据库的创建，aodh用户创建和密码设定，数据库编码，访问授权等。其调用了openstacklib::db::mysql来实现上述功能，关于`puppet-openstacklib`模块，本书会在下一章节详细说明。

### 2.3 `class <service>::db::postgresql`

`class <service>::db::mysql`用于创建相关服务的PostgreSQL数据库，用户和授权等。以Aodh为例:


```puppet
class aodh::db::postgresql(
  $password,
  $dbname     = 'aodh',
  $user       = 'aodh',
  $encoding   = undef,
  $privileges = 'ALL',
) {

  include ::aodh::deps

  ::openstacklib::db::postgresql { 'aodh':
    password_hash => postgresql_password($user, $password),
    dbname        => $dbname,
    user          => $user,
    encoding      => $encoding,
    privileges    => $privileges,
  }

  Anchor['aodh::db::begin']
  ~> Class['aodh::db::postgresql']
  ~> Anchor['aodh::db::end']

}
```
`class aodh::db::postgresql`完成了aodh数据库的创建，aodh用户创建和密码设定，数据库编码，访问授权等。其调用了openstacklib::db::postgresql来实现上述功能。

### 2.4  `class <service>::db::sync`

`class aodh::db::sync`用于执行数据库表的初始化和更新操作。以Aodh为例:

```puppet
class aodh::db::sync (
  $user = 'aodh',
){

  include ::aodh::deps

  exec { 'aodh-db-sync':
    command     => 'aodh-dbsync --config-file /etc/aodh/aodh.conf',
    path        => '/usr/bin',
    refreshonly => true,
    user        => $user,
    try_sleep   => 5,
    tries       => 10,
    logoutput   => on_failure,
    subscribe   => [
      Anchor['aodh::install::end'],
      Anchor['aodh::config::end'],
      Anchor['aodh::dbsync::begin']
    ],
    notify      => Anchor['aodh::dbsync::end'],
  }

}
```
aodh::db::sync的实现是通过声明exec资源来调用aodh-dbsync命令行完成数据库初始化的操作。

## 3.User，Role，Service, Endpoint管理

在OpenStack部署工作中，与Keystone相关的初始化操作是集群正常运行必不可少的步骤：
- 创建Domain
- 创建Project
- 创建User，设置Password
- 创建并指定Role
- 创建Service
- 创建Endpoint

包括后期的运维过程中，password或者endpoint的变更等常见操作都可以通过Puppet完成。而这背后的工作是通过`<service>::keystone::auth`来完成的。

### 3.1 `class <service>::keystone::auth`

`<service>::keystone::auth`用于创建OpenStack服务的user,service和endpoint，以Aodh为例：

```puppet
class aodh::keystone::auth (
  $password,
  $auth_name           = 'aodh',
  $email               = 'aodh@localhost',
  $tenant              = 'services',
  $configure_endpoint  = true,
  $configure_user      = true,
  $configure_user_role = true,
  $service_name        = 'aodh',
  $service_type        = 'alarming',
  $region              = 'RegionOne',
  $public_url          = 'http://127.0.0.1:8042',
  $internal_url        = 'http://127.0.0.1:8042',
  $admin_url           = 'http://127.0.0.1:8042',
) {

  include ::aodh::deps

  keystone::resource::service_identity { 'aodh':
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_name        => $service_name,
    service_type        => $service_type,
    service_description => 'OpenStack Alarming Service',
    region              => $region,
    auth_name           => $auth_name,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url,
    internal_url        => $internal_url,
    admin_url           => $admin_url,
  }

}
```
实际上`aodh::keystone::auth`在声明`define keystone::resource::service_identity`的基础上，根据Aodh服务而重写了相关的参数。

下面来看一段代码，关于`keystone::resource::service_identity`如何实现service的管理：
```
  if $configure_service {
    if $service_type {
      ensure_resource('keystone_service', "${service_name_real}::${service_type}", {
        'ensure'      => $ensure,
        'description' => $service_description,
      })
    } else {
      fail ('When configuring a service, you need to set the service_type parameter.')
    }
  }
```