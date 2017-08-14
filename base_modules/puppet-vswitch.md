# `puppet-vswitch`模块

1. [先睹为快](#1.先睹为快)
2. [代码讲解](#2.代码讲解)
4. [动手练习](#3.动手练习)


Open vSwitch(OVS)是一个高质量的、多层虚拟交换机，使用开源Apache2.0许可协议。它的目的是让大规模网络自动化可以通过编程扩展,同时仍然支持标准的管理接口和协议，Open vSwitch支持多种linux 虚拟化技术，包括Xen/XenServer， KVM和irtualBox。

`puppet-vswitch`项目是由OpenStack社区维护的模块，用于配置和管理Openvswitch。

`puppet-vswitch`项目地址: https://github.com/openstack/puppet-vswitch

在OVS中，有三个非常重要的基本概念：

- Bridge: 表示一个以太网交换机，其功能是根据流规则，把从端口收到的数据包转发到一个或多个端口
- Port: 收发数据包的单元，每个Port都属于一个特定的bridge
- Interface: 连接到Port的网络接口设备，可以是物理网卡，也可以是虚拟网卡

## 1.先睹为快

不想看下面大段的代码说明，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：
```bash
$ puppet apply -e 'class {'vswitch': provider => 'ovs'}'
```
等待命令执行完成，Puppet完成了Openvswitch安装并启动了ovs服务。

## 2.代码讲解
### 2.1 class vswitch

`class vswitch`的逻辑比较简单，使用include函数声明了"::vswitch::${provider}"。
```puppet
class vswitch (
  $provider = $vswitch::params::provider
) {
  $cls = "::vswitch::${provider}"
  include $cls
}
```

### 2.2 class vswitch::ovs
`class vswitch::ovs`用于管理Openvswitch的软件包和服务,管理服务的代码如下：
```puppet
    'Redhat': {
      service { 'openvswitch':
        ensure => true,
        enable => true,
        name   => $::vswitch::params::ovs_service_name,
      }
    }
```
管理openvswitch软件包的代码如下，指定安装软件的顺序在启动服务之前:
```puppet
  package { $::vswitch::params::ovs_package_name:
    ensure => $package_ensure,
    before => Service['openvswitch'],
  }
```

### 自定义资源类型vs_port/vs_bridge/vs_config
`puppet-vswitch`模块提供了vs_port和vs_bridge两个自定义资源类型，分别用于管理port和bridge。

例1, 使用`vs_bridge`创建一个名为br-ex的ovs bridge：
```puppet
vs_bridge { 'br-ex':
  ensure => present,
}
```
例2，使用vs_port将端口eth1绑定到br-ex上：
```puppet
vs_port { 'eth1':
  ensure => present,
  bridge => 'br-ex',
}
```
例3，使用vs_config添加新配置项到Openvswitch配置文件中：
```puppet
vs_config { 'parameter_name':
  ensure => present,
  value => "some_value"
} 
```

在`vswitch::ovs`指定了资源的执行顺序，vs_bridge和vs_port在openvswitch服务之后。

```puppet
  Service['openvswitch'] -> Vs_port<||>
  Service['openvswitch'] -> Vs_bridge<||>
```


## 3.动手练习

1. 创建一个vs bridge br-tun, 并且把eth1加入到br-tun
