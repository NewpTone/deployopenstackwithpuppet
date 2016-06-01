# puppet-sysctl

1. [先睹为快－一言不和，立马动手？](#先睹为快)
2. [核心代码讲解](＃核心代码讲解)
3. [小结](＃小结)
4. [动手练习－光看不练假把式](#动手练习)

**本节作者：周维宇**    

**建议阅读时间 30min**

在介绍这个模块前我们首先要讲下sysctl是什么,sysctl是一个在runtime检查和改变内核参数的公具，ok，废话少说，我们在实践中来学习吧

## 先睹为快
在命令行下输入
```puppet
puppet apply -e 'sysctl::value { "net.ipv4.tcp_syncookies": value => "1"}'
```
这将打开tcp_syscookieds功能来防止syn flood攻击。结下来我们看看是如何实现的吧

## 核心代码讲解

### Class sysctl::base
easy吧
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
### define sysctl::value
通过sysctl和sysctl_runtime两个type来管理参数
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
### Class sysctl::values
```puppet
class sysctl::values($args, $defaults = {}) {
  create_resources(sysctl::value, $args, $defaults)
}
```

## 小结
## 动手练习
1. 设置net.ipv4.tcp_timestamps参数为0
2. 设置net.ipv4.icmp_echo_ignore_broadcasts参数为1





