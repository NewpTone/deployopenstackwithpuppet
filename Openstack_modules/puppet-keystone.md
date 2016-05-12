# Puppet-keystone模块介绍

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

为指定参数赋值：
``` puppet
   keystone_config { 'section_name/option_name': value => option_value}
   
```

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






