# puppet-rabbitmq

1. [先睹为快 - 一言不合，代码撸起?](#先睹为快)
2. [核心代码讲解 - 如何做到管理rabbitmq服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 59分钟**

rabbitmq组件是此本书中重点章节，因为它与每个openstack服务都有一腿，故学习本章前可阅读关于rabbitmq相关的基础知识和人肉的安装。
>  相关链接：http://docs.openstack.org/liberty/install-guide-rdo/environment-messaging.html

##先睹为快
在解说puppet-rabbitmq模块前，让我们来使用它部署一个rabbitmq服务先吧。

在终端下执行以下命令:

```bash
puppet apply -e "class { 'rabbitmq': }"
```

等待puppet执行完成后，在终端下试试吧：

#核心代码讲解
## class rabbitmq
此段代码主要负责参数rabbitmq服务中参数声明和一些逻辑判断，比如：它会判断参数值得类型是否符合预期、调用其它类（include）、继承params类、判断参数是否启用LADP验证，我们可以用一句话来概括它，它是一个入口类，可以调用当前模块中的所有资源。
``` puppet
class rabbitmq(
  $admin_enable               = $rabbitmq::params::admin_enable,
  $cluster_nodes              = $rabbitmq::params::cluster_nodes,
  $config                     = $rabbitmq::params::config,
  $config_cluster             = $rabbitmq::params::config_cluster,
  ...
  ...
)inherits rabbitmq::params {
  validate_bool($admin_enable)
  ...
  include '::rabbitmq::install'
  ...
  
  if ($ldap_auth) {
    rabbitmq_plugin { 'rabbitmq_auth_backend_ldap':
      ensure  => present,
      require => Class['rabbitmq::install'],
      notify  => Class['rabbitmq::service'],
    }
  }
  ...

}
```

## class rabbitmq::install
此类主要负责rabbitmq服务端的软件部署。
```puppet

  $package_ensure   = $rabbitmq::package_ensure
  $package_name     = $rabbitmq::package_name
  $package_provider = $rabbitmq::package_provider
  $package_require  = $rabbitmq::package_require
  $package_source   = $rabbitmq::real_package_source

  package { 'rabbitmq-server':
    ensure   => $package_ensure,
    name     => $package_name,
    provider => $package_provider,
    notify   => Class['rabbitmq::service'],
    require  => $package_require,
  }

  if $package_source {
    Package['rabbitmq-server'] {
      source  => $package_source,
    }
  }

  if $rabbitmq::environment_variables['MNESIA_BASE'] {
    file { $rabbitmq::environment_variables['MNESIA_BASE']:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'rabbitmq',
      mode    => '0775',
      require => Package['rabbitmq-server'],
    }
  }
}
```
## class rabbitmq::config
config类主要是负责rabbitmq服务目录、配置文件、文件内容的写入等配置
```puppet
class rabbitmq::config {

  $admin_enable               = $rabbitmq::admin_enable
  $cluster_node_type          = $rabbitmq::cluster_node_type
  $cluster_nodes              = $rabbitmq::cluster_nodes
  $config                     = $rabbitmq::config
  }
  file { '/etc/rabbitmq':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0644',
  }
  file { '/etc/rabbitmq/ssl':
    ensure => directory,
    owner  => '0',
    group  => '0',
    mode   => '0644',
  }
```

## Class rabbitmq::service
上面我们说了软件包的安装、软件包配置文件的下发，既然准备工作已经做好，那么咱们需要让这个服务启动，service 这个类就是来负责触发服务的管理。
```puppet
class rabbitmq::service(
  $service_ensure = $rabbitmq::service_ensure,
  $service_manage = $rabbitmq::service_manage,
  $service_name   = $rabbitmq::service_name,
) inherits rabbitmq {

  validate_re($service_ensure, '^(running|stopped)$')
  validate_bool($service_manage)

  if ($service_manage) {
    if $service_ensure == 'running' {
      $ensure_real = 'running'
      $enable_real = true
    } else {
      $ensure_real = 'stopped'
      $enable_real = false
    }

    service { 'rabbitmq-server':
      ensure     => $ensure_real,
      enable     => $enable_real,
      hasstatus  => true,
      hasrestart => true,
      name       => $service_name,
    }
  }

}
```
#小结
rabbitmq 模块也比较简单，需要注意是默认安装的时候有guest用户，一般情况下我们会删除此用户。
#动手练习
1.如何删除rabbitmq中guest用户？
2.如何使用自定义资源rabbitmq_user来创建用户？


