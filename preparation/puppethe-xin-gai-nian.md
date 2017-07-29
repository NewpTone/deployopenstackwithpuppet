# Puppet核心概念

本书的重点是讲解PuppetOpenstack项目，并假定读者对于Puppet有一定的了解，因此将不会包含对于Puppet基础知识的讲解。

然而，在Puppet中有一些非常重要的概念，对于这些核心概念的准确理解，将有助于读者快速掌握Puppet Modules的开发，因此，本节将花费一些篇幅来帮助读者深入理解这些核心概念。

## 0.Resource Type

在Linux中，一切皆文件(`file`)。而在Puppet中，一切皆资源(`resource`)。


比如，package对应着`软件包`资源类型(resource type)。


在服务器上安装vim软件包，相应地声明一个package资源:

```puppet
package {'vim':
  ensure => present
}
```


在服务器上管理ntp服务，相应地声明一个service资源：

```puppet
service {'ntpd':
  ensure => running
}
```

在Puppet中，常用的资源类型有以下8类：

- file
- package
- service
- modify
- exec
- cron
- user
- group

### 0.1 资源声明

资源声明（Resource declaration）则是一个表达式，用于描述资源的期望状态并将其添加到Catalog。

可以理解为类似于编程语言中的函数调用。

## 1.Class

与面向对象语言不同，类(Class)在Puppet中只是表示了一个代码块：通常将一些相关的功能组合到一起，并存储到module中，以便后期使用。


### 1.1 类的定义

定义一个Class的语法格式如下：
  - 以`class`关键字开头
  - 指定一个类的名称
  - 参数列表（可选）
  - 一对花括号
  - 至少含有一个资源声明的代码块

例如，以下是一个关于apache的Class：

```puppet
class apache (String $version = 'latest') {
  package {'httpd':
    ensure => $version, # Using the class parameter from above
    before => File['/etc/httpd.conf'],
  }
  file {'/etc/httpd.conf':
    ensure  => file,
    owner   => 'httpd',
    content => template('apache/httpd.conf.erb'), # Template from a module
  }
  service {'httpd':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/httpd.conf'],
  }
}
```

### 1.2 Class文件的存放位置

Class定义文件应存放在modules的manifests目录下，Puppet将自动地加载该路径下的所有类。

### 1.3 类的声明

在Puppet manifest文件中声明一个Class时，则会将其添加到catalog文件。通常在节点定义文件中或者其他class文件中去声明一个Class。

在Puppet中，有两种方式来声明一个Class：

 - 类Include方式
 - 类Resource声明方式 
 
#### 1.3.1 Include方式

Include方式是指使用`include`，`require`，`contain`，`hiera_include`函数来声明Class，使用这种方式Class可以安全地被多次声明。


例如：

```puppet
class compute(){
  include ::nova
  include ::nova::api
}

node 'compute_node' {
  include compute
  # nova类被声明了2次
  include ::nova
}
```

何谓安全地多次声明？

 > 任何一个Class在一个指定节点的定义中，只能被声明一次，否则Puppet在运行时会抛出资源重复声明的错误。这也是初学者容易犯错的地方。

而通过类include的方式可以实现尽管Class被多次声明，但最终只向catalog添加一次的效果。

但使用这种方式，则Class中的参数传值只能通过Hiera进行。


### 1.3.2 Class方式

Class的方式则要求每个被声明的Class只被声明一次。通过这种方式，在声明某个特定Class的时候，可以对指定参数进行重新赋值。

例如：

```puppet
class compute($ip='127.0.0.1'){
  class {'nova':
    ipaddress => $ip
  }
  class {'nova::api':}
}

node 'compute_node' {
  class{'compute':
    ip => '192.168.1.1'
  }
}
```

### 2.Defines


Defines也称为是Defined resource type，是一段可以被多次赋值的代码块，可以理解为是一种轻量级的自定义的资源类型。

例如，以下是nova::manage:network define，用于管理nova network的创建。在实际使用中，可以通过传递不同的参数给nova::manage::network来创建不同的nova network。

```puppet
define nova::manage::network (
  $network,
  $label         = 'novanetwork',
  $num_networks  = 1,
  $network_size  = 255,
  $vlan_start    = undef,
  $project       = undef,
  $allowed_start = undef,
  $allowed_end   = undef,
  $dns1          = undef,
  $dns2          = undef
) {

  include ::nova::deps

  nova_network { $name:
    ensure        => present,
    network       => $network,
    label         => $label,
    num_networks  => $num_networks,
    network_size  => $network_size,
    project       => $project,
    vlan_start    => $vlan_start,
    allowed_start => $allowed_start,
    allowed_end   => $allowed_end,
    dns1          => $dns1,
    dns2          => $dns2,
  }

}
```

初学者在选择如何define和class时，常常犹豫不决。

首先，来看这两种类型的最大区别：

 - Define：在一个catalog中可以被重复声明
 - Class： 在一个catatlog中只能被声明一次

再谈使用场景：
 - Class通常用于管理具有唯一性的资源
 - Define通常用于管理具有多样性的资源
 
 以Apache为例，会使用Class来管理Apache软件包，主配置文件，以及服务状态的管理；而Apache vhost则会使用Define来管理。我们会在后面`puppet-apache`章节中详细讲解。
 
 
 # 3. Nodes
 
假设你已经下载了puppet-apache和puppet-mysql模块，接下来要为指定服务器赋予指定的角色，那么这个过程称为是节点分类（Node Classification）。
在Puppet中，这些数据通常存储在节点定义文件中。

节点定义文件的存放路径通常位于`<ENVIRONMENTS DIRECTORY>/<ENVIRONMENT>/manifests/site.pp`。

现在我们要配置2种类型的节点：Web服务器`www.example.com`和DB服务器`db1.example.com`，在site.pp中加入以下代码：

```puppet
node 'www.example.com' {
  include apache
}
node 'db.example.com' {
  include mysql
}
```

*最佳实践*

尽管在节点定义文件里可以添加任何的Puppet代码，但请保持只在节点定义文件中做两件事情：声明类和设置变量。

