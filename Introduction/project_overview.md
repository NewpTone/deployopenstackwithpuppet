# PuppetOpenstack项目简介

`PuppetOpenstack`项目是由PuppetLabs公司于2013年发起的开源项目，最初托管在Github上，半年后移入OpenStack CI体系。

PuppetOpenstack最初只有Keystone,Nova,Glance,Cinder等几个核心项目的modules，随后得到了Red Hat,Cisco,Mirantis等公司的广泛支持，在社区贡献者的持续努力下，PuppetOpenstack项目从Stackforge孵化项目演变成了OpenStack Offical项目，目前隶属于Openstack Goverance项目。目前已构成了了一套庞大而复杂的部署体系。

你可以通过以下链接找到有关PuppetOpenstack项目的更多细节说明：

 -  Wiki（Out of date）: https://wiki.openstack.org/wiki/Puppet
 -  Docs: http://docs.openstack.org/developer/puppet-openstack-guide/


## 为什么选择PuppetOpenstack

PuppetOpenstack社区对与其目标的定义如下：

> to bring scalable and reliable IT automation to OpenStack cloud deployments.


目前用于部署OpenStack的工具已非常广泛，为什么要选择它呢？或者说从技术角度来看，OpenStack自动化部署工具应该如何做技术选型？


笔者认为有以下三点：

第一，PuppetOpenstack项目诞生于2013年，诞生时间早，参与贡献者众多，使得PuppetOpenstack项目非常成熟和稳定，这对于自动化运维来说是十分重要的考虑因素。

其次，2016年4月出炉的Openstack User Survey (https://www.openstack.org/user-survey/survey-2016-q1/landing)

下图选自该份报告，统计了关于主流部署工具种类和占有率的使用统计：

![](../images/01/puppet.png)

值得一提的是，图中Fuel和Packstack项目的核心部署功能直接使用的是PuppetOpenstack项目。因此，可以理解为有近乎一半的用户选择使用PuppetOpenstack部署Openstack，这对于百花齐放的开源世界来说，是非常可观而且有说服力的数字。

第三，欧洲原子能机构CERN使用Puppet管理着世界上规模最为庞大的OpenStack集群，总计超过了一万台服务器。这从用户角度证明了PuppetOpenstack可以支持大规模Openstack集群的部署。



## OpenStack modules

现在我们先站在最高的山峰上，来看看这些伟岸的群山吧。

第一个印入我们眼帘的是Openstack服务相关的modules，目前puppetopenstack已经支持以下服务的配置和管理：

* [Alarming](https://github.com/openstack/puppet-aodh/) (Aodh)
* Key Manager (Barbican)
* Telemetry (Ceilometer)
* Block Storage (Cinder)
* DNS (Designate)
* Image service (Glance)
* Time Series Database (Gnocchi)  
* Orchestration (Heat)
* Dashboard (Horizon)
* Bare Metal (Ironic)
* Identity (Keystone)
* Shared Filesystems (Manila)   
* Workflow service (Mistral)
* Application catalog (Murano)
* Networking (Neutron)
* Compute (Nova)
* Load Balancer (Octavia)
* Oslo libraries (Oslo)
* Benchmarking (Rally)   
* Data processing (Sahara)
* Object Storage (Swift)
* Testing (Tempest)    
* Deployment (TripleO)
* Database service (Trove)  
* Deployment UI (TripleO UI)
* Root Cause Analysis (Vitrage)
* Message service (Zaqar)


## Tool modules

第二大山脉是工具类相关的modules，分别有：

* Common Puppet library (OpenStackLib)
* Common Ruby helper library (puppet-openstack_spec_helper)
* Puppet OpenStack helpers (OpenStackExtras)
* Virtual Bridging (OpenvSwitch)
* Integration CI tools (Puppet OpenStack Integration)
* Blueprints (Puppet OpenStack Specs) (hosted here)
* Compliant tool (Cookiebutter)
* Sync tool (Modulesync)


## Other modules

第三大块则是一些尚在开发阶段或者已经废弃的模块：

* Storage (Ceph) 
* Monitoring (Monasca)
* Composition Layer (deprecated in Juno) (OpenStack)


## 推荐的阅读顺序

> 说明： **本书以Ocata版本为基础**


如果你是第一次接触PuppetOpenstack，推荐从`公共库和工具类模块`章节 的`puppet-openstack-integration`一节开始，这节会介绍如何使用PuppetOpenstack模块快速部署一个All-in-One的Openstack服务。



