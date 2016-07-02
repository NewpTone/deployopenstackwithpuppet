# 转发层编写规范

转发层（composition layer）模块实际上是对第二部分所介绍的模块的调用。
官方社区曾经有一个转发层模块称为puppet-openstack，在Juno版本时被标记为弃用。
为什么社区不推荐转发层模块呢？因为这玩意和自家业务结合得非常紧密。比如，Fuel有自己的转发层模块[cluster](https://github.com/openstack/fuel-library/tree/master/deployment/puppet/cluster),ctask有自己的转发层sunfire。

那么关于它的最佳实践是什么？

2016年1月份，我们刚完成了对转发层sunfire的重构，甩掉了许多的历史包袱。关于转发层，我们有以下几点原则需要严格遵守:


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

我们在早期使用Puppet时并没有使用到Hiera，因此转发层承载了大量参数的默认值设置。这样做的好处是，我们需要使用到的参数都赋有一个合理默认值，但是坏处是数据和逻辑没有完全分离开。
比如说，我想查询一下目前线上集群$keystone_user_password的值，可能是在转发层的代码中，也可能是记录在hieradata中。另外一个不好的地方就是代码会变得非常冗余。

打个比方:

```puppet
  class sunfire::api(
    $nova_db_password = 'nova',     #先定义一个参数
  ){
   class {'nova::db::mysql':
     db_password => $nova_db_password, #把该参数值传给真正需要赋值的参数
   }
  }
```

完全分离的写法:
```puppet
  class sunfire::api(){
   include ::nova::db::mysql
  }
```
## 角色松耦合

我们习惯把转发层中的每个class称之为角色，这样比较形象，例如:

 - sunfire::api 表示API节点
 - sunfire::mq  表示MQ节点
 - sunfire::loadbalancer::l7 表示7层负载均衡

那么API角色中，又包含了nova/cinder/neutron/glance/... api,keystone等大量的服务。同时我们又要满足某些情况下，某些服务不启用的需求。例如，某用户表示，他们不需要使用neutron server而启用nova-network。
有两种方式来满足这种要求：

- 在sunfire::api添加开关:
```puppet
  class sunfire::api(
    $enable_neutron = true,
  ){
    if $enable_neutron {
      include ::neutron::server
    }
  }
```

- 在main manifests文件中声明：
```puppet
'xxx api node' {
  include ::neutron::server
}
```