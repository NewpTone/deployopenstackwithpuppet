# `puppet-sysctl`模块

1. [先睹为快](#先睹为快)
2. [代码讲解](#代码讲解)
3. [扩展阅读](#扩展阅读) 
4. [动手练习](#动手练习)


`sysctl`命令被用于在内核运行时动态地修改内核的运行参数，系统可用的内核参数可在目录/proc/sys中查询。它包含了一些TCP/IP堆栈和虚拟内存系统的高级选项， 这可以让系统管理员提高对操作系统的性能进行调优。

本节要谈的`puppet-sysctl`模块是由个人维护的项目，其目的是在Puppet中提供管理sysctl的接口。

`puppet-sysctl`项目地址：https://github.com/duritong/puppet-sysctl


## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```puppet
$ puppet apply -e 'sysctl::value { "net.ipv4.tcp_syncookies": value => "1"}'
```
这将开启内核中的`tcp_syscookieds`参数，常用于抵御`synflood`攻击。

我们打开`puppet-sysctl`模块下`manifests/base.pp`文件来一探究竟吧。


## 2.代码解析

### 2.1 `class sysctl::base`

`sysctl::base`是该模块仅有的一个类，其中的代码逻辑也非常简单，仅对`/etc/sysctl.conf`文件的所有者和权限进行了管理。

```puppet
class sysctl::base {
  file { '/etc/sysctl.conf':
    ensure => 'present',
    owner  => 'root',
    group  => '0',
    mode   => '0644',
  }
}
```

### 2.2 `define sysctl::value`

`define sysctl::value`用于管理`/etc/sysctl.conf`文件中的配置项。这里，有三处值得展开解析。

```puppet
define sysctl::value (
  $value,
  $key    = $name,
  $target = undef,
) {
  require sysctl::base
  $val1 = inline_template("<%= String(@value).split(/[\s\t]/).reject(&:empty?).flatten.join(\"\t\") %>")

  sysctl { $key :
    val    => $val1,
    target => $target,
    before => Sysctl_runtime[$key],
  }
  sysctl_runtime { $key:
    val => $val1,
  }
}
```
### 2.2.1 `require`函数

在`define sysctl::value`出现了`require`函数 (注意：与`require`元参数不同)，该函数可以声明一个或多个类，并与含有此函数的容器形成依赖关系。


```puppet
require sysctl::base
```
在该例中，Puppet在执行`sysctl::value`实例前，确保`class sysctl::base`的所有资源已被应用。

### 2.2.2 `inline_template`函数

在`define sysctl::value`中出现了以下一段代码：

```puppet
$val1 = inline_template("<%= String(@value).split(/[\s\t]/).reject(&:empty?).flatten.join(\"\t\") %>")
```

`inline_template`函数和`template`函数类似，可以简单地认为是只有一个字符串的模板。`inline_template`对模板求值后，生成字符串，常用于复杂的字符串拼接。

在前文中，已经提到标签```<%= %>```是插入值表达式，在该表达式中：首先对`$value`做字符串格式转换，然后以正则表达式`\s`和`\t`匹配进行字符串切割，去除空数组，对数组flatten操作，再做字符串连接。


#### 2.2.3 自定义资源类型

Puppet中有大量内置的资源类型，如`user`,`package`等等，同时用户也可以通过规范进行扩展，上述代码中的`sysctl`和`syscyl_runtime`是`puppet-sysctl`模块中自定义的资源类型，我们会在后文中详细讲解其代码结构和实现等细节。

### 2.3 `class sysctl::values`

`sysctl::values`的代码同样也非常简洁，主要是对`sysctl::value`进行了封装：
```puppet
class sysctl::values($args, $defaults = {}) {
  create_resources(sysctl::value, $args, $defaults)
}
```
### 2.3.1 `create_resources`函数

`create_resources`函数接受一个hash类型的参数，将其转换为一个资源集合并添加到catalog中。这么讲比较抽象，我们可以来看一个实际的例子。

假设，接到其他部门的需求，需要在线上开启Linux内核的IP转发功能，要在开启该功能的节点上声明两个`sysctl::value`实例。

```puppet
sysctl::value { 'net.ipv4.ip_forward':
  value => 1
}
sysctl::value { 'net.ipv6.conf.all.forwarding':
  value => 1
}
```
然而，在事前运维工程师是无法知道服务器需要开启哪些内核参数，按照第一章的`理解Hiera`一节中提到的节点数据不应该和节点数据放在一起，下面看如何借助`create_resources`函数来解决这个问题。
在节点定义文件中预先加入:
```puppet
include ::sysctl::values
```
接着在`common.yaml`Hiera文件中加入：
```yaml
---
sysctl::values:args:
 net.ipv4.ip_forward:
   value: 1
 net.ipv6.conf.all.forwarding:
   value: 1
```
现在只需要对`sysctl::values:args`参数进行改动就能实现动态地管理服务器上的所有内核参数了！


## 3.扩展阅读

 - https://docs.puppet.com/puppet/latest/function.html#createresources
 - https://docs.puppet.com/puppet/4.10/lang_template.html#with-a-template-string-inlinetemplate-and-inlineepp
 - https://docs.puppet.com/puppet/4.10/lang_classes.html#using-require

## 4.动手练习

1. 设置`net.ipv4.tcp_timestamps`参数为0
2. 设置`net.ipv4.tcp_rmem`参数为`4096` `131072` `131072`(多个值)
