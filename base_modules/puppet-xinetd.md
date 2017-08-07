# `puppet-xinetd`模块

1. [先睹为快](#1.先睹为快)
2. [代码讲解](#2.代码讲解)
3. [扩展阅读](#3.扩展阅读) 
4. [动手练习](#4.动手练习)


xinetd是一个运行于类Unix操作系统的开放源代码的超级服务器（Super-server）守护进程。 它的功能是管理网络相关的服务。 xinetd提供类似于inetd+tcp_wrapper的功能，由于其较高的安全性，xinetd开始逐渐取代inetd。 xinetd监听来自网络的请求，从而启动相应的服务。

`puppetlabs-xinetd`模块是由puppet官方维护的项目，用于管理xinetd服务。
`puppetlabs-xinetd`项目地址：https://github.com/puppetlabs/puppetlabs-xinetd



## 1.先睹为快

不想看下面大段的代码说明，已经跃跃欲试了？

Ok，我们开始吧！
   
打开虚拟机终端并输入以下命令：


```bash
$  puppet apply -e "include ::xinetd"
```

命令执行完成后，Puppet完成了对xinetd安装和配置，并启动了xinetd进程。

## 2.代码讲解

### 2.1 `class xinetd`

`class xinetd`用于完成对xinetd的软件包的安装、配置文件的生成、服务的管理，代码比较简单，这里不再赘述。其中值得一提的是，在代码块的首段是关于文件的资源声明语句，其首字母大写的`File`，这与通常的`file`资源有何区别？
```puppet
  File {
    owner   => 'root',
    group   => '0',
    notify  => Service[$service_name],
    require => Package[$package_name],
  }
```
这种以资源类型的首字母大写开头并且没有title的声明方式称为资源默认属性声明（Resource default statements），通过这种方式可以声明指定资源的默认属性。

在以上代码中，`class xinetd`下所有的文件资源的默认属性被设置为:
- 所有者为root
- 所属组为0(即root)
- 文件发生变化将通知xinetd服务重启
- 文件被管理前，需安装xinetd软件包

所以在`class xinted`出现的其他`file`资源的相关属性将以上默认值，例如:

```puppet
  file { $conffile:
    ensure => file,
    mode => '0644',
    content => template('xinetd/xinetd.conf.erb'),
  }
  # 等价于：
  file { $conffile:
    ensure  => file,
    mode    => '0644',
    content => template('xinetd/xinetd.conf.erb'),
    owner => 'root',
    group => '0',
    notify => Service[$service_name],
    require => Package[$package_name],
  }
```
那么通过资源默认属性声明的方式，可以带来两点好处：
  - 确保了相同资源默认属性的一致性
  - 提高了代码复用

需要注意的是，资源默认属性声明的作用范围很大，如果你在某个类中使用了它，那么可能会对其他类或者定义产生影响，

因此，最佳实践是：只在`site.pp`中使用资源默认属性声明。

### 2.2 define xinetd::service 

回顾一下，在上一节`puppet-rsync`模块中，类`rsync::server`声明了`xinetd::service`定义，用于创建某个rsync服务的xinetd的配置文件：

```puppet
    xinetd::service { 'rsync':
      bind        => $address,
      port        => '873',
      server      => '/usr/bin/rsync',
      server_args => "--daemon --config ${conf_file}",
      require     => Package['rsync'],
    }
```
以上代码在xinetd中创建rsync服务的配置，指定了：

 - 服务的监听地址
 - 服务的运行端口
 - 服务的运行命令
 - 服务运行命令的参数
 - 服务运行的依赖

## 扩展阅读

- 资源默认属性声明 https://docs.puppet.com/puppet/4.10/lang_defaults.html

## 动手练习

1. nagios是流行的开源监控项目，请使用Puppet部署nagios服务，并且通过xinted来管理nagios进程。

参考链接：https://github.com/example42/puppet-nagios