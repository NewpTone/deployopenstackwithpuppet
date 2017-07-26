# Puppet核心概念

本书的重点是讲解PuppetOpenstack项目，并假定读者对于Puppet有一定的了解，因此将不会包含对于Puppet基础知识的讲解。

然而，在Puppet中有一些非常重要的概念，对于这些核心概念的准确理解，将有助于读者快速掌握Puppet Modules的开发，因此，本节将花费一些篇幅来帮助读者深入理解这些核心概念。

## 0.Resource type

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

### 0.1 Resource declaration

资源声明则是一个表达式，用于描述资源的期望状态并将其添加到Catalog。

可以理解为类似于编程语言中的函数调用。

## 1.Class

与面向对象语言不同，类(Class)在Puppet中只是表示了一个代码块：通常将一些相关的功能组合到一起，并存储到module中，以便后期使用。


### 1.1 Class的定义

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

### 1.3 Class的声明

在Puppet manifest文件中声明一个Class时，则会将其添加到catalog文件。通常在节点定义文件中或者其他class文件中去声明一个Class。

在Puppet中，有两种方式来声明一个Class：

 - 类Include方式
 - 类Resource声明方式 
 
#### 1.3.1 类Include方式

类Include方式是指使用`include`，`require`，`contain`，`hiera_include`函数来声明Class，使用这种方式Class可以安全地被多次调用。

何谓安全地多次调用？

任何一个Class在一个指定node definition的Manifests文件中，只能被声明一次。否则会产生资源重复声明的错误，这是初学者容易犯的错误。


