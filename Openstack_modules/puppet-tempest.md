# puppet-tempest

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理tempest服务？](#核心代码讲解)
    - [class tempest](#class tempest)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

Tempest是Openstack的集成测试框架，它的实现基于python的unittest2测试框架和nose测试框架。Tempest通过Openstack client发起API请求，并且对API响应结果进行验证。

## 先睹为快

我们借助puppet-openstack_integration模块的tempest.pp来完成tempest的部署：
```shell
puppet apply -e 'include openstack_integration::tempest'
```
很快我们就能完成对tempest的部署工作。

## 核心代码讲解

### class tempest

在tempest类中，和其他module不同的一点是关于如何使用源码来安装软件包的技巧。

先说说`ensure_packages`，接受列表或哈希类型的package变量并进行安装。以下为使用示例：

Array类型:

```puppet
    ensure_packages(['ksh','openssl'], {'ensure' => 'present'})
```

Hash类型:

```puppet
    ensure_packages({'ksh' => { enure => '20120801-1' } ,  'mypackage' => { source => '/tmp/myrpm-1.0.0.x86_64.rpm', provider => "rpm" }}, {'ensure' => 'present'})
```


