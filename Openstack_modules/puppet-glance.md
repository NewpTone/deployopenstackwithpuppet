# puppet-glance

puppet-glance 是 openstack 官方的 puppet 项目，用来部署和管理 glacne 相关的资源，包括服务，模块自身通过灵活的配置与管理openstack的glance服务。包括manifests to provision 比如创建keystone endpoint、初始化RPC、初始化数据库等.配置文件管理，软件包安装，和服务管理这几个部分.

*学习本章，需要阅读前面的章节包括keystone/mysql/rabbitmq三个章节，并且需要对glance有些*了解，并且手动安装过glance服务。

puppet-glance主要有如下几个类组成：

# class glance
进入glance服务的大门从这里开始为您打开，映入眼帘是一个叫init.pp文件，此文件为入口文件，