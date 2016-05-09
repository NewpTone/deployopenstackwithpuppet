
# 关于本书


本书的目的是介绍如何使用自动化配置管理工具来完成Openstack系统的部署。



## 关于Openstack

Openstack目前已经成为开源IaaS项目的翘楚。在去年Openstack推出BigTent战略后，在Openstack名下的项目已经多达百个。那么在面对如此复杂的架构和众多服务，我们该如何去面对？



## 关于Puppet

Puppet是由Puppetlabs公司开发的系统管理框架和工具集，被用于IT服务的自动化管理。由于良好的声明式语言和易于扩展的框架设计以及可重用可共享的模块，使得Google、Cisco、Twitter、RedHat、New York Stock Exchange等众多公司和机构在其数据中心的自动化管理中用到了puppet。半年一度的PuppetConf大会也跻身于重要技术会议之列。AWS的CloudFormation文档中有一段关于Puppet的介绍，其开头是这么说的:

> Puppet has become the de facto industry standard for IT automation。



## 关于PuppetOpenstack

[PuppetOpenstack](https://wiki.openstack.org/wiki/Puppet)是Openstack社区推出的Puppet Modules项目，隶属于Openstack Goverance项目。引用官方对其目标的描述：

> to bring scalable and reliable IT automation to OpenStack cloud deployments.


目前部署Openstack的工具辣么多，为什么不使用Fuel，Packstack或者偏偏要选择它？
原因有两点：
第一，请看2016年4月新鲜出炉的Openstack User survey

![](../pics/01/puppet.png)

第二，Fuel和Packstack项目的部署逻辑直接使用的是PuppetOpenstack项目。所以，你可以理解为有近乎一半的公司选择使用PuppetOpenstack部署Openstack，这对于百花齐放的开源世界来说，是非常可观而且有说服力的数字。
￼