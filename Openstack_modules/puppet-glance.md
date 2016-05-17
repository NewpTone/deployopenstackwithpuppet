# puppet-glance

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理glance服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 1小时**
## 先睹为快
学习本章前，先“触（kai）摸(you)”一下神秘模块glance软件部署资源环节，这只是冰山的一角，更多的冰山请继续阅读核心代码章节。撸起你的袖子，开始吧。

> 本示例依赖面部署的 keystone/myql/ceph/rabbitmq 4个服务


编写puppet_glance.pp

**1.Define a glance node**
```puppet
class { 'glance::api':
  verbose             => true,
  keystone_tenant     => 'services',
  keystone_user       => 'glance',
  keystone_password   => '12345',
  database_connection => 'mysql://glance:12345@127.0.0.1/glance',
}

class { 'glance::registry':
  verbose             => true,
  keystone_tenant     => 'services',
  keystone_user       => 'glance',
  keystone_password   => '12345',
  database_connection => 'mysql://glance:12345@127.0.0.1/glance',
}
class { 'glance::backend::file': }
```
**2.Setup mysql node for glance**
```puppet
class { 'glance::db::mysql':
  password      => '12345',
  allowed_hosts => '%',
}
```
**3.Setup up keystone endpoints for glance on keystone node**
```puppet
class { 'glance::keystone::auth':
  password         => '12345'
  email            => 'glance@example.com',
  public_address   => '172.17.0.3',
  admin_address    => '172.17.0.3',
  internal_address => '172.17.1.3',
  region           => 'example-west-1',
}
```
**4.Setup up notifications for multiple RabbitMQ nodes**

```puppet
class { 'glance::notify::rabbitmq':
  rabbit_password               => 'pass',
  rabbit_userid                 => 'guest',
  rabbit_hosts                  => [
    'localhost:5672', 'remotehost:5672'
  ],
  rabbit_use_ssl                => false,
}
```
在终端执行以下命令:
```puppet
puppet apply -v puppet_glance.pp
```
> 如果想让

## 核心代码讲解

## 小结

## 动手练习