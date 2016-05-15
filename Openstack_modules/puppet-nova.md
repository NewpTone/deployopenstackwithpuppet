# puppet-nova 模块介绍
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理 Nova 服务？](#核心代码讲解)
    - [class keystone](###class keystone)
    - [class keystone::service](###class keystone::service)
    - [class keystone::endpoint](###class keystone::endpoint)
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
class ::nova::api {
  admin_password => 'password',
}
```

即可完成 nova-api 的基本部署。



