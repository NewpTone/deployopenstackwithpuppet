# 理解Hiera


## 0. Hiera是什么？

Hiera是Puppet内建的键值类型数据查询系统。Hiera默认支持的存储后端格式是YAML和JSON，当然也可以根据需要编写自定义的后端接口。

## 1. Hiera的历史和意义

在Puppet 2.x的早期版本中，在声明一个节点的角色时，与该节点相关的数据是直接与类的声明相关联。这种混合的方式，随着被管理集群数量的增加而变得复杂不堪。因此，社区提出了一个称之为Hiera的额外组件，可以将节点定义和节点数据分离开，但在2.x中，想要使用Hiera函数，则须安装额外的软件包，并且对已有的代码进行修改。从Puppet 3.x起，Hiera作为Puppet的原生功能，可以在manifests中直接使用。

通过描述比较晦涩，下面来看一个实际的例子：

假设我们在节点定义文件中声明了100台Web服务器，其中前三台Web服务器的定义如下：

```puppet

node 'web01' {
  include apache 
}

node 'web02' {
  class {'apache':
    default_vhost => false
  }
}

node 'web03' {
  class {'apache':
    default_mods => true
  }
}

```

从上述代码，可以发现每个节点都声明了`class apache`，有的使用了apache类的默认值，有的则对某些参数传递了非默认值。

如果这100台Web服务器节点定义的赋值都不相同，那么这个节点定义文件代码的行数将长达几百行，对于管理员来说则是一个梦靥。

在引入Hiera之后，我们可以看到明显的不同：

1.节点定义文件

```puppet
# 使用正则来匹配所有的web角色节点
node /^web\d+$/ {
  include apache
}
```

2.节点数据文件

web02.yaml

```yaml
---
# 变量使用类名标识的命名空间来区分
apache::default_vhost: false
```

web03.yaml
```yaml
---

apache::default_mods: true
```

在上述yaml文件中，参数`$defualt_vhost`与之对应的`apache::default_vhost`称为Hiera key，`false`是key value。

通过这种方式，可以做到将所谓的节点定义和节点数据相互分离，减少了冗余代码，提高了代码可读性，也提高了安全性。

## 2.Hiera配置文件

Hiera的配置文件称为hiera.yaml。在Hiera 4之前，hiera.yaml是全局唯一的，在Hiera 5之后，hiera.yaml则被分成了三类：全局，环境相关，模块相关。但是其目的都是一样的：定义数据的层次。

在解释层次这个概念之前，先理解在前一个Web节点例子中的Hiera配置文件是如何编写的。

以下是环境相关的hiera配置文件：

```yaml
# <ENVIRONMENT>/hiera.yaml
---
version: 5

defaults:  # Used for any hierarchy level that omits these keys.
  datadir: data  # This path is relative to the environment -- <ENVIRONMENT>/data
  data_hash: yaml_data  # Use the built-in YAML backend.

hierarchy:
  - name: "Per-node data"                   # 可读的名称
    path: "nodes/%{trusted.certname}.yaml"  # 文件路径
```


继续以Web节点为例，现在需要在Web节点中加入对NTP服务的管理：

```puppet

node /^web\d+$/ {
  include apache
  include ntp
}
```

在`class ntp`有一个参数是`$ntp_server`，需要在每一个web节点的yaml文件中添加以下参数：
```yaml
---
ntp::ntp_server: 
 - '10.0.10.101'
 - '10.0.10.102'
 - '10.0.10.103'
```
如果有100个节点，需要重复添加100次。

那么如何消除这段冗余的数据呢？还记得我们先前提到的层次（hierarchy）吗？


接下来，我们在现有的hiera.yaml添加一个新“层次”：common.yaml,用于统一管理web节点的公共数据。

```yaml
# <ENVIRONMENT>/hiera.yaml
---
version: 5

defaults:  # Used for any hierarchy level that omits these keys.
  datadir: data  # This path is relative to the environment -- <ENVIRONMENT>/data
  data_hash: yaml_data  # Use the built-in YAML backend.

hierarchy:
  - name: "Per node data"                   # 可读的名称
    path: "nodes/%{trusted.certname}.yaml"  # 文件路径
    
  - name: "Common data"
    path: "common.yaml"   
```

在common.yaml中对$ntp_server赋值:

```yaml
---
ntp::ntp_server: 
 - '10.0.10.101'
 - '10.0.10.102'
 - '10.0.10.103'
```

通过Hiera的层次设定，不同的节点通过同一套Hiera可以得到不同的数据，实现了数据的复用和分离等运维目标。

## 3.小结

Hiera是Puppet中的核心组件，也属于不易理解的部分。本节通过一些简单的示例来说明Hiera的主要功能，而Hiera还拥有其他强大的功能，推荐读者深入阅读以下官方文档：

- Hiera: How hierarchies work
- Hiera: How the three config layers work
- Hiera: Merging data from multiple sources