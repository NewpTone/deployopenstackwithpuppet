# puppet-apache

puppet-apache模块是由puppetlabs公司维护的官方模块，提供异常强大的apache管理能力。在开始介绍前，做一个警告：

> WARNING: Configurations not managed by Puppet will be purged.

如果你之前使用手工配置了Apache服务，想要尝试使用puppet-apache模块管理，请额外小心该模块默认情况下会清理掉所有没有被puppet管理的配置文件！


## init.pp

不想往下看，已经跃跃欲试了？
OK, let's rock!
   
在终端下输入：
   
   ```puppet apply -ve "include ::apache"```

在约1分钟内（取决于你的网速和虚拟机的性能），你就已经完成了Apache服务的安装，配置和启动了。
如何做到的呢？我们打开puppet-apache模块下manifests/init.pp文件，看看是如何做的？
这里面有比较多的判断逻辑，我们直接关注class apache调用了哪几个关键的class和define:


``` package { 'httpd':
      ensure => $package_ensure,
      name   => $apache_name,
      notify => Class['Apache::Service'],
    }```



``` class { '::apache::default_mods':
        all => $default_mods,
      }```
      
启用所有默认的mods。




   

