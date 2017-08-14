# Puppet-keystone模块介绍

0. [基础知识 - 快速了解Keystone ](#基础知识)
1. [先睹为快](#先睹为快)
2. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
    - [class keystone](###class keystone)
    - [class keystone::service](###class keystone::service)
    - [class keystone::endpoint](###class keystone::endpoint)
    - [define keystone::resource::service_identity](###define  keystone::resource::service_identity)
    - [class keystone::config](###class keystone::config) 
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

#基础知识

`puppet-keystone`是用于配置和管理Keystone，包括服务，软件包，Keystone user，role，service，endpoint等等。其中keystone user, role, service, endpoint等资源的管理是通过自定义的resource type来实现。

在开始介绍puppet-keystone模块前，先来看看Keystone中的基础概念。

Identity
---
Keystone的认证部分包含：`user`和`group`，可以通过SQL或通用LDAP支持。

| 名称 | 说明 |
|--------|:-----:|
| user | user表示独立的API消费者，user非全局唯一，必须属于某个domain，但在domain命名空间下唯一 |
| group| group表示汇总user集合的容器，和user一样，group非全局唯一，group必须属于某个domain，在domain命名空间下唯一|

Resources
---
Keystone的resources部分包含：`Projects`和`Domains`，通常存储在SQL中。

| 名称 | 说明 |
|--------|:-----:|
|Project(Tenant)|Project(在v2.0时也称为Tenant)表示Openstack基本单位的所有权限，表示在Openstack中的资源必须归属于某个特定project。project同样的，非全局唯一，必须归属于某个domain，在domain命名空间下唯一。若一个project没有被指定domain，那么它的domain会被设置为default |
|Domain|domain是project，user和group的更高层级的容器。每个domain定义了一个命名空间，keystone默认提供了一个名为'Default'的domain。Domain是全局唯一的。|

Assignment
---

| 名称 | 说明 |
|--------|:-----:|
|Role|role指定了user能获取的授权级别，roles可以授予到domain或project级别，role可以被指定到单独的user或group级别。注意噢，role可是全局唯一的。|
|Role Assignments|一个包含Role,Resource,Identity的三元组|

Token
===
Token服务验证和管理token，在完成对用户正确的认证请求后，Keystone会返回相应的token。token有时效期，在用户与Openstack服务的交互中，会使用token作为验证信息，提高系统的安全性。

Catalog
===
Catalog提供了各service的endpoint注册入口，用于endpoint自动发现。
以下是service catalog的样例：
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
通常，作为user是不用太关心这个列表的，catalog在以下情况下会出现在响应中：
 - token creation response (`POST /v3/auth/tokens`)
 - token validation response (`GET /v3/auth/tokens`)
 - standalone resource (`GET /v3/auth/catalog`)

Services
===
service catalog本身是由一组services组成，辣么service的定义是：


> Service实体表示Openstack中的web服务。每个service可以有0个或以上的endpoint，当然有没有endpoint的service并没有什么卵用。完整描述请参见：[Identity API v3 spec](https://github.com/openstack/keystone-specs/blob/master/api/v3/identity-api-v3.rst#services-v3services)

除了和endpoint相关以外，还有两个非常重要的属性：

- name (string)

> 面向用户的service名称

这表示该参数的值不是为了让程序去解析的，而是作为一个终端用户可读的字符串。例如keystone服务的name，你可以设置为"Keystone"或者"UnitedStack Public Cloud Indetity Service"。因此，使用者可以根据实际需求来设置。

- type (string)

> 描述service所实现的API。该参数值只能在给定的列表中选择。目前Openstack支持的参数值是：`compute, image, ec2, identity, volume, network`。

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

这个完整URL应该由不带版本信息的基础URL加端口号组成。一个好例子是这样滴：
`https://identity.example.com:35357/`，相反的,`https://identity.example.com:35357/v2.0/`就是一个反例，它引导所有的client去连接指定的v2.0版本，不管这些客户端能否处理哪里版本。


我们通过图例来解释这些比较复杂的概念：

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

顾名思义，用于创建和管理keystone的service,endpoint。

来看一段使用样例：

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
### define keystone::resource::service_identity

少侠莫慌，我们接着来看keystone::resource::service_identity，终于到路的尽头了，我们来看看它是怎么实现的。
我先看看它是如何实现管理user的。
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
这里的关键是keystone_user，这又是一个自定义resource type，其源码路径为:

* lib/puppet/type/keystone_config.rb   定义
* lib/puppet/provider/keystone_config/ini_setting.rb  实现 

通过keystone_user，puppet完成了user的管理工作（包括创建和修改）。
同理，我们还看到了keystone_domain，目的是完成对domain的管理。
剩下的代码同理，就不一一解读了。

### class keystone::config

这个类最初是由我(xingchao)提出用于自定义参数管理，自定义参数是指所有未被puppet-keystone模块管理的参数。怎么理解？
打个比方，keystone在Mitaka版本新增了一个参数称为new_mitaka_op（虚构），那么在puppet-keystone模块里并没有该参数，这时候，我们只要使用keystone::config就可以轻松完成参数的管理。
在hiera文件中添加如下代码：

```yaml
---
   keystone::config::keystone_config:
     DEFAULT/new_mitaka_opt:
       value: newValue
```

## 小结
  在这里，我们介绍了puppet-keystone的核心代码，当然该module还有许多重要的class我们并没有涉及，例如：keystone::deps，keystone::policy等等。这些就留给读者自己去阅读代码了，当然在后期的版本中，我也会进一步去完善puppet-keystone的核心代码内容。

## 动手练习

1. 配置token_flush的cron job，使得可以定期清理Keystone数据库的token表中token失效数据。
2. 将keystone服务运行在Apache上
3. 如何开启keystone的debug日志级别
4. 接第3问，在keystone和keystone::loging里都存在$verbose变量，这种代码冗余的原因是出于什么考虑？可以移除吗？

