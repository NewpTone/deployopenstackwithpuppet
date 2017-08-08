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

## 3. Keystone初始化管理

在OpenStack部署工作中，与Keystone相关的初始化操作是集群正常运行必不可少的步骤：
- 创建Domain
- 创建Project
- 创建User，设置Password
- 创建并指定Role
- 创建Service
- 创建Endpoint

也包括在后期的运维中，指定user的password更新或者endpoint的更改等常见操作都可以在Puppet中完成。而这背后的工作是通过`<service>::keystone::auth`来完成的。

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
通过函数`ensure_resource`调用了`keystone_service`自定义资源类型，并传入两个参数:
  - "${service_name_real}::${service_type}"
  - {'ensure' => $ensure, 'description' => $service_description,}

有细心的读者读到这里可能会好奇，把服务名称和服务类型作为一个参数传入keystone_service，它是怎么区分的？

先来看keystone_service.rb的代码片段(代码路径puppet-keystone/lib/puppet/type/keystone_service.rb)：

```ruby
  def self.title_patterns
    PuppetX::Keystone::CompositeNamevar.basic_split_title_patterns(:name, :type)
  end
```
title_patterns方法通过调用`PuppetX::Keystone::CompositeNamevar.basic_split_title_patterns`方法来得到`:name`和`:type`变量。

接着跳转到basic_split_title_patterns的定义(代码路径lib/puppet_x/keystone/composite_namevar.rb):
```ruby
  def self.not_two_colon_regex
    # Anything but 2 consecutive colons.
    Regexp.new(/(?:[^:]|:[^:])+/)
  end

  def self.basic_split_title_patterns(prefix, suffix, separator = '::', *regexps)
    associated_regexps = []
    if regexps.empty? and separator == '::'
      associated_regexps += [not_two_colon_regex, not_two_colon_regex]
    else
      if regexps.count != 2
        raise(Puppet::DevError, 'You must provide two regexps')
      else
        associated_regexps += regexps
      end
    end
    prefix_re = associated_regexps[0]
    suffix_re = associated_regexps[1]
    [
      [
        /^(#{prefix_re})#{separator}(#{suffix_re})$/,
        [
          [prefix],
          [suffix]
        ]
      ],
      [
        /^(#{prefix_re})$/,
        [
          [prefix]
        ]
      ]
    ]
  end
```
可以看到`basic_split_title_patterns`方法默认使用'::'作为分隔符，通过not_two_colon_regex函数进行正则匹配并切割字符串。
至此，我们从上到下地剖析了如何实现Keystone相关资源的初始化，以加深读者对于代码的理解。在实际使用中，对于终端用户来说，并不需要关心底层的Ruby代码。

### 3.2 `class <service>::keystone::authtoken`

`<service>::keystone::authtoken`用于管理OpenStack各服务配置文件中的keystone_authtoken配置节。以Aodh服务为例:

```puppet
class aodh::keystone::authtoken(
...){

  ...

  keystone::resource::authtoken { 'aodh_config':
    username                       => $username,
    password                       => $password,
    project_name                   => $project_name,
    auth_url                       => $auth_url,
    auth_uri                       => $auth_uri,
    auth_version                   => $auth_version,
    auth_type                      => $auth_type,
    auth_section                   => $auth_section,
    ...
    memcache_pool_conn_get_timeout => $memcache_pool_conn_get_timeout,
    memcache_pool_dead_retry       => $memcache_pool_dead_retry,
    memcache_pool_maxsize          => $memcache_pool_maxsize,
    memcache_pool_socket_timeout   => $memcache_pool_socket_timeout,
    ...
  }
}
```
`aodh::keystone::authtoken`定义中声明了`define keystone::resource::authtoken`，并重写了部分参数的默认值。
`keystone::resource::authtoken`中定义了hash类型变量$keystonemiddleware_options，涵盖了keystone_authtoken配置节下的所有参数，
最终通过调用create_resources函数，传入服务名称参数$name，从而完成指定服务配置文件中keystone_authtoken的配置。
```puppet
  $keystonemiddleware_options = {
    'keystone_authtoken/auth_section'                   => {'value' => $auth_section},
    'keystone_authtoken/auth_uri'                       => {'value' => $auth_uri},
    'keystone_authtoken/auth_type'                      => {'value' => $auth_type},
    'keystone_authtoken/auth_version'                   => {'value' => $auth_version},
    'keystone_authtoken/cache'                          => {'value' => $cache},
     ...
    'keystone_authtoken/username'                       => {'value' => $username},
    'keystone_authtoken/password'                       => {'value' => $password, 'secret' => true},
    'keystone_authtoken/user_domain_name'               => {'value' => $user_domain_name},
    'keystone_authtoken/project_name'                   => {'value' => $project_name},
    'keystone_authtoken/project_domain_name'            => {'value' => $project_domain_name},
    'keystone_authtoken/insecure'                       => {'value' => $insecure},
  }
  create_resources($name, $keystonemiddleware_options)
```

