# Openstack自动化部署最佳实践

**本章完成度:`30%`**

> Fools ignore complexity. Pragmatists suffer it. Some can avoid it. Geniuses remove it.  
>   &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;                  — Alan J. Perlis, “Epigrams in Programming”


我们在一一介绍了众多基础模块，Openstack模块以及公共库模块后，是否就可以抡起袖子开始做大规模线上部署了?  
答案是No。

哎，有话好好说，你们别丢臭鸡蛋啊...  
读者：%#@($#@!，你骗我读了那么长的文档，竟然不能用于线上部署！

部署是一项复杂的系统工程，前期的架构设计，硬件规划和兼容性和性能测试，采购，上架，裸机操作系统安装，网络配置，这些都完成了，才到了软件部署阶段。
熟悉本书介绍的Puppet modules，加上对于Puppet的基础使用，的确是可以胜任Openstack集群的部署和配置管理了。
但是我们想把积累了5年的Openstack部署经验和4年的Puppet管理线上集群各种经验和教训归纳成最佳实践告诉给读者，以避免不合理的设计，为后期的运维管理埋下不稳定因素。

## 本章内容

我们将其归纳为以下几大块。

1.代码管理相关：

> 代码规范的程度体现了一个程序员的素质，映射出一家公司对待技术的态度。

那么代码规范体现在以下几点：

   - 使用版本控制工具进行管理
   - 符合一门语言的通用代码风格要求
   - 完整的文档，包含commit消息，代码注释，架构文档等
   - 不使用花式技巧

2.配置管理相关:

 - Hiera
 - Node Definition
 - Environment
 - PuppetDB

3.任务编排相关:

 - ClusterShell
 - Ansible

4.运维原则相关:

 - 配置管理操作的基本守则
