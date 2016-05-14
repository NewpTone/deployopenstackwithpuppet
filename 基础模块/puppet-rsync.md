# puppet-rsync

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理rsync服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 30分钟**
## 先睹为快
puppet-rsync 由puppetlabs开发，此模块可管理rsync的客户端、服务器，并且通过provider自定义define轻松获取远程服务器的数据。学习本模块前咱们先快刀斩乱马（rsync），在命令行执行如下命令:

```puppet
  puppet apply -e "class { 'rsync': }"
```
fine，有木有很too simple？既然这样，我们需要知道它是如何实现的。so...

## 核心代码讲解
###Class: rsync
####软件包管理
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

###Class: rsync::server
####服务管理
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
  $servicename = $::osfamily ? {
    'suse'   => 'rsyncd',
    'RedHat' => 'rsyncd',
    default  => 'rsync',
  }

  if $use_xinetd {
    include xinetd
    xinetd::service { 'rsync':
      bind        => $address,
      port        => '873',
      server      => '/usr/bin/rsync',
      server_args => "--daemon --config ${conf_file}",
      require     => Package['rsync'],
    }
  } else {
    service { $servicename:
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      subscribe  => Concat[$conf_file],
    }

    if ( $::osfamily == 'Debian' ) {
      file { '/etc/default/rsync':
        source => 'puppet:///modules/rsync/defaults',
        notify => Service['rsync'],
      }
    }
  }

  if $motd_file != 'UNSET' {
    file { '/etc/rsync-motd':
      source => 'puppet:///modules/rsync/motd',
    }
  }

  concat { $conf_file: }

  # Template uses:
  # - $use_chroot
  # - $address
  # - $motd_file
  concat::fragment { 'rsyncd_conf_header':
    target  => $conf_file,
    content => template('rsync/header.erb'),
    order   => '00_header',
  }

  create_resources(rsync::server::module, $modules)

}
```
### define rsync::server::module
####定义一个rsync服务的仓库
```puppet
$path  = '/var/testrsync',
rsync::server::module { 'repo':
  path    => $path,
  require => File[$path],
  }
```
path这里设置成一个变量,即可搭建成一个rsync的服务
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

### define rsync::put
#### 从本地服务器传输文件拷贝到远端
```puppet
$rsyncDestHost  = 192.168.1.222,
rsync::put { '${rsyncDestHost}:/repo/foo':
  user    => 'user',
  source  => "/repo/foo/",
} 
```
本实例中只需要设置一个远程服务器的地址，即可轻松同步本地目录到远程服务器的目录

### define rsync::get
#### 从远端服务器获取文件
```puppet
$rsyncServer  = 192.168.1.223
rsync::get { '/foo':
  source  => "rsync://${rsyncServer}/repo/foo/",
  require => File['/foo'],
}
```
本实例中只需要设置一个rsync服务器的地址，即可从远端服务器的目录同步到指定的本地目录。
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