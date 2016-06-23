# puppet-stdlib

## 简介
`puppet-stdlib`是由Puppet官方提供的标准库模块。这是一个聚宝盆，几乎在前面介绍的Openstack模块中都会使用到它。因为DSL作为一个不完整的语言（不是男人），缺少某些内置魔法和特性会让程序员们抓狂。
例如，在Python中借助内置库可以轻松地做数值比较：
```python
max(1,2,3)
```
那么在原生Puppet中，你只能望而兴叹。因此我们需要——puppet-stdlib模块！
```puppet
# 和Python不同的是,max函数须在语句中使用。
$largest=max(1,2,3)
notify {"$largest":}
```
那么在这个模块中，它提供大量的Puppet资源：

 * Stages
 * Facts
 * Functions
 * Defined resource types
 * Types
 * Providers