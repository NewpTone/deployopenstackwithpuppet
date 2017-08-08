# `puppet-mongodb`模块

1. [先睹为快](#先睹为快)
2. [代码讲解](#代码讲解)
3. [推荐阅读](#推荐阅读) 
4. [动手练习](#动手练习)


MongoDB是一个基于分布式文件存储的数据库，旨在为Web应用提供可扩展的高性能数据存储解决方案。
`puppetlabs-mongodb`模块是由Puppet公司维护的官方项目，用于管理MongoDB服务，包括:

- 配置mongodb server(包括不同模式)
- 配置mongodb client
- 配置mongos
- 管理安装源

`puppet-mongodb`项目地址：https://github.com/puppetlabs/puppetlabs-mongodb

# 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
$ puppet apply -e "include mongodb::server,mongodb::client" -v
```

在看到赏心悦目的绿字后，Puppet已经完成了MongoDB服务的安装，配置和启动，输入mongo就可以进入命令行界面了。


# 2.代码讲解

### 2.1 `class mongodb`

`class mongodb`的代码比较简单，声明了`class mongodb::server`。

## 2.2 `class mongodb::server`

### 2.2.1 类包含和链式箭头
在该类中，有一段复杂的代码:

```puppet
  if ($ensure == 'present' or $ensure == true) {
    if $restart {
      anchor { 'mongodb::server::start': }
      -> class { 'mongodb::server::install': }
      # If $restart is true, notify the service on config changes (~>)
      -> class { 'mongodb::server::config': }
      ~> class { 'mongodb::server::service': }
      -> anchor { 'mongodb::server::end': }
    } else {
      anchor { 'mongodb::server::start': }
      -> class { 'mongodb::server::install': }
      # If $restart is false, config changes won't restart the service (->)
      -> class { 'mongodb::server::config': }
      -> class { 'mongodb::server::service': }
      -> anchor { 'mongodb::server::end': }
    }
  } else {
    anchor { 'mongodb::server::start': }
    -> class { '::mongodb::server::service': }
    -> class { '::mongodb::server::config': }
    -> class { '::mongodb::server::install': }
    -> anchor { 'mongodb::server::end': }
  }
```

在Puppet中,非常特别的一点是：资源和类的执行顺序并不是由上到下的。其背后是由于Puppet本身的设计机制产生了这一结果，在此我们不做展开。

而链式箭头(chain arrow)用于指定资源的执行顺序，一共有两种类型的运算符：
  - 序列箭头`->`，左侧资源的执行顺序优于右侧
  - 通告箭头`~>`，左侧资源执行后，右侧资源将会刷新

在`mongodb::server`中，若$restart为true，则执行以下代码段:

```puppet
  anchor { 'mongodb::server::start': }
  -> class { 'mongodb::server::install': }
  -> class { 'mongodb::server::config': }
  ~> class { 'mongodb::server::service': }
  -> anchor { 'mongodb::server::end': }
```

表示MongoDB配置文件的变化(`mongodb::server::config`)将触发MongoDB Server端服务的重启(`mongodb::server::service`)。

若$restart为false，则执行以下代码段:

```puppet
  anchor { 'mongodb::server::start': }
  -> class { 'mongodb::server::install': }
  -> class { 'mongodb::server::config': }
  -> class { 'mongodb::server::service': }
  -> anchor { 'mongodb::server::end': }
}
```
表示MongoDB配置文件的变更在管理MongoDB Server端服务之前。


其次，在Puppet中并无法通过include加上链式箭头声明的方式来指定类的执行顺序，或者说在类中无法通过include的方式包含(contain)一个类。

由于include和contain翻译成中文都可以理解为包含或者含有，从字面理解来看比较晦涩，我们通过举例说明。

```puppet
class first {
  notify { 'foo': }
}

class second {
  notify { 'bar': }
}

class classa {
  include first
}

class classb {
  include second
}

Class['classa'] -> Class['classb']

include classa
include classb
```

无论将两个类之间的执行顺序如何改变，其输出结果可能是"foo bar"也可能是"bar foo"。

而anchor是解决这个问题的方法之一，其格式通常如下:

```
anchor{'start':} -> class{'new_class':} -> anchor{'end':} 
```

通过这种方式使得new_class类被包含，从而可以指定类的依赖顺序。例如：

```puppet
  anchor { 'mongodb::server::start': }
  -> class { '::mongodb::server::service': }
  -> class { '::mongodb::server::config': }
  -> class { '::mongodb::server::install': }
  -> anchor { 'mongodb::server::end': }
  }
```

其执行顺序是:

  1. mongodb::server::service
  2. mongodb::server::config
  3. mongodb::server::install

在Puppet 3.4.0之前，使用`anchor`资源类型是解决类包含类的唯一方法。

在Puppet 3.4.0之后，新增了函数contain的方法来解决这个问题。但在使用contain声明多个class时，无法和anchor一样同时配合链式箭头使用，而需要单独声明。如:
```
class a {
  notify { 'a':}
}
class b {
  notify { 'b':}
}
class include_class {
  contain a
  contain b
  Class['a']->Class['b']
}
```
### 2.2.2

MongoDB分为三种模式：StandAlone，Replication和Sharding。

StandAlone是标准单机环境，Replication是主从结构，一个Primary，多个Secondary，Sharding，share nothing的结构，每台机器只存一部分数据。mongod服务器存数据，mongos服务器负责路由读写请求，元数据存在config数据库中。

创建MongoDB server时可以设置为config server或者shard server，对应的参数为configsvr或shardsvr，但是只能选择其一。

同时，在mongodb::server中可以通过replset参数来配置副本集的名称，通过replset_config或replset_members指定副本集中的成员，当然replset_members也是要转换为replset_config的。

```puppet
$replset_config_REAL = {
 "${replset}" => {
   'ensure'   => 'present',
   'members'  => $replset_members
 }
}
```

### 2.3 `class mongodb::client`

`mongodb::client`用于安装MongoDB客户端，声明了mongodb::client::install，其代码结构和mongodb::server相似。

### 2.4 `class mongodb::db`

`class mongodb::db`用于创建MongoDB数据库，创建数据库时可以传入密码或者是一个hash的密码，调用方式如下：
```
mongodb::db { 'testdb':
  user          => 'user1',
  # password_hash是'user1:mongo:pass1'的md5值
  password_hash => 'a15fbfca5e3a758be80ceaf42458bcd8',
}
```

### 2.5 `class mongodb::mongos`
mongodb::mongos用于配置Mongo Shard进程，其代码结构和mongodb::server相似，通过声明install、config、service三个class来配置mongos,在这就不再赘述。

### 2.6 `class mongodb::repo`

`class mongodb::repo`用于配置安装源，也支持通过repo_location参数自己配置安装源。

## 3.扩展阅读

* Containment https://docs.puppet.com/puppet/4.10/lang_containment.html
* What is Class containment https://puppet.com/blog/class-containment-puppet
* Relationships and orderings https://docs.puppet.com/puppet/5.0/lang_relationships.html#syntax-chaining-arrows

## 4.动手练习

1. 配置一个mongo集群，使用Replication模式
2. 配置一个mongo集群，使用sharding模式
