# 项目概览

`PuppetOpenstack`项目是在2013年开始由前PuppetLabs工程师Dan Bode发起，发布在github上。当时只有几个核心项目的modules，但在3年多时间里，在大量贡献者的持续努力下，现在已经发展成为一个庞大而复杂的module系统。

你可以通过以下链接找到有关PuppetOpenstack项目的更多细节说明：

 -  Wiki（Out of date）: https://wiki.openstack.org/wiki/Puppet
 -  Docs: http://docs.openstack.org/developer/puppet-openstack-guide/

现在我们先站在最高的山峰上，来看看这些伟岸的群山吧。

## OpenStack modules

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

* Storage (Ceph)  @luyuan
* Monitoring (Monasca)
* Composition Layer (deprecated in Juno) (OpenStack)


