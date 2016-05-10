# puppet-apache

puppet-apache模块是由puppetlabs公司维护的官方模块，提供异常强大的apache管理能力。在开始介绍前，做一个警告：

> WARNING: Configurations not managed by Puppet will be purged.

如果你之前使用手工配置了Apache服务，想要尝试使用puppet-apache模块管理，请额外小心该模块默认情况下会清理掉所有没有被puppet管理的配置文件！

我们主要以Openstack服务中使用到的类进行介绍。


## class apache

不想往下看，已经跃跃欲试了？
OK, let's rock!
   
在终端下输入：
   
   ```puppet apply -ve "include ::apache"```

在约1分钟内（取决于你的网速和虚拟机的性能），你就已经完成了Apache服务的安装，配置和启动了。
如何做到的呢？我们打开puppet-apache模块下manifests/init.pp文件，看看是如何做的？
这里面有比较多的判断逻辑，我们直接关注class apache调用了哪几个关键的class和define:


---

```
    package { 'httpd':
      ensure => $package_ensure,
      name   => $apache_name,
      notify => Class['Apache::Service'],
    }
```
用于安装apache软件包。

---


```
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

```
class { '::apache::default_mods':
  all => $default_mods,
}
```
      
用于启用所有默认的mods。

---

```
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

## define apache::mod

用来安装相应mod软件包和管理mod配置文件。需要配合apache::mod:xxx使用。


## class apache::mod::wsgi

apache::mod下有大量的class用于支持各种类型mod的管理。Openstack服务是使用Python语言编写，因此要将Python程序运行在Apache上，那么需要使用到wsgi mod。


## class apache::mod::ssl

此外，为了确保通讯安全，用户会要求使用HTTPS来加密通讯，因此我们需要使用到ssl mod。
