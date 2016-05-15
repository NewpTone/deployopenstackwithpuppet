# puppet-openstacklib
1. [核心代码讲解 - puppet-openstacklib 中的主要资源](##核心代码讲解)
    - [define openstacklib::db::mysql](###openstacklib::db::mysql)
    - [define openstacklib::service::validation](###openstacklib::service::validation)
    - [define openstacklib::policy::base](###openstacklib::policy::base)
    - [Puppet::Provider::Openstack::Auth](###Puppet::Provider::Openstack::Auth)
    - [openstack_config](###openstack_config)
    - [facter os_service_default](###os_service_default) 
2. [小结](##小结)


在部署一个 OpenStack 集群时，我们可能需要安装多个 OpenStack 项目，由于 OpenStack 项目都是按照类似的设计模式开发的，因此这些不同的服务的架构都具有某些共同的特点，例如每个服务一般都会有一个专用的数据库，都会使用消息队列来完成内部组件通信，一般都由 Python 开发，可以使用 WSGI 的方式进行部署等等...

由于这些服务的共同特性，在部署 OpenStack 服务时，我们的很多操作往往需要重复进行，例如为每个服务创建数据库，以及数据库的用户和访问权限，这些操作可能存在于每个服务对应的 Puppet 模块中，为了尽可能的减少重复性代码，社区将一些常用的通用性操作写成 Puppet 中的 define 并放在一个公共模块中供其他模块使用，这样其他模块只需要调用这个公共模块中定义好 define 资源即可。这个公共模块就是 `puppet-oepnstacklib`，它的作用类似于软件开发中的公共类库。

## 核心代码讲解
`puppet-openstacklib` 这个模块主要提供了下面这些资源：

* `openstacklib::service_validation`，用于执行脚本或命令对服务可用性进行验证
* `openstacklib::db::mysql`，用于完成 mysql 数据库，数据库用户的创建和用户的授权
* `openstacklib::db::postgresql`，用于完成 postgresql 数据库，数据库用户的创建和用户的授权
* `openstacklib::policy::base`，用于配置 policy.json 文件
* `$::os_service_default` 这个 facter，用于设置 openstack 配置文件的默认值
* 用于定义各个服务配置的自定义资源所用的基础类

### openstacklib::db::mysql
这里以 `puppet-nova` 模块为例，来看看 openstack 模块如何去使用 `puppet-openstacklib` 模块中的资源。例如，在配置数据库用户，权限以及数据库的创建时，nova 模块中的 nova::db::mysql 使用了 `openstacklib::db::mysql` 来创建数据库，用户，以及对用户授权：

```puppet
  ::openstacklib::db::mysql { 'nova':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
  }
 ```

### openstacklib::service::validation
nova 模块中的 nova::api 类调用了 `openstacklib::service::validation` 这个资源，用户可以自己定义服务的检查脚本，来对服务进行健康检查：

```puppet
  if $validate {
    $defaults = {
      'nova-api' => {
        'command'  => "nova --os-auth-url ${auth_uri} --os-tenant-name ${admin_tenant_name} --os-username ${admin_user} --os-password ${admin_password} flavor-list",
      }
    }
    $validation_options_hash = merge ($defaults, $validation_options)
    create_resources('openstacklib::service_validation', $validation_options_hash, {'subscribe' => 'Service[nova-api]'})
  }
```

### openstacklib::policy::base
如果想自己定义 policy.json 文件，可以使用 nova::policy 这个类，在这个类的代码中，实际是通过调用 `openstacklib::policy::base` 这个资源来完成对 policy.json 文件的配置：

```puppet
  $policy_defaults = {
    'file_path' => $policy_path,
    'require'   => Anchor['nova::config::begin'],
    'notify'    => Anchor['nova::config::end'],
  }

  create_resources('openstacklib::policy::base', $policies, $policy_defaults)
```

上面的代码使用 `create_resource` 函数动态的创建 `openstacklib::policy::base` 资源，实现配置 policy.json 文件的目的。

### Puppet::Provider::Openstack::Auth
`Puppet::Provider::Openstack::Auth` 是 puppet-openstacklib 提供一个类，它被其他 openstack 模块所使用，它的主要功能是为 CLI 接口提供认证的功能，认证信息的获取方式为：

1. 从环境变量中获取认证信息
2. 如果没有从环境变量中获取到密码信息，那么读取 /root/openrc 文件

当其他 openstack 模块中的自定义资源需要使用 CLI 接口时，都会将此类中的方法加载到新定义的类中，通过这个类提供的方法完成认证。

### openstack_config
openstack 中大部分项目的配置文件都使用 `ini` 格式的配置文件，puppet-openstack 社区为每个服务提供了自定义资源，用来完成对这些配置文件的管理，例如 `nova.conf` 中需要在 `[DEFAULT]` 这个 section 中添加一条配置如下：

```
[DEFAULT]
memcached_servers = 10.10.0.1:11211
```

可以使用 `nova_config` 这个自定义资源完成：

```puppet
nova_config { 'DEFAULT/memcached_servers':
  value => '10.10.0.1:11211',
}
```

所有这些自定义资源的实现都会使用 puppet-openstack 中的基础类 `openstack_config`，因此其他 openstack 模块都会依赖此模块。

### os_service_default
`nova.conf` 中需要在 `[DEFAULT]` 这个 section 中添加一条配置如下：

```
[DEFAULT]
memcached_servers = 10.10.0.1:11211
```

可以使用 `nova_config` 这个自定义资源完成：

```puppet
nova_config { 'DEFAULT/memcached_servers':
  value => '10.10.0.1:11211',
}
```

那么，如果我想从配置文件中删除这条配置，需要这样做：

```puppet
nova_config { 'DEFAULT/memcached_servers':
  ensure => absent,
}
```

可以看到两种代码传递的参数不同，因此我们在 openstack 模块中往往看到这种风格的代码：

```puppet
if $memcached_servers {
  nova_config { 'DEFAULT/memcached_servers': value  => join($memcached_servers, ',') }
} else {
  nova_config { 'DEFAULT/memcached_servers': ensure => absent }
}
```

由于配置一个参数和删除一个参数需要对自定义资源传递的参数不同，在 puppet 代码中往往需要很多这种条件判断语句。为了解决这个问题，puppet-openstack 社区推行了一种新的配置方式，对 ini 格式的自定义资源进行了一些修改，例如对于 `nova_config` 这个资源来说，使用一个特定的 value 参数来表示将此资源从配置文件中删除：

```puppet
nova_config { 'DEFAULT/memcached_servers':
  value => '<SERVICE DEFAULT>',
}
```

当给 value 参数传递 `'<SERVICE DEFAULT>'` 这个特定的字符串时，将会从 nova 的配置中删除对应的配置，这样服务就会使用默认的配置项。这个 `'<SERVICE DEFAULT>'` 字符串也是由 puppet-openstacklib 这个模块通过自定义 facter 提供的，其他模块只需要引用这个 facter 就可以了，不需要知道这个特定的字符串具体是什么。这个自定义的 facter 是使用 ruby 原生的方式，和键值对的方式定义的，这个 facter 就是 **$os_service_default**：

```ruby
require 'puppet/util/package'

if Puppet::Util::Package.versioncmp(Facter.value(:facterversion), '2.0.1') < 0
  Facter.add('os_service_default') do
    setcode do
      '<SERVICE DEFAULT>'
    end
  end
end
```

有了这个自定义的 facter，其他模块中，就可以使用这个 facter 作为配置文件参数的默认值，即默认从配置文件中删除对应的选项，由服务自己来使用默认值，这样在 puppet 中也不用额外维护一套各服务配置的默认配置了，同时也减少了很多条件判断语句的代码。

## 小结
puppet-openstacklib 这个模块的主要功能是作为其他模块的基础模块使用，对其他模块提供自定义的资源和 facter，用于配置数据库，policy.json，以及 CLI 接口的认证，几乎所有的 openstack 模块都会使用此模块。

