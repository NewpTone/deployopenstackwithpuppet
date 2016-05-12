# puppet-vswitch
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理openvswitch服务？](#核心代码讲解)
    - [class vswitch](###class vswitch)
    - [class vswitch::ovs](###class vswitch::ovs)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

## 先睹为快
puppet-vswitch是管理openvswitch的模块，部署超级简单.
编辑一个test.pp，输入以下内容：
```
class { 'vswitch':
  provider  => 'ovs',
}
```
在终端下输入:
```bash
puppet apply -v test.pp
```
Openvswitch服务就装好了（其实也就是安装一个包，启动一个服务。。。）

## 核心代码讲解
### class vswitch
class vswitch的逻辑很简单，只需要传入provider的值，然后include对应的class，目前只有vswitch::ovs一个。
```puppet
class vswitch (
  $provider = $vswitch::params::provider
) {
  $cls = "::vswitch::${provider}"
  include $cls
}
```

### class vswitch::ovs
class vswitch::ovs
看起来代码不少，大多数为兼容不同的系统版本的代码，L版的代码中支持的系统为：Debian、Redhat、FreeBSD,
在一个系统版本下对应的代码只有很少的一部分，例如，在CentOS中有用的代码为只是安装一个openvswitch的软件包，
并且启动服务。
service管理的代码如下：
```puppet
    'Redhat': {
      service { 'openvswitch':
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovs_service_name,
      }
    }
```
软件包管理代码如下，包的名称调用的params中的参数，并且指定安装软件的顺序在启动服务之前。
```puppet
  package { $::vswitch::params::ovs_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
  }
```
puppet-vswitch模块提供了vs_port和vs_bridge两个provider，如果想要创建一个名为br-ex的ovs bridge，
我们可以使用vs_bridge来创建：
```puppet
vs_bridge { 'br-ex':
  ensure => present,
}
```
而如果想要把端口绑到br-ex上，我们可以是用vs_port来实现：
```puppet
vs_port { 'eth2':
  ensure => present,
  bridge => 'br-ex',
}
```
vswitch::ovs 在最后定义了执行顺序，创建ovs bridge和绑定port，都要在启动服务之后。

### class vswitch::params
vswitch::params为别的class提供参数，在vswitch::params里根据不同的系统指定了不同的软件包、
服务等名称

## 小结
我们在本章里介绍了puppet-vswitch的核心代码，这个模块相对简单，大家可以自己练习一下，对照代码，
了解每一步是怎么实现的。

## 动手练习
1. 部署openvswitch服务
2. 创建一个bridge，名字是br-tun,并且把eth1加入到br-tun