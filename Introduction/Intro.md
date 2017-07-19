# 概览

[0.关于本书 - 章节简介](#关于本书)  
[1.关于讲与不讲 - 取和舍的艺术](#关于讲与不讲)  
[2.关于Openstack](#关于Openstack)  
[3.关于Puppet](#关于Puppet)  
[4.关于PuppetOpenstack](#关于PuppetOpenstack)  
[5.相同和不同 - Fuel/Packstack/TripleO/Ctask和PuppetOpenstack的关联](#Fuel/Packstack/Ctask和PuppetOpenstack的区别)  
[6.为什么要学? - 不要甘于做一个只会使用工具的人](#为什么要学习PuppetOpenstack)  
 
## 关于本书

本书的主旨是为读者讲解如何借助当前流行的自动化运维工具目来完成OpenStack云平台的部署和配置工作，本书大致划分为三大部分：

* 介绍部分 包含前期的准备工作，相关约定，术语说明，项目概览，模块剖析等等基础知识给读者从全局上的认识
* 配置管理部分 本部分分为三章，分别介绍Openstack使用到的基础模块和核心服务模块以及公共库模块的介绍
* 最佳实践部分 主要介绍在实际生产环境中应注意的细节和管理规约


## 关于讲与不讲

这点很重要，笔者在撰写本书前也曾设想编写一本OpenStack运维大全，涉及到运维中的所有环节，但发现其工作量和难度远远超出了事先的预估。延期在IT领域内是一件常识，因此在做一件事情前尚若没有考虑清楚其界限和范围，那么就容易引起工程延期甚至无法完成。因此，对于本书，其主要目的是：

> 讲解如何使用自动化配置管理工具Puppet完成OpenStack

我们不会讲的是：

核心服务模块的主要class和define，重要params，使用陷阱，注意事项，使用技巧；像reference books那样事无巨细地讲解每个模块的每个class,define,custom resource,facter，每个params的说明。因为我们不是超人，你也不是机器人。


## 关于OpenStack

Openstack目前已经成为开源IaaS项目的翘楚。在去年Openstack推出BigTent战略后，在Openstack名下的项目已经多达百个。那么在面对如此复杂的架构和众多服务，我们该如何去面对？


### Fuel/Packstack/TriplO/Ctask和PuppetOpenstack的关系

- Packstack封装了PuppetOpenstack，使得用户在终端下可以通过交互式问答或者非交互式YAML格式文件的方式去部署Openstack集群，使得用户无需了解Puppet和PuppetOpenstack的细节。

- Fuel更进一步，提供了友好的Web UI界面，使得用户对于技术细节如何实现上做到了非常好的隐藏，还提供了一些健康检查工具，确保部署符合预期。

- TripleO使用Openstack的现有项目来部署Openstack，tripleo-puppet-elements组件用于生成部署Openstack的磁盘镜像文件，直接使用到了PuppetOpenstack。

- Ctask类似于Packstack，封装了PuppetOpenstack，不同点在于整合了内部开发的网络检查工具，分布式存储检查脚本，确保每步的输出符合预期，并能快速定位到问题的根源。

## 为什么要学习OpenStack自动化部署?

我们的目标读者是实施工程师，运维工程师，DevOps工程师和研发工程师，是一个不甘于只会使用工具的人，喜欢探索新的事物，喜欢去刨根问底。  
同时现有基于PuppetOpenstack封装的S工具并不能100%满足用户的需求，如果你没有手动能力的话，那你只能采用一些很low的方法，比如使用Fuel部署了一套集群，然后再手动修改配置文件，手动重启服务！一周后，一个月后，你还能记住你当时做的操作吗？之后来维护的同事，他们知道你对这套复杂的软件栈做了什么吗？  
No，在运维自动化的世界里，一切都应该自动的，不依赖于具体的人，而是依赖于稳定强大的自动化运维系统。  
如果你是一名正在或者即将要做Openstack集群部署和管理的工程师，那么这就是你应该看的书籍。

## 和电子版本有什么不同？

最初我们在Gitbook上开始了本书的编写，获得了广泛的关注和评论。但是电子版本更像是一个collection，来自于多个协作者的共同产物，在内容统一和用词上没有做到严谨精确，当时所使用的Mitaka版本已经滞后于最新稳定版本近一年。更重要的是，在这一年多的时间里，我们在新上线的OpenStack集群上做了许多新的尝试和总结。

因此，纸质版会包含更多更新令人感兴趣的内容，包括对于网络的管理，操作系统的管理，运维节点的设计等等。
