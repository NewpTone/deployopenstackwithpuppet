# puppet-memcached
1. 先睹为快－一言不和，立马动手?
2. 核心代码－如何管理memcached服务
3. 小结
4. 动手练习


## 先睹为快
puppet-memcache 是由Steffen Zieger(saz)维护的一个模块，他还维护了很多其他的基础模块包括puppet-sudo,puppet-ssh等.
在解说这个模块前，我们先动手部署一个memcached吧
在命令行执行
```puppet
puppet apply -e "class { 'memcached': }"
```
ok,部署完成，赶紧来看下这是怎么实现的吧
##核心代码讲解
puppet-memcached只有一个Class
### Class memcached

####软件包管理
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
####服务管理
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
####配置文件管理
使用标准的puppet模版实现
```puppet
  if ( $memcached::params::config_file ) {
    file { $memcached::params::config_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template($memcached::params::config_tmpl),
      require => Package[$memcached::params::package_name],
      notify  => $service_notify_real,
    }
  }
  ```
  ####防火墙管理
  主要是打开memecahed监听的端口，允许外部访问
  ```puppet
    if $manage_firewall_bool == true {
    firewall { "100_tcp_${tcp_port}_for_memcached":
      dport  => $tcp_port,
      proto  => 'tcp',
      action => 'accept',
    }

    firewall { "100_udp_${udp_port}_for_memcached":
      dport  => $udp_port,
      proto  => 'udp',
      action => 'accept',
    }
  }
  ```
  ##小结
  这个模块比较简单，只有一个Class，为什么呢？因为memcached部署起来就是很简单啊。。
  ##动手练习
  1. 限制memcached最大使用内存为50%
  2. 关闭对防火墙规则的管理
