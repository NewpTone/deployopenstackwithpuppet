# puppet-horizon
0. [基础知识 - 快速了解Horizon](#基础知识)
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理horizon服务？](#核心代码讲解)
   - [class horizon](###class horizon)
   - [class horzion::wsgi::apache](###class horizon::wsgi::apache)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)


## 0.基础知识

Horizon是OpenStack Dashbaord项目，为用户提供了Web图形化的管理界面来完成一些常见的虚拟资源操作，例如创建虚拟机实例，管理网络，设置访问权限等等。下图给出了Horizon的预览页面的样例。

![](../images/03/horizon.png)

除了四大核心项目以外，Horizon还支持以下项目：

* swift
* cinder
* heat
* ceilometer
* trove
* sahara

> 注：要正常运行horizon服务，至少需安装Nova,Keystone,Glance,Neutron服务

`puppet-horizon`模块用于配置和管理horzion服务，包括Horzion软件包，配置文件和服务的管理，并且`puppet-horizon`支持将Horizon将运行在Python内置Web服务器或Apache服务器上。

## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```puppet
$ puppet apply -e 'class {'horizon': secret_key => 'big'}'
```

等待命令执行完成，Puppet完成了Horizon部署，并将其运行在Apache上。

## 2.核心代码讲解

### 2.1 class horizon

`class horizon`管理了以下三个任务:

- Horizon软件包的安装:

```puppet
  package { 'horizon':
    ensure => $package_ensure,
    name   => $::horizon::params::package_name,
    tag    => ['openstack', 'horizon-package'],
  }
```

- Horizon配置文件的管理:

```puppet
  concat { $::horizon::params::config_file:
    mode    => '0644',
    require => Package['horizon'],
  }

  concat::fragment { 'local_settings.py':
    target  => $::horizon::params::config_file,
    content => template($local_settings_template),
    order   => '50',
  }
```

这里说明一下concat管理配置文件的方式，在其他模块中也出现过这种管理配置文件的方式，而它曾经流行过一段时间。

了解过template的同学都知道，这是puppet管理配置文件的内置方式，这种方式的优缺点非常明显，其缺点就是每次配置文件发生新的变动，那么模板也得保持同步的更新。

因此，有人提出来一种新方法，将模板文件拆为分片(fragment)，把保持不变的配置项放到分片1中，把频繁更新的配置项放到分片2中，然后最后再拼接起来(concat)。这种方法简化了模板维护的成本，使得配置文件的管理变得更灵活，但本质上仍是模板。

- 管理Horizon服务的运行环境:

```puppet
  if $configure_apache {
    class { '::horizon::wsgi::apache':
      bind_address   => $bind_address,
      servername     => $servername,
      server_aliases => $final_server_aliases,
      listen_ssl     => $listen_ssl,
      ssl_redirect   => $ssl_redirect,
      horizon_cert   => $horizon_cert,
      horizon_key    => $horizon_key,
      horizon_ca     => $horizon_ca,
      extra_params   => $vhost_extra_params,
      redirect_type  => $redirect_type,
      root_url       => $root_url
    }
  }
```

这个类的代码通俗易懂，值得一提的是以下4个参数，若配合不慎可能会导致服务运行异常：

- keystone_url
- available_regions
- cache_server_ip
- secret_key

还有一点是函数member的使用，类似于Python中的`in`，用于判断指定变量是否存在于指定的数组中，第一个参数是数组变量，第二个参数是成员变量：

```puppet
 if ! (member($tuskar_ui_deployment_mode_allowed_values, $tuskar_ui_deployment_mode)) {
    fail("'${$tuskar_ui_deployment_mode}' is not correct value for tuskar_ui_deployment_mode parameter. It must be either 'scale' or 'poc'.")
  }
```

### 2.1 `class horizon::wsgi::apache`

`horizon::wsgi::apache`用于配置将horizon运行在apache上。

这里有两点值得注意，第一点是merge函数：

```puppet
  if $bind_address {
    $default_vhost_conf = merge($default_vhost_conf_no_ip, { ip => $bind_address }) #将两个或两个以上的hash变量合并成一个hash变量
  } else {
    $default_vhost_conf = $default_vhost_conf_no_ip
  }
```

第二点是函数ensure_resource:

```puppet
  ensure_resource('apache::vhost', $vhost_conf_name, merge ($default_vhost_conf, $extra_params, {
    redirectmatch_regexp => $redirect_match,
    redirectmatch_dest   => $redirect_url,
  }))
```

其等价于:

```puppet
 $merged_hash_list = merge ($default_vhost_conf, $extra_params, {
    redirectmatch_regexp => $redirect_match,
    redirectmatch_dest   => $redirect_url,
  })
 apache::vhost {"$vhost_conf_name":
    $merged_hash_list
  }))
```
使用`ensure_resource`的目的是为了使代码更简洁。

## 3.小结

本节介绍了如何使用`puppet-horizon`模块部署Horizon服务，同时也介绍了concat, merge, ensure_resource等define和function，合理使用有助于提高代码的简洁和优雅。

## 4.动手练习

1. 开启Horizon SSL端口
2. 确保Horizon服务只监听在内网IP上
3. 如何调整mod_wsgi的参数来设置Horizon运行在三种不同的MPM模式：prefork, worker, winnt
