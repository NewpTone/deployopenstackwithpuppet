# puppet-cinder

cinder项目是openstack项目的核心组件，puppet-keystone 是 openstack 官方的 puppet 项目，用来部署和管理cinder组件，包括manifests to provision 比如创建keystone endpoint、初始化RPC、初始化数据库等.配置文件管理，软件包安装，和服务管理这几个部分.

*学习本章，需要阅读前面的章节包括keystone/mysql/rabbitmq三个章节，并且需要对cinder有些*了解。
puppet-cinder主要由以下几个类组成:
## init.pp
入口类，安装cinder基础包并配置cinder配置文件

## api.pp
安装和配置cinder-api服务
## scheduler.pp
安装和配置cinder-scheduler服务
## volume.pp
安装和配置cinder-volume服务
## backend and backend.pp
配置cinder-volume后端
## backup.pp
安装和配置cinder-backup服务
