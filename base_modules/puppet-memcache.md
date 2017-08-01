# `puppet-memcached`

1. [先睹为快](#1.先睹为快)
2. [代码解析](#2.代码解析)
3. [小结](#小结) 
4. [动手练习](#动手练习)


Memcached是一个高性能的分布式内存对象缓存系统，用于动态Web应用以减轻数据库负载，最初由LiveJournal的Brad Fitzpatrick开发，目前得到了广泛的使用。它通过在内存中缓存数据和对象来减少读取数据库的次数，从而提高动态、数据库驱动网站的速度。

`puppet-memcached`是由Steffen Zieger(saz)维护的一个模块。同时，他还维护了`puppet-sudo`,`puppet-ssh`等模块。

`puppet-memcached`项目地址：https://github.com/saz/puppet-memcached

## 1.先睹为快

不想看下面大段的代码说明，已经跃跃欲试了？

Ok，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
$ puppet apply -e "class { 'memcached': }"
```

在看到赏心悦目的绿字后，Puppet已经完成了Memcached服务的安装，配置和启动。这是如何做到的呢？

我们打开`puppet-memcached`模块下`manifests/init.pp`文件来一探究竟吧。


## 2.代码解析

`puppet-memcached`模块的代码结构非常简洁，所有的工作都在`Class memcached`中完成：

### 2.1 `Class memcached`

以下代码完成了对`Memcached`软件包管理：

```puppet
  package { $memcached::params::package_name:
    ensure   => $package_ensure,
    provider => $memcached::params::package_provider
  }

  if $install_dev {
    package { $memcached::params::dev_package_name:
      ensure  => $package_ensure,
      require => Package[$memcached::params::package_name]
    }
  }
```
这里可以看到在`package`资源类型中，参数`provider`并不常见，它用于配置管理软件包的后端，常见的可选项有：`yum`,`apt`,`pip`等。

下述代码完成了对`Memcached`服务的管理：

```puppet
  if $service_manage {
    service { $memcached::params::service_name:
      ensure     => $service_ensure,
      enable     => $service_enable,
      hasrestart => true,
      hasstatus  => $memcached::params::service_hasstatus,
    }
  }
```
下述代码完成了对`Memcached`配置文件管理：

```puppet
  if ( $memcached::params::config_file ) {
    file { $memcached::params::config_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template($memcached::params::config_tmpl),  #使用了模板完成对配置完成的管理
      require => Package[$memcached::params::package_name],
      notify  => $service_notify_real,
    }
  }

    ```

  
## 推荐阅读
  
  
##动手练习
  
1. 限制memcached最大使用内存为50%
2. 关闭对防火墙规则的管理
