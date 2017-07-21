# Puppet核心概念

在Puppet中有一些重要的概念，对于这些概念的理解，有助于读者快速掌握Puppet Modules的开发。

## Resource type

在Linux中，一切皆文件(`file`)。而在Puppet中，一切皆资源(`resource`)。


比如，package对应着`软件包`资源类型(resource type)。


在服务器上安装vim软件包，相应地声明一个package资源:

```puppet
package {'vim':
  ensure => present
}
```


在服务器上管理ntp服务，相应地声明一个service资源：

```puppet
service {'ntpd':
  ensure => running
}
```

在Puppet中，常用的资源类型有以下8类：

- file
- package
- service
- modify
- exec
- cron
- user
- group

## Class

