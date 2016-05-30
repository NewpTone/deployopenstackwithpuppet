# 模块结构

在开始接下来的各Openstack模块的介绍工作前，我们先来看看所有的Openstack module的目录结构几乎是一致的，这是在长期迭代周期中形成的统一和规范，目录结构相同带来的好处有两点：

1. 易于理解和管理
2. 减少冗余代码，提高代码复用

那么我们就来看看一个openstack服务类型的module其一层目录结构是怎么样的：

* examples/      放置示例代码   
* ext/           放置external代码，和主要代码无关，但是一些有用的脚本
* lib/           放置library代码，例如自定义facter,resource type
* manifests/     放置puppet代码
* releasenotes/  放置releasenote
* spec/          放置class,unit,acceptance测试
* tests/         已弃用，使用examples/ 替代


这里我们重点介绍manifests/目录，这里放置了最核心的部分：puppet代码，我们会介绍其中的公共部分。

| 名称 | 说明 |
| -- | -- |
| init.pp | 主类，一般仅管理公共参数（如mq参数） |
| params.pp | 用于特定操作系统的参数值设定 |
| client.pp | 客户端的配置 |
| config.pp | 未由该模块管理的参数配置 |
| policy.pp | policy设置 |
| db/ | 支持多种数据库后端的配置 |
| keystone/ | keystone endpoint,service,user,role的设置 |

