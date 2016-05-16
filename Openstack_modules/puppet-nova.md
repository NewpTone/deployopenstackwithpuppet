# puppet-nova 模块介绍
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理 Nova 服务？](#核心代码讲解)
    - [class nova](###class nova)
    - [class nova::keystone::auth](###class keystone::service)
    - [class nova::api](###class keystone::endpoint)
    - [define keystone::resource::service_identity](###define  keystone::resource::service_identity)
    - [class keystone::config](###class keystone::config) 
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 1.5h**

puppet-nova 是用来配置和管理 nova 服务，包括服务，软件包，配置文件，flavor，nova cells 等等。其中 nova flavor, cell 等资源的管理是使用自定义的resource type来实现的。

## 先睹为快
Nova 服务内部有很多组件，其中最重要的组件是 nova-api 和 nova-compute，这两个服务的部署可以使用 nova 模块中的类来完成，当然在部署之前环境中需要有 keystone 来为 nova 提供认证服务。

以部署 nova-api 为例：

```puppet
class { 'nova':
  rabbit_host         => 'localhost',
  rabbit_password     => 'password',
  rabbit_userid       => 'user',
  database_connection => 'mysql://nova:nova_pass@localhost/nova?charset=utf8',
}
class nova::keystone::auth {
  password => 'password',
}
class nova::api {
  admin_password => 'password',
}
```

即可完成 nova-api 的基本部署。其中 `nova` 这个类主要负责所有 nova 服务通用配置项的配置，`nova::keystone::auth` 用于创建 keystone 用户，服务，endpoint，以及角色和用户的关联，`nova::api` 用于部署 nova-api 服务，管理相关的配置文件，并管理 nova-api 服务。

### class nova
Nova 是一个有多个内部组件的 OpenStack 服务，这些服务可以分开部署在不同的节点中，服务之间使用消息队列进行通信，有些组件会使用到数据库，还可能和 keystone 服务进行交互。nova 虽然服务众多，但是配置文件只有一份，这个配置文件中所有服务通用的配置项，也有某个服务特有的配置项，对于通用的这些配置项，主要使用 `nova` 这类来进行管理，这个类主要管理了这些选项：

* 数据库相关的配置
* 消息队列相关的配置
* 日志相关的配置
* SSL 相关的配置

这个类主要使用 `nova_config` 来对这些配置进行管理，它的使用也非常简单，只用传递相关的参数就可以了。

### class nova::keystone::auth
这个类的主要功能是添加 keystone 用户，以及用户和角色的关联，它通过调用 keystone 模块的 `keystone::resource::service_identity` 这个 define 资源来完成所有 keystone 中资源的创建。

```puppet
  keystone::resource::service_identity { "nova service, user ${auth_name}":
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => 'compute',
    service_description => $service_description,
    service_name        => $real_service_name,
    region              => $region,
    auth_name           => $auth_name,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }
```

### class nova::api
nova::api 这个类用来配置和管理 nova-api 服务以及相应的配置，其中比较重要的是用于 keystone 认证的相关配置。

首先，代码中会使用 `nova::generic_service` 来完成 nova-api 这个软件包的安装和服务的管理，`nova::generic_service` 这个资源主要的作用是管理 nova 中各个组件的软件包安装和服务的启动： `  

```puppet
nova::generic_service { 'api':
    enabled        => $service_enabled,
    manage_service => $manage_service,
    ensure_package => $ensure_package,
    package_name   => $::nova::params::api_package_name,
    service_name   => $::nova::params::api_service_name,
    subscribe      => Class['cinder::client'],
}
```

然后通过 `nova_config` 和 `nova_paste_api_ini` 这个两个自定义资源来对 `/etc/nova/nova.conf` 和 `/etc/nova/api-paste.ini` 进行一系列的配置，并通过 `nova::db` 来进行数据库相关的配置。


### class nova::conductor
nova::conductor 这个类比较简单，主要使用 `nova::generic_service` 来完成
