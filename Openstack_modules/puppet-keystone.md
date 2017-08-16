# `puppet-keystone`模块介绍

0. [基础知识 - 理解Keystone](#基础知识)
1. [先睹为快](#先睹为快)
2. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
    - [class keystone](###class keystone)
    - [class keystone::service](###class keystone::service)
    - [class keystone::endpoint](###class keystone::endpoint)
    - [define keystone::resource::service_identity](###define  keystone::resource::service_identity)
    - [class keystone::config](###class keystone::config) 
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

# 0.基础知识

`puppet-keystone`是用于配置和管理Keystone，其中包括:服务，软件包，Keystone user，role，service，endpoint等等。其中keystone user, role, service, endpoint等资源的管理是通过自定义的resource type来实现。

在开始介绍puppet-keystone模块前，先来回顾一下Keystone中的基础概念。

Identity
---
Keystone的Identity：`user`和`group`，用于标识用户的身份，数据可以存在Keystone数据库中，或者也可以使用LDAP。

| 名称 | 说明 |
|--------|:-----:|
| user | user表示独立的API消费者，user非全局唯一，必须属于某个domain，但在domain命名空间下唯一 |
| group| group表示汇总user集合的容器，和user一样，group非全局唯一，必须属于某个domain，在domain命名空间下唯一|

Resources
---
Keystone的resources部分提供了两类数据：`Projects`和`Domains`，通常存储在SQL中。

| 名称 | 说明 |
|--------|:-----:|
|Project(Tenant)|Project(在v2.0时也称为Tenant)表示Openstack基本单位的所有权限。在OpenStack中的资源必须归属于某个特定project。project非全局唯一，必须归属于某个domain，在domain命名空间下唯一。若一个project没有被指定domain，那么其domain会被设置为default |
|Domain|domain是project，user和group更高层级的容器。每个domain定义了一个命名空间，Keystone默认提供了一个名为'Default'的默认domain。Domain是全局唯一的。|

Assignment
---
Assignment提供了role和role assignment的数据。

| 名称 | 说明 |
|--------|:-----:|
|Role| role指定了user能获取的授权级别，roles可以domain或project级别授予，role可以被指定到单独的user或group。注意噢，role可是全局唯一的。|
|Role Assignments|一个包含Role, Resource, Identity的三元组|

Token
===
Token服务用于验证和管理token，在完成对用户正确的认证请求后，Keystone会返回相应的token，token存在有效期。在用户与Openstack服务的交互中，会使用token作为验证信息，提高系统的安全性。

Catalog
===
Catalog提供了各个service的endpoint注册入口，用于endpoint自动发现。

以下是Keystone service catalog的样例：
```json
"catalog": [
    {
        "name": "Keystone",
        "type": "identity",
        "endpoints": [
            {
                "interface": "public",
                "url": "https://identity.example.com:35357/"
            }
        ]
    }
]
```
通常，作为用户不需要关心这个列表，catalog在以下情况下会作为返回值响应：
 - token creation response (`POST /v3/auth/tokens`)
 - token validation response (`GET /v3/auth/tokens`)
 - standalone resource (`GET /v3/auth/catalog`)

Services
===
service catalog本身是由一组services组成，service的定义是：


> Service实体表示Openstack中的web服务。每个service可以有0个或以上的endpoint，当然没有endpoint的service并没有什么实际用途。完整描述请参见：[Identity API v3 spec](https://github.com/openstack/keystone-specs/blob/master/api/v3/identity-api-v3.rst#services-v3services)

除了和endpoint相关以外，还有两个非常重要的属性：

- name (string)

> 面向用户的service名称

这表示该参数的值不是为了让程序去解析的，而是作为一个终端用户可读的字符串。例如keystone服务的name，你可以设置为"Keystone"或者"New Public Cloud Indetity Service"。因此，使用者可以根据实际需求来设置。

- type (string)

> 描述service所实现的API。该参数值只能在给定的列表中选择。目前Openstack支持的参数值有：`compute, image, ec2, identity, volume, network`等。

Endpoints
===

Endpoint表示API服务的基础URL，以及与其相关的metadata。每个服务应该有1个及以上相关的endpoint，例如：publicurl,adminurl,internalurl。

> Endpoint实体表示Opestack web services的URL。

- interface(string)

根据设置的类型来决定endpoint的访问权限：

  - `public`: 向终端用户提供可在公网上访问的网络接口
  - `internal`: 向终端用户提供近可在内部网络访问的网络接口
  - `admin`: 提供各个服务管理权限的访问，一般仅部署在内部并且加密的网络接口

多数服务在实际使用时，只需要设置`public`URL即可。

- url (string)

> service enpoint的完整URL。

这个完整URL应该由不带版本信息的基础URL加端口号组成。一个理想的url是：`https://identity.example.com:35357/`

相反,`https://identity.example.com:35357/v2.0/`作为一个反例，它引导所有的client去连接指定的v2.0版本，不管这些客户端能否处理哪里版本。


我们通过图例来解释这些复杂的概念：

Keystone v2 model
---
![](../images/03/keystone_v2.png)
 - user可以存在于不同的部门中（project），并且在各个部门中可以拥有不同的role。
 - SandraD在Aerospace是个系统管理员，在Comp Sci就变身为客户支持。

Keystone v3 model: Domain
---
![](../images/03/keystone_v3.png)
   - v3通过domain术语引入了多租户的概念。如上图，domain相当于是project的容器。
   - 通过domain，一个云用户就可以创建属于自己的user，groups和roles。

Keystone v3 model: Group
---
![](../images/03/keystone_v3_group.png)
- 往常我们需要为user/project赋予role，现在domain owner就可以把role赋予group，然后把user添加到group里去。
- role可以赋予到domain范围的group或者project范围的group 

在上图中：
- JohnB属于"domain1 sysadmins" group，拥有sysadmin role，并属于Bio,Aero,Compsci project。
- LisaD属于"Big Engineers"group，拥有Engineer role，仅属于compsci project。

Keystone服务组件
---
| 组件 | 描述 |
|--------|:-----:|
|openstack-keystone|对外提供认证和授权服务，同时支持v2/v3 API|
|keystone| 基于命令行的keystone客户端工具|


## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
$ puppet apply -v keystone/examples/v3_basic.pp
```

等待命令执行完成，在终端下试试吧：

```bash
   $ export OS_IDENTITY_API_VERSION=3
   $ export OS_USERNAME=admin
   $ export OS_USER_DOMAIN_NAME=admin_domain
   $ export OS_PASSWORD=ChangeMe
   $ export OS_PROJECT_NAME=admin
   $ export OS_PROJECT_DOMAIN_NAME=admin_domain
   $ export OS_AUTH_URL=http://keystone.local:35357/v3

   $ openstack user list
   $ openstack service list
```

这是如何做到的？下面来看v3_basic.pp代码

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

## 2.核心代码讲解

### 2.1 class keystone

`class keystone`逻辑非常复杂，暂先抛开大量的判断逻辑和类调用，它主要完成了三个主要任务：

* 安装Keystone软件包
* 管理Keystone.conf中的主要配置项 
* 管理Keystone服务

#### 2.1.1 keystone软件包管理

这里有一个重要参数$package_ensure，可以指定软件包的版本，或者将其标记为总是安装最新版本，本书将会在最佳实践部分再次提及它。

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

#### 2.1.2 keystone.conf核心参数管理

class keystone管理了大量的配置项，比如cache, token, db, endpoint等相关参数，这里不一一列举。

那么对于这些选项是如何管理的呢？这里我们要提到`keystone_config`。

`keystone_config`是一个自定义的resource type，其代码路径是：

* lib/puppet/type/keystone_config.rb   定义了keystone_config
* lib/puppet/provider/keystone_config/ini_setting.rb  实现了keystone_config

在这里我们关注如何使用`keystone_config`。

keystone_config有几种使用场景:

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

OK，讲解就到这里，下面看一段实际的代码。
```puppet
  keystone_config {
    'DEFAULT/admin_token':      value => $admin_token, secret => true;
    'DEFAULT/public_bind_host': value => $public_bind_host;
    'DEFAULT/admin_bind_host':  value => $admin_bind_host;
    'DEFAULT/public_port':      value => $public_port;
    'DEFAULT/admin_port':       value => $admin_port;
  }
```
与之对应的keystone.conf配置文件[DEFAULT]下的admin_token等配置项被Puppet修改为指定值。

#### 2.1.3 keystone服务管理
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
     ... 
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

### 2.2 class keystone::service

在`class keystone`中就遇到了keystone::service，从类的名称可以得知，该类用于管理Keystone服务。其中有两段代码需要注意：

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

### 2.3 class keystone::endpoint 

顾名思义，`class keystone::endpoint`用于创建和管理Keystone的service和endpoint。

以下是使用样例：

```puppet
  class { 'keystone::endpoint':
    public_url   => 'https://154.10.10.23:5000',
    internal_url => 'https://11.0.1.7:5000',
    admin_url    => 'https://10.0.1.7:35357',
  }
```
那么它是如何实现的呢？继续往下看，它又调用了一个define。

```puppet
  keystone::resource::service_identity { 'keystone':
    configure_user      => false,
    configure_user_role => false,
    service_type        => 'identity',
    service_description => 'OpenStack Identity Service',
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
    region              => $region,
    user_domain         => $user_domain,
    project_domain      => $project_domain,
    default_domain      => $default_domain,
  }
```
接下来，需要跳转到`keystone::resource::service_identity`的定义了。

### 2.3.1  define keystone::resource::service_identity

莫慌，接着来看keystone::resource::service_identity，终于到路的尽头了，来看看它是怎么实现的。

首先，它实现了管理keystone user：
```puppet
if $configure_user {
    if $user_domain_real {
      # We have to use ensure_resource here and hope for the best, because we have
      # no way to know if the $user_domain is the same domain passed as the
      # $default_domain parameter to class keystone.
      ensure_resource('keystone_domain', $user_domain_real, {
        'ensure'  => 'present',
        'enabled' => true,
      })
    }
    ensure_resource('keystone_user', $auth_name, {
      'ensure'                => 'present',
      'enabled'               => true,
      'password'              => $password,
      'email'                 => $email,
      'domain'                => $user_domain_real,
    })
    if ! $password {
      warning("No password had been set for ${auth_name} user.")
    }
  }
```

这里的关键是keystone_user资源，这又是一个自定义resource type，其源码路径为:

* lib/puppet/type/keystone_config.rb   定义
* lib/puppet/provider/keystone_config/ini_setting.rb  实现 

通过keystone_user，Puppet完成了对user的管理（包括创建,修改,查询）。

同理，还有keystone_domain，目的是完成对domain的管理。剩下的代码同理，就不一一解读了。

## 3.小结

  在这里，我们介绍了puppet-keystone的核心代码，当然该module还有许多重要的class我们并没有涉及，例如：keystone::deps，keystone::policy等等。这些就留给读者自己去阅读代码了。

## 4.动手练习

1. 配置token_flush的cron job，使得可以定期清理Keystone数据库的token表中token失效数据。
2. 将keystone服务运行在Apache上
3. 如何开启keystone的debug日志级别
4. 接第3问，在keystone和keystone::loging里都存在$verbose变量，这种代码冗余的原因是出于什么考虑？可以移除吗？
