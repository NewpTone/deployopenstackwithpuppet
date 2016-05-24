# puppet-xinetd
1. [看啥看 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理xineted服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 30分钟**
## 看啥看
puppet-xinetd 由puppetlabs开发，此模块可管理xinetd(超级进程管理器....)。咱们还是用一句话来了解这货儿。xinetd即extended internet daemon，xinetd是新一代的网络守护进程服务程序，又叫超级Internet服务器。经常用来管理多种轻量级Internet服务。xinetd提供类似于inetd+tcp_wrapper的功能，但是更加强大和安全。那么我来撸起你袖子来搞：

> 学习代码前，需要读者先了解本章的服务是如何手动安装和它到底是什么鬼？然后再继续阅读puppet代码。

```puppet
  puppet apply -e "class { 'xinetd': }"
```


## 核心代码讲解
###Class xinetd
此类中主要包含了，对xinetd的软件包的安装、配置文件的生成、服务的管理
```puppet
  package { $package_name:
    ensure => $package_ensure,
    before => Service[$service_name],
  }
  file { $conffile:
    ensure  => file,
    mode    => '0644',
    content => template('xinetd/xinetd.conf.erb'),
  }
  service { $service_name:
    ensure     => running,
    enable     => true,
    hasrestart => $service_hasrestart,
    hasstatus  => $service_hasstatus,
    restart    => $service_restart,
    status     => $service_status,
    require    => File[$conffile],
}
```

###define xinetd::service 
####服务管理
咱们在基础章节介绍过define，咱们的代码通过调用 define xinetd::service类，来创建某个服务的xinetd配置的配置文件，实例如下：
> Requires:
> $server must be set
> $port must be set
```puppet
xinetd::service { 'tftp':
  port        => '69',
  server      => '/usr/sbin/in.tftpd',
  server_args => '-s $base',
  socket_type => 'dgram',
  protocol    => 'udp',
  cps         => '100 2',
  flags       => 'IPv4',
  per_source  => '11',
  nice        => 19,
  }
```




## 小结

## 动手练习