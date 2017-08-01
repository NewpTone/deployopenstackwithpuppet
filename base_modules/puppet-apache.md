# puppet-apache

1. [先睹为快](#先睹为快)
2. [代码讲解－如何管理apache服务](#代码讲解)
3. [推荐阅读](#推荐阅读) 
4. [动手练习](#动手练习)

Apache HTTP Server（简称Apache）是Apache软件基金会的一个开放源代码的网页服务器软件，可以在大多数电脑操作系统中运行，由于其跨平台和安全性被广泛使用，是最流行的Web服务器软件之一。它快速、可靠并且可通过简单的API扩充，将Perl／Python等解释器编译到服务器中。

`puppet-apache`模块是由Puppet公司维护的官方模块，提供了完善的Apache管理能力。

`puppet-apache`项目地址：https://github.com/puppetlabs/puppetlabs-apache


在开始介`puppet-apache`模块前，读者需特别留意以下：

> WARNING: Configurations not managed by Puppet will be purged.

对于已存在的Apache服务，如果尝试使用`puppet-apache`模块进行管理，请额外小心在默认情况下该模块会清除所有未被Puppet管理的配置文件！

# 1.先睹为快

不想看下面大段的代码说明，已经跃跃欲试了？

好的，我们开始吧！
   
打开虚拟机终端并输入以下命令：
   
```bash 
$ puppet apply -ve "include ::apache"
```
   
或者创建一个manifest文件test.pp，并输入以下代码：
``` puppet
class { 'apache': }
```
在终端下执行`puppet apply`命令:

   ```bash
   puppet apply -v test.pp
   ```

约1分钟之后（取决于网速和虚拟机的性能），Puppet已经完成了Apache服务的安装，配置和启动了。

这是如何做到的呢？我们打开puppet-apache模块下manifests/init.pp文件，看看是如何做的？

# 2.代码讲解

`puppet-apache`模块当前支持的主要功能如下:

- Apache配置文件和目录
- Apache软件包/服务/配置文件
- Apache的module
- 虚拟主机(Virtual hosts)
- 监听端口(Listened-to ports)


## 2.1 `class apache`

`class apache`中有大量的判断逻辑，这些并不是核心，对于一个init类，其核心是调用了哪些资源（class，define等）:

用于安装Apache软件包
``` puppeAt
    package { 'httpd':
      ensure => $package_ensure,
      name   => $apache_name,
      notify => Class['Apache::Service'],
    }
```

用于管理conf.d目录，注意这个$purge_confd参数，默认为true,会清理掉一切未被管理的配置文件。

``` puppet
  file { $confd_dir:
    ensure  => directory,
    recurse => true,
    purge   => $purge_confd,
    notify  => Class['Apache::Service'],
    require => Package['httpd'],
  }
```

用于启用所有默认的mods

``` puppet
class { '::apache::default_mods':
  all => $default_mods,
}
```

这里有两个apache::vhost define，分别用于生成默认的80端口和443端口的vhost文件。


``` puppet
   ::apache::vhost { 'default':
      ensure          => $default_vhost_ensure,
      port            => 80,
      docroot         => $docroot,
      scriptalias     => $scriptalias,
      serveradmin     => $serveradmin,
      access_log_file => $access_log_file,
      priority        => '15',
      ip              => $ip,
      logroot_mode    => $logroot_mode,
      manage_docroot  => $default_vhost,
    }
    $ssl_access_log_file = $::osfamily ? {
      'freebsd' => $access_log_file,
      default   => "ssl_${access_log_file}",
    }
    ::apache::vhost { 'default-ssl':
      ensure          => $default_ssl_vhost_ensure,
      port            => 443,
      ssl             => true,
      docroot         => $docroot,
      scriptalias     => $scriptalias,
      serveradmin     => $serveradmin,
      access_log_file => $ssl_access_log_file,
      priority        => '15',
      ip              => $ip,
      logroot_mode    => $logroot_mode,
      manage_docroot  => $default_ssl_vhost,
    }
  }
```
以上代码示例用于简单的测试验证，若在生产环境中，请关闭默认生成的vhost文件：

``` puppet
class { 'apache':
  default_vhost => false,
}
```

## 2.2 配置Apache mod

`puppet-apache`支持使用两种方式来安装mod软件包和管理mod配置文件：
  - `class apache::mod::<MODEULE_NAME>`方式
  - `define apache::mod`方式

其中`apache::mod::<MODULE NAME>`支持众多已预先定义的Apache mod的管理，而`define apache::mod`方式则可以灵活地支持未在`define apache::mod`中的mod。

## 2.2.1 `class apache::mod::ssl`

下面以`mod_ssl`为例进行说明：

为了确保通讯安全，会使用HTTPS来加密通讯，因此需在Apache启用mod_ssl。

- `class apache::mod::<MODEULE_NAME>`方式：

```puppet
#开启ssl compression
class { 'apache::mod::ssl':
  ssl_compression => true,
}
```

- `define apache::mod`方式：
```puppet
apache::mod { 'mod_ssl': }
```

在通常情况下，使用默认参数apache::mod::ssl就可以完成mod_ssl的管理工作，同时也提供了10个可配置的参数：

*  $ssl_compression         = false
*  $ssl_cryptodevice        = 'builtin'
*  $ssl_options             = [ 'StdEnvVars' ]
*  $ssl_openssl_conf_cmd    = undef
*  $ssl_cipher              = 'HIGH:MEDIUM:!aNULL:!MD5:!RC4'
*  $ssl_honorcipherorder    = 'On'
*  $ssl_protocol            = [ 'all', '-SSLv2', '-SSLv3' ]
*  $ssl_pass_phrase_dialog  = 'builtin'
*  $ssl_random_seed_bytes   = '512'
*  $ssl_sessioncachetimeout = '300'


需要注意的是，在使用`define apache::mod`方式下，Puppet仅会安装指定名称的mod软件包，用户需要手动完成对于mod配置文件的设置。

### 2.2.2 `class apache::mod::wsgi`

OpenStack服务的所有提供API接口的组件使用Python语言编写，Python原生的Web服务器性能较弱，只适合用于非线上环境。为了提高API服务的性能，需将Python Web程序运行在Apache上，将使用到`mod_wsgi`。

在通常情况下,声明`apache::mod::wsgi`时使用默认参数就可以完成`mod_wsgi`的安装和配置工作：

```puppet
class { 'apache::mod::wsgi':}
```

`apache::mod::wsgi`也提供了5个可配置的参数，其中`$wsgi_socket_prefix`有默认值：

* `$wsgi_socket_prefix` = $::apache::params::wsgi_socket_prefix
* `$wsgi_python_path`
* `$wsgi_python_home`
* `$package_name`
* `$mod_path`


## 2.3 `define apache::vhost`

在配置Apache时，最常见的操作之一就是添加和修改虚拟主机。

因此，在`puppet-apache`模块中`apache::vhost`是使用最频繁的define，用于管理Apache服务的vhost配置文件。

### 2.3.1 配置一个vhost

最简单的调用方式是在声明一个`apache::vhost`时，只对参数port和docroot传值，例如：

``` puppet
apache::vhost { 'vhost.example.com':
  port    => '80',
  docroot => '/var/www/vhost',
}
```

### 2.3.2 配置开启SSL的vhost

在线上配置vhost时，经常会使用HTTPS来确保Web访问的安全性，这在puppet中配置起来也非常容易。在声明一个`apache::vhost`时，开启$ssl参数即可：
``` puppet
apache::vhost { 'ssl.example.com':
  port    => '443',
  docroot => '/var/www/ssl',
  ssl     => true,
}
```
如果要对开启SSL的vhost指定证书路径，则在声明时引入参数`ssl_cert`和`ssl_key`：

```puppet
apache::vhost { 'cert.example.com':
  port     => '443',
  docroot  => '/var/www/cert',
  ssl      => true,
  ssl_cert => '/etc/ssl/cert.example.com.cert',
  ssl_key  => '/etc/ssl/cert.example.com.key',
}
```

### 2.3.3 配置一个WSGI的vhost

下面代码示例说明了如何为vhost配置WSGI mod，用于运行Python Web服务：

```puppet
apache::vhost { 'wsgi.example.com':
  port                        => '80',
  docroot                     => '/var/www/pythonapp',
  wsgi_application_group      => '%{GLOBAL}',
  wsgi_daemon_process         => 'wsgi',
  wsgi_daemon_process_options => {
    processes    => '4',
    threads      => '24',
    display-name => '%{GROUP}',
  },
  wsgi_import_script          => '/var/www/wsgi.example.com',
  wsgi_import_script_options  => {
    process-group     => 'wsgi',
    application-group => '%{GLOBAL}',
  },
  wsgi_process_group          => 'wsgi',
  wsgi_script_aliases         => { '/' => '/var/www/wsgi.example.com' },
}
```


## 推荐阅读

* [ServerLimit](https://httpd.apache.org/docs/current/mod/mpm_common.html#serverlimit)
* [ServerName](https://httpd.apache.org/docs/current/mod/core.html#servername)
* [ServerRoot](https://httpd.apache.org/docs/current/mod/core.html#serverroot)
* [ServerTokens](https://httpd.apache.org/docs/current/mod/core.html#servertokens)
* [ServerSignature](https://httpd.apache.org/docs/current/mod/core.html#serversignature)
* [Service attribute restart](http://docs.puppetlabs.com/references/latest/type.html#service-attribute-restart)
* [mod_wsgi](https://modwsgi.readthedocs.org/en/latest/)
* [mod_ssl](https://httpd.apache.org/docs/current/mod/mod_ssl.html)

## 动手练习

1. 使用Puppet搭建一套LAMP环境（注：需和`puppet-mysql`结合使用）
2. 使用`Certbot`和`puppet-apache`配置并管理一个HTTPS站点(注：`Certbot`的说明见https://certbot.eff.org/)
