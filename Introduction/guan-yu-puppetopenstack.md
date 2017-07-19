## 关于PuppetOpenstack


> 说明： **本书以Ocata版本为基础**

[PuppetOpenstack](https://wiki.openstack.org/wiki/Puppet)是Openstack社区推出的Puppet Modules项目，隶属于Openstack Goverance项目。引用官方对其目标的描述：

> to bring scalable and reliable IT automation to OpenStack cloud deployments.


目前用于部署OpenStack的工具已非常广泛，为什么不使用其他工具偏偏要选择它？

笔者认为有以下三点：

第一，PuppetOpenstack项目诞生于2013年

第一，2016年4月出炉的Openstack User Survey (https://www.openstack.org/user-survey/survey-2016-q1/landing)

下图选自该份报告，统计了关于当前主流部署工具的使用情况：

![](../images/01/puppet.png)

此外，图中Fuel和Packstack项目的核心部署功能直接使用了PuppetOpenstack项目。因此，可以理解为有近乎一半的用户选择使用PuppetOpenstack部署Openstack，这对于百花齐放的开源世界来说，是非常可观而且有说服力的数字。

第二，欧洲原子能机构CERN使用Puppet管理着世界上规模最为庞大的OpenStack集群，总计超过了一万台服务器。

