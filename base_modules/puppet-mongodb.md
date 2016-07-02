# puppetlabs-mongodb
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理mongodb服务？](#核心代码讲解)
    - [class mongodb](##class mongodb)
    - [class mongodb::server](##class mongodb::server)
    - [class mongodb::client](##class mongodb::client)
    - [class mongodb::db](##class mongodb::db)
    - [class mongodb::globals](##class mongodb::globals)
    - [class mongodb::mongos](##class mongodb::mongos)
    - [class mongodb::repo](##class mongodb::repo)
    - [class mongodb::replset](##class mongodb::replset)
[小结](#小结) 
4. [动手练习](#动手练习)

**本节作者：韩亮亮**    

**建议阅读时间 1h**

puppetlabs-mongodb模块是由puppetlabs管理的，用于配置mongodb服务。

**puppetlabs-mongodb module的管理范围:**

- 配置mongodb server(包括不同模式)
- 配置mongodb client
- 配置mongos
- 管理安装源


# 先睹为快
mongodb分为三种模式：StandAlone，Replication和Sharding。
StandAlone是标准单机环境，Replication是主从结构，一个Primary，多个Secondary，Sharding，share nothing的结构，每台机器只存一部分数据。mongod服务器存数据，mongos服务器负责路由读写请求，元数据存在config数据库中。
我们先来配置一个简单的mongodb服务，
在site.pp中写入下面的内容：
```
class {'::mongodb::client': } ->
class {'::mongodb::server': }
```
在终端下输入：
```
puppet apply -v “site.pp”
```
很快就已经完成了mongodb服务的安装，配置和启动，输入 mongo 就可以进入命令行界面了。
如果你想用10gen的源，需要在上面的代码前面加入以下代码：
```
class {'::mongodb::globals':
  manage_package_repo => true,
}->
```

# 核心代码讲解
## class mongodb
class mongodb基本可以不用关心，它的作用只是把传给该class的值再传给class mongodb::server而已。。。
## class mongodb::server
我们先来看一下这个class中可能会有困惑的地方，
```
anchor { 'mongodb::server::start': }->
class { 'mongodb::server::install': }->
# If $restart is true, notify the service on config changes (~>)
class { 'mongodb::server::config': }~>
class { 'mongodb::server::service': }->
anchor { 'mongodb::server::end': }
```
在引用mongodb::server::install、mongodb::server::config、mongodb::server::service三个class的时候，前后各有一个anchor，这是个什么东西？
anchor这个参数是在puppet 3.4.0版本之前使用的，用来包含一个或多个class，但是遏制class的执行时间，以上面代码为例，用anchor包含的class，一定要在mongodb::server这个class执行之后开始执行，一定要在mongodb::server这个class执行完成之前结束。
在puppet 3.4.0版本之后，有了一个新的功能contain，但是在使用contain包含多个class的时候，不能像anchor一样使用资源依赖，需要在后面自己加。如:
```
class a {
  notify { ‘a’:}
}
class b {
  notify { ‘b’:}
}
class include_class {
  contain a
  contain b
  Class[‘a’]->Class[‘b’]
}
```
至于用哪个，我想说的是，想用哪个用哪个。。。
创建mongodb server的时候可以设置是config server或者shard server，对应的参数为configsvr或shardsvr，但是只能二选其一。
同时，在mongodb::server中可以通过replset参数配置“副本集”的名称，通过replset_config或replset_members指定副本集中的成员，当然replset_members也是要转换为replset_config的。
```
$replset_config_REAL = {
 "${replset}" => {
   'ensure'   => 'present',
   'members'  => $replset_members
 }
}
```

## class mongodb::client
用于安装mongodb的客户端，class mongodb::client只是包含了mongodb::client::install，而这个class里也只是安装了个包，恩，可能是为了代码风格统一吧。
## class mongodb::db
使用class mongodb::db创建数据库时可以传入密码或者是一个hash的密码，调用方式如下
```
mongodb::db { 'testdb':
  user          => 'user1',
  password_hash => 'a15fbfca5e3a758be80ceaf42458bcd8',
}
```
同时mongodb::db里使用两个provider，mongodb_database和mongodb_user来创建相应的资源。
## class mongodb::globals
mongodb::globals提供了一个新的变量的配置方式，	mongodb模块中params里的很多参数，都可以通过从mongodb::globals这个class中获取，例子如下：
```
$service_manage = pick($mongodb::globals::mongod_service_manage, true)
```
## class mongodb::mongos
这个class和我们开始看到的mongodb::server中的很像，都是通过包含install、config、service三个class来配置mongos,在这就不多讲了。
```
anchor { 'mongodb::mongos::start': }->
class { 'mongodb::mongos::install': }->
class { 'mongodb::mongos::config': }~>
class { 'mongodb::mongos::service': }->
anchor { 'mongodb::mongos::end': }
```
## class mongodb::repo
class mongodb::repo用于配置安装源，支持Redhat和Debian两个系列的系统，也支持通过repo_location参数自己配置安装源。
## class mongodb::replset
clsss mongodb::replset用于配置副本集的，需要传入sets参数，虽然这没检查，但sets必须是hash格式。
## 相关文档

* [Sharding](https://docs.mongodb.com/manual/sharding/)
* [Replication](https://docs.mongodb.com/manual/replication/)


## 动手练习

1. 配置一个mongo集群，使用Replication模式
2. 配置一个mongo集群，使用sharding模式
