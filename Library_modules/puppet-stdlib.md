# puppet-stdlib

1. [先睹为快](#先睹为快)
2. [核心资源讲解](#核心资源讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

## 先睹为快
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

## 核心资源讲解

在这个模块中，它提供了以下Puppet资源：

 * Stages
 * Facts
 * Functions
 * Defined resource types
 * Types
 * Providers

接下来，我们将挑选一些使用频率较高的资源进行讲解。


### Run Stages

我们知道为了保证resources间的执行顺序，可以使用`require`,`subscribe`,`notify`等元参数或者使用链式标记来指定resources间的执行顺序。例如：
```puppet
   package {'ntp':
     ensure => present
   }
   # ntp.conf的配置依赖于ntp软件包的安装
   file {'/etc/ntp.conf':
     ensure  => present,
     require => Package['ntp']
   }
   # ntpd进程的运行依赖于ntp软件包和配置文件
   service {'ntpd':
     ensure    => running,
     subscribe => Package['ntp'],File['/etc/ntp.conf']
   }
```
但是在`class`和`class`之间就没法使用这些方法去标记类之间的执行顺序了。那么`Run stages`允许将指定分组的类按照不同的stage来顺序执行。

#### `main` stage
在Puppet中，默认只有一个stage（`main`）。所有的资源都被默认自动地关联到这个stage上，如果你不显式地为Resources指定stage，那么所有的资源都会在`main stage·阶段允许。

#### 使用定制stage

  使用定制stage和其他资源的调用方式完全相同，除了有一点硬性要求是：
  
> Each additional stage must have an order relationship with another stage

例如，我们可以使用以下方式进行声明：
``` puppet
# 通过元参数的方式
stage { 'first':
  before => Stage['main'],
}
# 通过链式箭头的方式
stage { 'last': }
Stage['main'] -> Stage['last']
```
接下来，我们只需要将stage关联到class：
```puppet
  # stage作为元参数出现
class { 'ntp':
  stage => first,
}
```

#### 使用stdlib::stages
  终于讲到了正题了：`stdlib::stages`类声明了各种run stages用于基础设施，语言运行时和应用的部署。它提供了以下stages：
  
  * setup
  * main
  * runtime
  * setup_infra
  * deploy_infra
  * setup_app
  * deploy_app
  * deploy

使用起来也很简单，不用先声明，直接使用即可：以下为代码示例：
```puppet
  node default {
    include stdlib
    class { java: stage => 'runtime' }
  }
```

### `file_line` type
配置文件的管理是CMS中最主要的目标之一。对于`INI`格式的配置文件的管理方式有多种不同的配置方式。但是对于一些非格式化的配置文件来说，其配置管理通常都是选择使用`template`的方式进行管理。

`file_line` type的出现，使得我们有了一种更轻量的方式去管理非格式化配置文件。它的实现与正则匹配和替换类似。

我们来看看实际的使用吧：
```puppet
# 在/etc/sudoers文件中确保`%sudo ALL=(ALL) ALL`被正确添加
file_line { 'sudo_rule':
  path => '/etc/sudoers',
  line => '%sudo ALL=(ALL) ALL',
}
```

