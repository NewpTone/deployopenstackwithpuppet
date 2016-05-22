# puppet-ceilometer

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理ceilometer服务？](#核心代码讲解)
    - [class ceilometer](###class ceilometer)
    - [class ceilometer::api](###class ceilometer::api)
    - [class ceilometer::collector](###class ceilometer::collector)
    - [class ceilometer::db](###class ceilometer::db)
    - [class ceilometer::keystone::auth](###class ceilometer::keystone::auth)
    - [class ceilometer::logging](###class ceilometer::logging)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

## 先睹为快
ceilometer是openstack的数据收集模块，它把收集OpenStack内部发生的大部分事件，为计费和监控以及其它服务提供数据支撑。由于ceilometer依赖很多服务，所以最好先部署一个openstack，我们可以使用下一站章节的puppet-openstack-integration或devstack部署一套简易版openstack。
部署ceilometer：
在examples/site.pp里添加下面的代码,因为默认的site.pp里没有创建endpoint,role。
```puppet
  class { 'ceilometer::keystone::auth':
    password      => 'tralalayouyou'        #这个参数是puppet-openstack-integratioin中默认的。
  }
```
然后执行以下命令

```bash
# puppet apply examples/site.pp
```
等一会ceilometer就安装完成了。
验证：
```bash
# source openrc
# ceilometer event-list
```

## 核心代码讲解
### ceilometer

### ceilometer::api

### ceilometer::collector

### ceilometer::db

### ceilometer::keystone::auth
ceilometer::keystone::auth模块是用来创建ceilometer的endpoint和role，其中有这么一段代码：
```puppet
  ::keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => $service_description,
    service_name        => $service_name_real,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    roles               => ['admin', 'ResellerAdmin'],
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }
```
我们可以看到这里调用keystone::resource::service_identity这个define的时候前面有::符号，这就要讲到
puppet中的一个概念:域。
puppet中的域分为4种：顶级域、节点域、父域和本地域。在所有的类、定义或节点之外的就是顶级域，如在site.pp
中定义了一个$v的参数，那我们可以在任意位置之中使用$::v来调用它。
节点定义中节点名称后面的一对大括号就是节点域，节点域中定义的变量只能在该节点内调用。
父域和本地域的关系在于继承，如果class A通过关键字inherits引用了class B，如下：
```puppet
class A{
  $variable = 'v1'
  ...
}
class B inherits A {
  ...
}
```
那么我们可以在class B中通过$::A::variable的方式调用该变量.

返过来看我们这段代码， ::keystone::resource::service_identity 这个调用前面使用::是在顶级域中搜索
keystone模块。
### ceilometer::logging

## 小结
在puppet-ceilometer模块中还有一些其他的class,如：ceilometer::policy、 ceilometer::client、  ceilometer::config等，就留给读者自己去阅读了
## 动手练习
