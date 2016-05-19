# puppet-ceilometer

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理ceilometer服务？](#核心代码讲解)
    - [class ceilometer](###class ceilometer)
    - [class ceilometer::api](###class ceilometer::api)
    - 
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

## 先睹为快
ceilometer是openstack的数据收集模块，它把收集OpenStack内部发生的大部分事件，为计费和监控以及其它服务提供数据支撑。由于ceilometer依赖很多服务，所以最好先部署一个openstack，我们可以使用下一站章节的puppet-openstack-integration或devstack部署一套简易版openstack。
部署ceilometer：
在examples/site.pp里添加下面的代码
```puppet
  class { 'ceilometer::keystone::auth':
    password      => 'tralalayouyou'        #这个参数是puppet-openstack-integratioin中默认的。
  }
```
然后执行以下命令

```bash
# puppet apply examples/site.pp
```

## 核心代码讲解

## 小结

## 动手练习
