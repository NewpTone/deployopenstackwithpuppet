# 转发层模块

转发层（composition layer）模块实际上是对第二部分所介绍的模块的调用。
官方社区曾经有一个转发层模块称为puppet-openstack，在Juno版本时被标记为弃用。
为什么社区不推荐转发层模块呢？因为这玩意和自家业务结合得非常紧密。比如，Fuel有自己的转发层模块[cluster](https://github.com/openstack/fuel-library/tree/master/deployment/puppet/cluster),ctask有自己的转发层sunfire。

那么关于它的最佳实践是什么？

2016年1月份，我们刚完成了对转发层sunfire的重构，甩掉了许多的历史包袱。关于转发层，我们有以下几点特别需要指出:


## 逻辑清晰

概括来讲就是在转发层中，不允许出现对resource的直接调用，所有转发层的类抑或定义，只能直接调用基础模块，Openstack模块中的类或定义。

打个不是非常恰当的比方:
```puppet
class sunfire::api(){
  # 这块代码就应该被移除，使用include ::nova::client来替换
  package {'python-novaclient':
    ensure => present,
  }
  include ::nova
  include ::nova::api
}
```
## 数据和逻辑分离
