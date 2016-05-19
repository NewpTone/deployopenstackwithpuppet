# puppet-neutron 模块介绍
1. [先睹为快 - 一言不合，立马动手?](##先睹为快)
2. [核心代码讲解 - 如何做到管理各 Neutron 服务？](##核心代码讲解)
    - [class neutron](###class neutron)
    - [class neutron::keystone::auth](###class neutron::keystone::auth)
    - [class neutron::server](###class neutron::server)
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

## 核心代码讲解
### class neutron
这个类主要完成一些通用的 neutron 配置，主要包括有：

* 消息队列相关的配置
* 日志相关的配置
* SSL 相关的配置

这个类主要使用 `neutron_config` 来对这些配置进行管理，同时还使用了 `oslo` 模块来完成消息队列相关的配置管理。

### class neutron::keystone::auth
这个类的主要功能是添加 keystone 用户，以及用户和角色的关联，它通过调用 keystone 模块的 `keystone::resource::service_identity` 这个 define 资源来完成所有 keystone 中资源的创建。

```puppet
  keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => $service_description,
    service_name        => $real_service_name,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => $public_url,
    admin_url           => $admin_url,
    internal_url        => $internal_url,
  }

```

### class neutron::server
nova::server 用来管理 neutron-server 服务，这个服务是 neutron 的核心服务，用于处理 API 请求。代码中主要使用 `neutron_config` 来完成 keystone 用户认证相关的配置，数据库连接相关的配置，以及一些 agent 的基础配置。

这个类的代码中多次了 `ensure_resource` 函数来创建资源，这样做的好处是 `ensure_resource` 在创建资源前会检查是否有重复的资源定义，如果有重复的资源定义那么就不再重复创建资源，可以避免资源的重复定义，我们来看一些这个函数是如何被使用的：

```puppet
  if $ensure_vpnaas_package {
    ensure_resource( 'package', 'neutron-vpnaas-agent', {
      'ensure' => $package_ensure,
      'name'   => $::neutron::params::vpnaas_agent_package,
      'tag'    => ['openstack', 'neutron-package'],
    })
  }
```

这里使用了 package 资源来进行软件包的管理，如果相同的资源已经定义过了，那么 `ensure_resource` 函数将不再重复创建此资源。


### class neutron::plugins::ml2
neutron::plugins::ml2 用于配置 ml2 plugin 相关的配置，包括 `/etc/neutron/plugin.ini` 软链接的创建，服务配置项的管理等等。

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


