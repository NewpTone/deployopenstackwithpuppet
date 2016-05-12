# OpenStack modules

PuppetOpenstack模块发展到今天，其代码可以称得上是学习Puppet的经典素材。它体现在以下几点：

* 严格遵守Puppet Code Style
* 完全松耦合的逻辑
* 几乎没有代码冗余，非常高的代码复用率
* 精心设计的自定义resource type和facter，在灵活性和控制能力上做出了良好的权衡


第一期我们将介绍以下Openstack modules：

* Telemetry (Ceilometer)  @liangliang
* Block Storage (Cinder)  @weiyu
* Image service (Glance)  @luyuan
* Time Series Database (Gnocchi)  
* Dashboard (Horizon)   @xingchao  已完成
* Identity (Keystone)   @xingchao  已完成
* Application catalog (Murano)
* Networking (Neutron)  @penghui
* Compute (Nova)    @penghui
* Oslo libraries (Oslo)   @xingchao  已完成
* Object Storage (Swift)   @luyuan
* Testing (Tempest)    