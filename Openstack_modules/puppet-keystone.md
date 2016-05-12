# Puppet-keystone模块介绍

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
3.  - [class keystone](###class keystone)
3. 
3. 


puppet-keystone是用来配置和管理keystone服务，包括服务，软件包，keystone user，role，service，endpoint等等。其中 keystone user, role, service, endpoint等资源的管理是使用自定义的resource type来实现。


## 先睹为快

在解说puppet-keystone模块前，让我们来使用它部署一个keystone服务先吧。

在终端下执行以下命令:

```bash
puppet apply -v keystone/examples/v3_basic.pp
```

等待puppet执行完成后，在终端下试试吧：

```bash
# To be sure everything is working, run:
   $ export OS_IDENTITY_API_VERSION=3
   $ export OS_USERNAME=admin
   $ export OS_USER_DOMAIN_NAME=admin_domain
   $ export OS_PASSWORD=ChangeMe
   $ export OS_PROJECT_NAME=admin
   $ export OS_PROJECT_DOMAIN_NAME=admin_domain
   $ export OS_AUTH_URL=http://keystone.local:35357/v3
   $ openstack user list
```

这是如何做到的？下面来看看v3_basic.pp的代码

```puppet
#设置了全局的Exec属性，当命令执行失败时，输出结果
Exec { logoutput => 'on_failure' } 

# 安装MySQL服务
class { '::mysql::server': }
# 配置keystone database
class { '::keystone::db::mysql':
  password => 'keystone',
}
# 配置keystone服务
class { '::keystone':
  verbose             => true,
  debug               => true,
  database_connection => 'mysql://keystone:keystone@127.0.0.1/keystone',
  admin_token         => 'admin_token',
  enabled             => true,
}
# 设置admin role
class { '::keystone::roles::admin':
  email               => 'test@example.tld',
  password            => 'a_big_secret',
  admin               => 'admin', # username
  admin_tenant        => 'admin', # project name
  admin_user_domain   => 'admin', # domain for user
  admin_tenant_domain => 'admin', # domain for project
}
# 创建keystone endpoint
class { '::keystone::endpoint':
  public_url => 'http://127.0.0.1:5000/',
  admin_url  => 'http://127.0.0.1:35357/',
}
```

## 核心代码讲解


### class keystone

class keystone逻辑非常复杂，我们先抛开大量的判断逻辑和类调用，它主要做了三件核心工作：

* 安装keystone软件包
* 管理keystone.conf中的核心参数
* 管理keystone服务

#### keystone软件包管理

这里有一个非常有用的参数是$package_ensure，我们可以指定软件包的版本，或者将其标记为总是安装最新版本，我们将会在最佳实践部分去介绍它。

```puppet
# keystone软件包
  package { 'keystone':
    ensure => $package_ensure,
    name   => $::keystone::params::package_name,
    tag    => ['openstack', 'keystone-package'],
  }
# keystone-client软件包 
  if $client_package_ensure == 'present' {
    include '::keystone::client'
  } else {
    class { '::keystone::client':
      ensure => $client_package_ensure,
    }
  }
```

#### keystone.conf核心参数管理

class keystone里管理了大量的配置参数，比如cache,token,db,endpoint设置等相关参数，这里不一一列举。

这里只一个代码片段为例来解释keystone_config的用法。keystone_config是一个自定义的resource type，其源码路径位于：

* lib/puppet/type/keystone_config.rb   定义
* lib/puppet/provider/keystone_config/ini_setting.rb  实现 

在这里我们关注如何使用，在Advanced Puppet一书中我们将讲解如何编写custom resource type。

keystone_config有多种使用方法:

对指定参数赋值：
``` puppet
   keystone_config { 'section_name/option_name': value => option_value}
```

对指定参数赋值，并设置为加密：
``` puppet
   keystone_config { 'section_name/option_name': value => option_value， secret => true}
```
我们知道puppet agent的所有输出默认都会被syslog打到系统日志/var/log/messages中，那么有心人只要用grep就能从中搜到许多敏感信息，例如：admin_token, user_password,  keystone_db_password等等。只要设置了secret为true后，那么就不会把该参数的相关日志打到系统日志中。

删除指定参数:
``` puppet
   keystone_config { 'section_name/option_name': ensure => absent}
```

OK，讲解就到这里，我们来看代码。
```puppet
  keystone_config {
    'DEFAULT/admin_token':      value => $admin_token, secret => true;
    'DEFAULT/public_bind_host': value => $public_bind_host;
    'DEFAULT/admin_bind_host':  value => $admin_bind_host;
    'DEFAULT/public_port':      value => $public_port;
    'DEFAULT/admin_port':       value => $admin_port;
    'paste_deploy/config_file': value => $paste_config;
  }
```
#### keystone服务管理
   puppet支持keystone以单进程模式运行或者跑在Apache上，请注意，如果需要将keystone运行在Apache上，那么需要添加keystone::wsgi::apache，代码如下：
```puppet
   class { 'keystone':
      ...
      service_name => 'httpd',
      ...
   }
   class { 'keystone::wsgi::apache':
      ...
   }
```
我们来看一下管理keystone服务的逻辑：
```puppet
 if $service_name == $::keystone::params::service_name {
    $service_name_real = $::keystone::params::service_name
    if $validate_service {
      if $validate_auth_url {
        $v_auth_url = $validate_auth_url
      } else {
        $v_auth_url = $admin_endpoint
      }
      
      #这里调用了keystone::service类，用于管理keystone服务的具体配置
      class { '::keystone::service':
        ensure         => $service_ensure,
        service_name   => $service_name,
        enable         => $enabled,
        hasstatus      => true,
        hasrestart     => true,
        validate       => true,
        admin_endpoint => $v_auth_url,
        admin_token    => $admin_token,
        insecure       => $validate_insecure,
        cacert         => $validate_cacert,
      }
    } else {
      class { '::keystone::service':
        ensure       => $service_ensure,
        service_name => $service_name,
        enable       => $enabled,
        hasstatus    => true,
        hasrestart   => true,
        validate     => false,
      }
    }
    warning('Keystone under Eventlet has been deprecated during the Kilo cycle. Support for deploying under eventlet will be dropped as of the M-release of OpenStack.')
  } elsif $service_name == 'httpd' {
    # 在这里，我们可以看到当$service_name为httpd时，将keystone service的状态设置为了stopped。
    include ::apache::params
    class { '::keystone::service':
      ensure       => 'stopped',
      service_name => $::keystone::params::service_name,
      enable       => false,
      validate     => false,
    }
    $service_name_real = $::apache::params::service_name
    # leave this here because Ubuntu packages will start Keystone and we need it stopped
    # before apache can run
    Service['keystone'] -> Service[$service_name_real]
  } else {
      fail('Invalid service_name. Either keystone/openstack-keystone for running as a standalone service, or httpd for being run by a httpd server')
  }
```

### class keystone::service

我们在class keystone中就遇到了keystone::service，那么来看看其代码。值得一讲有两块代码：

第一段是管理keystone服务：
```puppet
  service { 'keystone':
    ensure     => $ensure,
    name       => $service_name,
    enable     => $enable,
    hasstatus  => $hasstatus,
    hasrestart => $hasrestart,
    tag        => 'keystone-service',
  }
```
第二段代码比较有意思，类似于smoketest，简单调用keystone的user list接口来验证keystone服务是否正常运行：
```puppet
  if $validate and $admin_token and $admin_endpoint {
    $cmd = "openstack --os-auth-url ${admin_endpoint} --os-token ${admin_token} ${insecure_s} ${cacert_s} user list"
    $catch = 'name'
    exec { 'validate_keystone_connection':
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      provider    => shell,
      command     => $cmd,
      subscribe   => Service['keystone'],
      refreshonly => true,
      tries       => $retries,
      try_sleep   => $delay,
      notify      => Anchor['keystone::service::end'],
    }
  }
```

### class keystone::endpoint 





