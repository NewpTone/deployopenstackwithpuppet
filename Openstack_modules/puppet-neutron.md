# puppet-neutron 模块介绍
1. [先睹为快 - 一言不合，立马动手?](##先睹为快)
2. [核心代码讲解 - 如何做到管理各 Neutron 服务？](##核心代码讲解)
    - [class nova](###class nova)
    - [class nova::keystone::auth](###class keystone::service)
    - [class nova::api](###class keystone::endpoint)
    - [class nova::conductor](###class nova::conductor)
    - [class nova::compute](###class nova::compute)
    - [class nova::network::neutron](###class nova::network::neutron)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 1.5h**

neutron 组件是 OpenStack 各组件中最为复杂的组件，puppet-neutron 模块提供了 neutron 各个组件的部署和管理，包括 neutron plugins 的管理和 neutron agents 的管理。

## 先睹为快
Neutron 是一个分布式的服务，它由 neutron-server 和不同功能的 agent 组成。neutron-server 用于处理 API 请求，agent 用来完成各种网络功能。

以部署 neutron-server 为例：

```puppet
  class { '::neutron::keystone::auth':
    public_url   => "http:/localhost:9696",
    internal_url => "http://localhost:9696",
    admin_url    => "http://localhost:9696",
    password     => 'a_big_secret',
  }
  class { '::neutron':
    rabbit_user           => 'neutron',
    rabbit_password       => 'an_even_bigger_secret',
    rabbit_host           => localhost,
    rabbit_port           => 5672,
    core_plugin           => 'ml2',
  }
  class { '::neutron::client': }
  class { '::neutron::server':
    database_connection => 'mysql+pymysql://neutron:neutron@127.0.0.1/neutron?charset=utf8',
    password            => 'a_big_secret',
  }
```

这里使用了 `neutron`，`neutron::client`，`neutron::server`，`neutron::keystone::auth` 四个类，分别用于完成服务的基础配置，客户端的安装，neutron-server 服务的配置和管理，以及 keystone 的认证。


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
nova::conductor 这个类比较简单，主要使用 `nova::generic_service` 来完成 conductor 服务和软件包的管理，并配置了 workers 参数。

### class nova::compute
nova::compute 这个类用来配置 nova-compute 服务，nova-compute 服务一般部署在计算节点，用于完成虚拟机的创建。

nova::compute 中主要完成了：

* nova-compute 相关配置的管理，如 VNC，网络相关的配置
* 管理 nova-compute 的软件包和服务

这些服务和配置的管理都是通过 `nova_config` 和 `nova::generic_service` 两个资源来完成的。

### class nova::migration::libvirt
nova 可以控制 Libvirt 来完成虚拟机的迁移，配置虚拟机迁移除了需要配置 nova 的配置之外，还需要配置 Libvirt 相关的配置，因此在 nova 模块中专门有一个 `nova::migration::libvirt` 的类来进行 libvirt 相关的配置，这个类中，使用了 `augeas` 和 `file_line` 资源来配置 `/etc/libvirt/libvirtd.conf`：

```puppet
    augeas { 'libvirt-conf-uuid':
      context => '/files/etc/libvirt/libvirtd.conf',
      changes => [
        "set host_uuid ${host_uuid}",
      ],
      notify  => Service['libvirt'],
      require => Package['libvirt'],
    }
  }
```

`augeas` 能够将配置文件当做树形的结构来进行处理，详细的使用说明可以参考[这里](https://projects.puppetlabs.com/projects/1/wiki/puppet_augeas)。同时，也使用了 `file_line` 来进行 libvirtd.conf 的配置：

```puppet
      file_line { '/etc/libvirt/libvirtd.conf listen_tls':
        path  => '/etc/libvirt/libvirtd.conf',
        line  => "listen_tls = ${listen_tls}",
        match => 'listen_tls =',
        tag   => 'libvirt-file_line',
      }
  ```
  
 ## 小结
 puppet-nova 模块中的内容众多，按照 nova 中的各个服务和功能进行了拆分，每个服务都有对应的 puppet 类进行管理，模块中还包含了 neutron, nova cell 等资源的管理，感兴趣的读者可以研究模块中其余的代码。
 
 ## 动手练习
1. nova 中的各个服务是通过哪个统一的自定义资源进行管理的？阅读这个 define 资源的代码，查看它的实现方式。
2. 部署 nova-api, nova-scheduler, nova-conductor 服务
3. 如何设置 nova-compute 服务的宿主机内存分配比，这些资源分配比例的设定是在哪个类中进行管理的？
4. 如何将 nova-compute


