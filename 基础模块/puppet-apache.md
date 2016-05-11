# puppet-apache

[Module description](#module-description)

puppet-apache模块是由puppetlabs公司维护的官方模块，提供异常强大的apache管理能力。

**puppet-apache module的管理范围:**

- Apache配置文件和目录
- Apache的Package/service/conf
- Apache modules
- Virtual hosts
- Listened-to ports

在开始介绍代码前，给出一个重要的警告：

> WARNING: Configurations not managed by Puppet will be purged.

如果你之前使用手工配置了Apache服务，想要尝试使用puppet-apache模块管理，请额外小心该模块默认情况下会清理掉所有没有被puppet管理的配置文件！

我们主要以Openstack服务中使用到的类进行介绍。

1. [Module description - What is the apache module, and what does it do?](id:Module description)


## class apache

不想往下看，已经跃跃欲试了？
OK, let's rock!
   
在终端下输入：
   
   ```puppet apply -ve "include ::apache"```
   
或者创建并编辑一个文件test.pp，并输入：
``` puppet
class { 'apache': }
```
在终端下输入:

   ```puppet apply -v test.pp```

在约1分钟内（取决于你的网速和虚拟机的性能），你就已经完成了Apache服务的安装，配置和启动了。
如何做到的呢？我们打开puppet-apache模块下manifests/init.pp文件，看看是如何做的？
这里面有比较多的判断逻辑，我们直接关注class apache调用了哪几个关键的class和define:

---

``` puppet
    package { 'httpd':
      ensure => $package_ensure,
      name   => $apache_name,
      notify => Class['Apache::Service'],
    }
```
用于安装apache软件包。

---


``` puppet
  file { $confd_dir:
    ensure  => directory,
    recurse => true,
    purge   => $purge_confd,
    notify  => Class['Apache::Service'],
    require => Package['httpd'],
  }
```

用于管理conf.d目录，注意这个$purge_confd参数，默认为true,会清理掉一切未被管理的配置文件。

---

``` puppet
class { '::apache::default_mods':
  all => $default_mods,
}
```
      
用于启用所有默认的mods。

---

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
这里有两个apache::vhost define，分别用于生成默认的80端口和443端口的vhost文件。

以上例子仅用于简单的测试验证，若在生产环境中，请关闭默认生成的vhost文件：

``` puppet
class { 'apache':
  default_vhost => false,
}
```

## define apache::mod

用来安装相应mod软件包和管理mod配置文件。需要配合apache::mod:xxx使用。

## class apache::mod::wsgi

apache::mod下有大量的class用于支持各种类型mod的管理。Openstack服务是使用Python语言编写，因此要将Python程序运行在Apache上，那么需要使用到wsgi mod。
在通常情况下,使用默认参数apache::mod::wsgi就可以完成wsgi mod的管理工作，同时也提供了5个可配置的参数，其中wsgi_socket_prefix有默认值，分别是：

* $wsgi_socket_prefix = $::apache::params::wsgi_socket_prefix
* $wsgi_python_path
* $wsgi_python_home
* $package_name
* $mod_path

## class apache::mod::ssl

此外，为了确保通讯安全，用户会要求使用HTTPS来加密通讯，因此我们需要使用到ssl mod。
同上，在通常情况下，使用默认参数apache::mod::ssl就可以完成ssl mod的管理工作，同时也提供了10个可配置的参数，并附有默认值：

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

## define apache::vhost

这个apache模块中是使用最频繁的define，通常使用它来管理Apache的vhost配置文件。

### 配置一个vhost

最简单的方式是传递port和docroot两个参数，例如：

``` puppet
apache::vhost { 'vhost.example.com':
  port    => '80',
  docroot => '/var/www/vhost',
}
```

### 配置开启SSL的vhost

``` puppet
apache::vhost { 'ssl.example.com':
  port    => '443',
  docroot => '/var/www/ssl',
  ssl     => true,
}
```

## 相关文档

* [ServerLimit](https://httpd.apache.org/docs/current/mod/mpm_common.html#serverlimit)
* [ServerName](https://httpd.apache.org/docs/current/mod/core.html#servername)
* [ServerRoot](https://httpd.apache.org/docs/current/mod/core.html#serverroot)
* [ServerTokens](https://httpd.apache.org/docs/current/mod/core.html#servertokens)
* [ServerSignature](https://httpd.apache.org/docs/current/mod/core.html#serversignature)
* [Service attribute restart](http://docs.puppetlabs.com/references/latest/type.html#service-attribute-restart)
* [mod_wsgi](https://modwsgi.readthedocs.org/en/latest/)
* [mod_ssl](https://httpd.apache.org/docs/current/mod/mod_ssl.html)