## 4.维护不同Linux发行版之间的数据

PuppetOpenstack支持在Redhat, CentOS, Ubuntu等多个Linux发行版上部署OpenStack服务，然而在不同的Linux发行版中，同一个OpenStack服务的软件包的名称会有所不同。

例如，Nova API软件包的名称在Redhat下是'openstack-nova-api'，在Debian下是'nova-api'。

而这些数据则通过各个模块的`class <service>::params`维护。

以keystone::params为例，可以看到不同的Linux发行版之间$package_name, $service_name等参数值也有所不同:

```puppet
class keystone::params {
  include ::openstacklib::defaults
  $client_package_name = 'python-keystoneclient'
  $keystone_user       = 'keystone'
  $keystone_group      = 'keystone'
  $keystone_wsgi_admin_script_path  = '/usr/bin/keystone-wsgi-admin'
  $keystone_wsgi_public_script_path = '/usr/bin/keystone-wsgi-public'
  case $::osfamily {
    'Debian': {
      $package_name                 = 'keystone'
      $service_name                 = 'keystone'
      $keystone_wsgi_script_path    = '/usr/lib/cgi-bin/keystone'
      $python_memcache_package_name = 'python-memcache'
      $mellon_package_name          = 'libapache2-mod-auth-mellon'
      $openidc_package_name         = 'libapache2-mod-auth-openidc'
    }
    'RedHat': {
      $package_name                 = 'openstack-keystone'
      $service_name                 = 'openstack-keystone'
      $keystone_wsgi_script_path    = '/var/www/cgi-bin/keystone'
      $python_memcache_package_name = 'python-memcached'
      $mellon_package_name          = 'mod_auth_mellon'
      $openidc_package_name         = 'mod_auth_openidc'
    }
    default: {
      fail("Unsupported osfamily ${::osfamily}")
    }
  }
}
```

##  5. 管理自定义配置项的`<service>::config`

模板是用于管理配置文件的常见方式，对于成熟的项目而言，模板是一种理想的管理配置文件方式。但对于快速迭代的项目如OpenStack，维护人员会非常痛苦，每增删一个配置项需要同时更新模板和manifets文件。

试想一个module的更新若都在参数的增添上，那对社区开发者来说是极大的成本。有没有一种办法可以不修改module，直接在hiera里定义来添加新配置项呢？

`<service>::config`类是由笔者在14年初提出的特性，目的是灵活地管理自定义配置项。

自定义配置项是指未被模块管理的参数。怎么理解？

以`keystone::config`为例，其核心是create_resources函数以及`keystone_config/keystone_paste_init`自定义资源：

```puppet
# == Class: keystone::config
#
# This class is used to manage arbitrary keystone configurations.
#
# === Parameters
#
# [*keystone_config*]
#   (optional) Allow configuration of arbitrary keystone configurations.
#   The value is an hash of keystone_config resources. Example:
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#   In yaml format, Example:
#   keystone_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
# [*keystone_paste_ini*]
#   (optional) Allow configuration of /etc/keystone/keystone-paste.ini options.
#
#   NOTE: The configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
class keystone::config (
  $keystone_config  = {},
  $keystone_paste_ini = {},
) {

  include ::keystone::deps

  validate_hash($keystone_config)
  validate_hash($keystone_paste_ini)

  create_resources('keystone_config', $keystone_config)
  create_resources('keystone_paste_ini', $keystone_paste_ini)
}
```

若Keystone在某版本新增了参数new_param，在puppet-keystone模块里没有该参数，此时，只要使用keystone::config就可以轻松完成参数的管理。

在hiera文件中添加以下代码：

```yaml
---
   keystone::config::keystone_config:
     DEFAULT/new_param:
       value: newValue
```

## 6.管理客户端 `<service>::client`

`<service>::client`用于管理各OpenStack服务的Client端，完成客户端的安装。

以Nova为例，nova::client完成了`python-novaclient`软件包的安装：

```puppet
class nova::client(
  $ensure = 'present'
) {
  include ::nova::deps

  package { 'python-novaclient':
    ensure => $ensure,
    tag    => ['openstack', 'nova-support-package'],
  }

}
```

## 7. 管理策略`<service>::policy`

`<service>::policy`用于管理Openstack各服务的策略文件policy.json。

以Cinder为例，下面是cinder::policy代码：
```puppet
class cinder::policy (
  $policies    = {},
  $policy_path = '/etc/cinder/policy.json',
) {

  include ::cinder::deps

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)
  oslo::policy { 'cinder_config': policy_file => $policy_path }

}
```
其中使用create_resources调用了`openstacklib::policy::base`，以及声明了oslo::policy定义。
