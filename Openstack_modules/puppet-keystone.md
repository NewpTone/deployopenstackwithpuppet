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

class keystone做了三件最核心的事情：

* 安装keystone软件包
* 管理keystone.conf中的核心参数
* 管理keystone服务








