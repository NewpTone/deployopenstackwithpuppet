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

   

