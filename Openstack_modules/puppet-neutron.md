# puppet-neutron 模块介绍
1. [先睹为快 - 一言不合，立马动手?](##先睹为快)
2. [核心代码讲解 - 如何做到管理各 Neutron 服务？](##核心代码讲解)
    - [class neutron](###class neutron)
    - [class neutron::keystone::auth](###class neutron::keystone::auth)
    - [class neutron::server](###class neutron::server)
    - [class neutron::plugins::ml2](###class neutron::plugins::ml2)
    - [class neutron::agents::ml2::ovs](###class neutron::agents::ml2::ovs)
    - [class neutron::agents::l3](###class neutron::agents::l3)
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
neutron::plugins::ml2 用于配置 ml2 plugin 相关的配置，包括 `/etc/neutron/plugin.ini` 软链接的创建，服务配置项的管理等等。关于 ml2 plugin 的配置，在 neutron 中有专用的自定义资源 `neutron_plugin_ml2` 用来配置 ml2 的配置文件：

```puppet
  neutron_plugin_ml2 {
    'ml2/type_drivers':                     value => join(any2array($type_drivers), ',');
    'ml2/tenant_network_types':             value => join(any2array($tenant_network_types), ',');
    'ml2/mechanism_drivers':                value => join(any2array($mechanism_drivers), ',');
    'ml2/path_mtu':                         value => $path_mtu;
    'ml2/extension_drivers':                value => join(any2array($extension_drivers), ',');
    'securitygroup/enable_security_group':  value => $enable_security_group;
    'securitygroup/firewall_driver':        value => $firewall_driver;
  }
```

并且，还控制了 ml2-plugin 软件包的安装顺序，在安装完软件包之后才应该配置其相关配置文件：

``` puppet
  if $::neutron::params::ml2_server_package {
    package { 'neutron-plugin-ml2':
      ensure => $package_ensure,
      name   => $::neutron::params::ml2_server_package,
      tag    => 'openstack',
    }
    Package['neutron-plugin-ml2'] -> File['/etc/neutron/plugin.ini']
    Package['neutron-plugin-ml2'] -> File['/etc/default/neutron-server']
    Package['neutron-plugin-ml2'] -> Neutron_plugin_sriov<||>
  } else {
    Package['neutron'] -> File['/etc/neutron/plugin.ini']
    Package['neutron'] -> File['/etc/default/neutron-server']
    Package['neutron'] -> Neutron_plugin_sriov<||>
  }
```

### class neutron::agents::ml2::ovs
openvswitch-agent 是使用 neutron 使最常用的 agent，它通常被部署在网络节点和计算节点，用来完成 ovs bridge 的管理，ovs-agent 由 neutron::agents::ml2::ovs 这个类来进行管理，neutron 模块中为 ovs-agent 的配置提供了专门的自定义资源 `neutron_agent_ovs` 用于管理其配置文件，这个类中，主要使用了 `neutron_agnet_ovs` 来完成  ovs-agent 的配置，并管理了 ovs-agent 的软件包和服务。与这个类类似的，还有 `neutron::agents::ml2::linuxbridge` 用来管理 linuxbridge-agent 相关的配置和服务。

### class neutron::agents::l3
l3-agent 通常部署在网络节点，提供网络间转发与路由的功能，`neutron::agents::l3` 这个类用于完成 L3-agent 的配置与管理。值得注意的是，它在代码中，使用了 `is_service_default` 这个函数：

```puppet
  if ! is_service_default ($external_network_bridge) {
    warning('parameter external_network_bridge is deprecated')
  }

  if ! is_service_default ($router_id) {
    warning('parameter router_id is deprecated and will be removed in future release')
  }
```

这个函数是在 [puppet-openstacklib](Library_modules/puppet-openstacklib.md) 中，定义的，它的作用是判断一个变量的值是否等于 $::os_service_default 这个 facter 的值，即这个变量是否为默认值。这里对一些废弃参数的值进行了判断，如果用户修改了这些废弃参数的值，那么将会收到 warning 警告信息，告诉用户这个参数已经被废弃了。我们可以看到 `is_service_default` 这个函数的定义如下：

```puppet
module Puppet::Parser::Functions
  newfunction(:is_service_default, :type => :rvalue, :doc => <<-EOS
Returns true if the variable passed to this function is '<SERVICE DEFAULT>'
  EOS
  ) do |arguments|
    raise(Puppet::ParseError, "is_service_default(): Wrong number of arguments" +
          "given (#{arguments.size} for 1)") if arguments.size != 1

    value = arguments[0]

    unless value.is_a?(String)
      return false
    end

    return (value == '<SERVICE DEFAULT>')
  end
end
```

这个函数首先对传递的参数个数进行了检查，然后比较了参数类型是否为字符串，最后将参数与 `'<SERVICE DEFAULT>'` 进行比较，并返回布尔值。


## 小结
puppet-neutron 模块管理了 neutron 的 neutron-server 服务，各种 plugin以及不同的 agent 服务，同时模块总还有管理其他服务如 lbaas, vpnaas 等服务的专用类，读者可以自行去探究其代码。 
 
 ## 动手练习
1. 部署 neutron lbaas 服务，查看 neutron 模块中有哪些类是用来管理这个服务相关组件的
2. 使用 `neutron_port` 和 `neutron_router` 自定义资源来创建 neutron port 和 router 


