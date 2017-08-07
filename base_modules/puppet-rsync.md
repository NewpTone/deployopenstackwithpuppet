# `puppet-rsync`模块

1. [先睹为快](#1.先睹为快)
2. [代码讲解](#代码讲解)
3. [扩展阅读](#扩展阅读) 
4. [动手练习](#动手练习)


`Rsync`(remote sync)是一款通过网络进行数据同步的软件，由于Rsync会对需要同步的源和目的进行对比，只同步有改变的部分，所以相比常见的scp命令更加高效。

`puppet-rsync`模块由puppet官方维护的项目，用于管理rsync的客户端、服务器，命令行的配置。
`puppet-rsync`项目地址：https://github.com/puppetlabs/puppetlabs-rsync

## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```puppet
  $ puppet apply -e "class { 'rsync': }"
```

以上命令会在目标服务器上安装rsync软件包。

接下来，我们打开`puppet-sysctl`模块下`manifests/base.pp`文件来一探究竟吧。


## 2.代码讲解
### 2.1 `class rsync`

在`class rsync`中，除了`package`资源对`rsync`进行了声明以外，还有上一节提到的`create_resources`函数，分别传递了`rsync::put`和`rsync::get`参数。
```puppet
class rsync(
  $package_ensure    = 'installed',
  $manage_package    = true,
  $puts              = {},
  $gets              = {},
) {

  if $manage_package {
    package { 'rsync':
      ensure => $package_ensure,
    } -> Rsync::Get<| |>
  }

  create_resources(rsync::put, $puts)
  create_resources(rsync::get, $gets)
}
```

rsync命令行下有两种不同的执行模式：pull和push。在`puppet-rsync`模块中`define rsync::put`对应push模式，`define rsync::get`则对应pull模式。下面来看相关的两段代码示例。

```puppet
# rsync push模式
rsync::put { '${rsyncDestHost}:/repo/foo':
  user    => 'user',
  source  => "/repo/foo/",
}

#rsync pull模式
rsync::get { '/foo':
  source  => "rsync://${rsyncServer}/repo/foo/",
  require => File['/foo'],
}
```

###  2.2 `class: rsync::server`

`class rsync::server`则用于管理rsync server，`rsync`在server模式下以守护进程存在，能够接收客户端的数据请求。使用时，可以在客户端使用rsync命令把文件发送到服务器端，也可以向服务器请求获取文件。`class rsync::server`使用xinetd来管理rsync服务，使用`concat`模块来管理rsync配置文件。

```puppet
class rsync::server(
  $use_xinetd = true,
  $address    = '0.0.0.0',
  $motd_file  = 'UNSET',
  $use_chroot = 'yes',
  $uid        = 'nobody',
  $gid        = 'nobody',
  $modules    = {},
) inherits rsync {

  $conf_file = $::osfamily ? {
    'Debian' => '/etc/rsyncd.conf',
    'suse'   => '/etc/rsyncd.conf',
    'RedHat' => '/etc/rsyncd.conf',
    default  => '/etc/rsync.conf',
  }
  ...
  
  if $use_xinetd {
    include xinetd
    xinetd::service { 'rsync':
      bind        => $address,
      port        => '873',
      server      => '/usr/bin/rsync',
      server_args => "--daemon --config ${conf_file}",
      require     => Package['rsync'],
    }
  ...

  concat { $conf_file: }

  concat::fragment { 'rsyncd_conf_header':
    target  => $conf_file,
    content => template('rsync/header.erb'),
    order   => '00_header',
  }
  ...
}
```

在代码片段中，出现了`inherits`关键字，与面向对象编程中的继承概念类似，其允许某个指定类从另一个类中扩展其功能和参数。

为了让读者更易于理解，称：被继承的类为`基类`，在基类上建立的新类称为`派生类`。

在使用`inherits`关键字时，将产生以下效果：

- 当派生类被声明时，基类在此之前自动被声明
- 基类成为派生类的父作用域(parent scope)，派生类将拥有基类所有的参数和资源
- 派生类可以重写基类中任何资源的属性

在此此例中，派生类`rsync::server`继承了基类`rsync`，得到了管理rsync软件包的package资源，得到了$package_ensure等参数，若要在`rsync::server`中使用该参数，则其作用域为：`$rsync::package_ensure`。

需要注意的是，`inherits`的使用需要谨慎，尤其是多层继承时，会严重影响代码的可读性。在最佳实践中，仅推荐用于获取`class param`中的参数时使用，例如：

```puppet
class example (
  String $my_param = $example::params::myparam
) inherits example::params 
  { ... }
```

## 2.3 `define rsync::server::module`

`rsync::server::module`用于设置rsync服务实例，代码实现比较简单，以下看一段示例：`class swift::ringserver`，通过声明了`rsync::server`和`rsync::server::module`来搭建同步ring文件的rsync服务器:
```puppet
class swift::ringserver(
  $local_net_ip,
  $max_connections = 5
) {

  include ::swift::deps
  Class['swift::ringbuilder'] -> Class['swift::ringserver']

  if !defined(Class['rsync::server']) {
    class { '::rsync::server':
      use_xinetd => true,
      address    => $local_net_ip,
      use_chroot => 'no',
    }
  }

  rsync::server::module { 'swift_server':
    path            => '/etc/swift',
    lock_file       => '/var/lock/swift_server.lock',
    uid             => 'swift',
    gid             => 'swift',
    max_connections => $max_connections,
    read_only       => true,
  }
}
```
在`rsync::server::module {'swift_server'}`实例中，swift_server的路径为`/etc/swift`，所有者和所属组是`swift`，设置了默认的最大连接数，设为只读权限。


### Class rsync::repo
####创建一个存放数据的rsync仓库
```puppet
class rsync::repo {
  include rsync::server
  $base = '/data/rsync'
  file { $base:
    ensure  => directory,
  }
  # setup default rsync repository
  rsync::server::module { 'repo':
    path    => $base,
    require => File[$base],
  }
```
rsync::repo类主的作用是创建一个rsync的仓库，仓库位置默认设置在/data/rsync的目录下。


## 小结
rsync模块分为几个部分，
1、安装rsync服务 
2、配置rsync服务 
3、启动rsync服务 
4、定义rsync服务的数据库存放端
5、定义rsync如何同步远程和本地的数据

## 动手练习
1.如何指定一端IP地址可以与rsyncserver同步？
2.如何设置rsync服务的最大连接数量？