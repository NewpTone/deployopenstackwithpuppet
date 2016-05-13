# puppet-openstacklib
在部署一个 OpenStack 集群时，我们可能需要安装多个 OpenStack 项目，由于 OpenStack 项目都是按照类似的设计模式开发的，因此这些不同的服务的架构都具有某些共同的特点，例如每个服务一般都会有一个专用的数据库，都会使用消息队列来完成内部组件通信，一般都由 Python 开发，可以使用 WSGI 的方式进行部署等等...

由于这些服务的共同特性，在部署 OpenStack 服务时，我们的很多操作往往需要重复进行，例如为每个服务创建数据库，以及数据库的用户和访问权限，这些操作可能存在于每个服务对应的 Puppet 模块中，为了尽可能的减少重复性代码，社区将一些常用的通用性操作写成 Puppet 中的 define 并放在一个公共模块中供其他模块使用，这样其他模块只需要调用这个公共模块中定义好 define 资源即可。这个公共模块就是 `puppet-oepnstacklib`，它的作用类似于软件开发中的公共类库。

## 主要资源
`puppet-openstacklib` 这个模块主要提供了下面这些资源：

* `openstacklib::service_validation`，用于执行脚本或命令对服务可用性进行验证
* `openstacklib::db::mysql`，用于完成 mysql 数据库，数据库用户的创建和用户的授权
* `openstacklib::db::postgresql`，用于完成 postgresql 数据库，数据库用户的创建和用户的授权
* `openstacklib::policy::base`，用于配置 policy.json 文件
* `$::os_service_default` 这个 facter，用于设置 openstack 配置文件的默认值
* 用于定义各个服务配置的自定义资源所用的基础类

## 使用范例
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

如果想自己定义 policy.json 文件，可以使用 nova::policy 这个类，在这个类的代码中，实际是通过调用 `openstacklib::policy::base` 这个资源来完成对 policy.json 文件的配置。



