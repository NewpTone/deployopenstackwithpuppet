# OpenStack模块代码结构

在开始介绍OpenStack模块前，先来观察一下所有OpenStack module的目录结构，你会发现所有的模块的代码目录结构和命名方式几乎是一致的，这是经过了长期迭代和开发中形成的规范和统一，代码结构统一带来的好处有两点：

1. 易于维护人员理解和管理
2. 减少冗余代码，提高代码复用

那么我们就来看看一个Openstack服务的Module中包含了哪些目录：

* examples/      放置示例代码   
* ext/           放置external代码，和主要代码无关，但是一些有用的脚本
* lib/           放置library代码，例如自定义facter,resource type
* manifests/     放置puppet代码
* releasenotes/  放置releasenote
* spec/          放置class,unit,acceptance测试
* tests/         已弃用，使用examples替代


以上目录中最重要的是manifests目录，该目录用于放置最核心的Puppet代码，在该目录下包含了以下通用代码文件：

| 名称 | 说明 |
| -- | -- |
| init.pp | 主类，也称为入口类，通常仅用于管理公共参数（如MQ参数） |
| params.pp | 用于特定操作系统的参数值设置 |
| client.pp | 管理客户端的配置 |
| config.pp | 用于管理自定义的参数配置 |
| policy.pp | policy设置 |
| db/ | 支持多种数据库后端的配置 |
| keystone/ | keystone endpoint,service,user,role的设置 |


