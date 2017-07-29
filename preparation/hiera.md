# 理解Hiera


## 0. Hiera是什么？

Hiera是Puppet内建的键值类型数据查询系统。Hiera默认支持的存储后端格式是YAML和JSON，当然也可以根据需要编写自定义的后端接口。

## 1. Hiera的历史

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
  apache::vhost { 'www.example.com':
    port    => '80',
    docroot => '/var/www',
  }
}

```

从上述代码，可以发现，其实每个节点都包含了`class apache`，并有不同的
