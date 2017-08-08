# `puppet-firewall`模块

1. [先睹为快](#先睹为快)
2. [代码讲解](#代码讲解)
3. [推荐阅读](#推荐阅读) 
4. [动手练习](#动手练习)

iptables是一个配置Linux内核防火墙的命令行工具，通过设定一些特殊的规则，以允许或拒绝数据包通过。

`puppet-firewall`模块是由Puppet公司维护的官方模块, 用于管理防火墙和其规则。该模块通过扩展自定义资源类型来管理firewall规则和
iptables chains, 当前支持iptables和ip6tables。

`puppet-firewall`项目地址：'https://github.com/puppetlabs/puppetlabs-firewall'

## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

先别激动，这个模块的使用是有风险的，操作不慎会把自己也拒之门外，请确保可以通过除ssh外的方式登陆。

创建learn_firewall.pp文件并编辑:

```puppet
  class my_fw::pre {
    Firewall {
      require => undef,
    }
  
    # Default firewall rules
    firewall { '000 accept all icmp':
      proto  => 'icmp',
      action => 'accept',
    }->
    firewall { '001 accept all to lo interface':
      proto   => 'all',
      iniface => 'lo',
      action  => 'accept',
    }->
    firewall { '002 reject local traffic not on loopback interface':
      iniface     => '! lo',
      proto       => 'all',
      destination => '127.0.0.1/8',
      action      => 'reject',
    }->
    firewall { '003 accept related established rules':
      proto  => 'all',
      state  => ['RELATED', 'ESTABLISHED'],
      action => 'accept',
    }
  }
  
  class my_fw::post {
      firewall { '999 drop all':
        proto  => 'all',
        action => 'drop',
        before => undef,
      }
  }

  class my_fw {
    firewall { '004 Allow inbound SSH':
      dport    => 22,
      proto    => tcp,
      action   => accept,
      provider => 'iptables',
    }
    firewall { '005 Allow inbound HTTP':
      dport    => 80,
      proto    => tcp,
      action   => accept,
      provider => 'iptables',
    }
  }
  
  Firewall {
    before  => Class['my_fw::post'],
    require => Class['my_fw::pre'],
  }
  
  class { ['my_fw::pre', 'my_fw::post','my_fw']: }
  
  class { 'firewall': }
```

在终端下输入以下命令：
   
   ```$ puppet apply -v learn_firewall.pp```
  
在执行该命令前,操作系统的防火墙规则为空：
```bash
$ iptables -L

Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
```
在执行完成该命令后，防火墙规则发生了以下变化：
```bash
$ iptables -L

Chain INPUT (policy ACCEPT)
target     prot opt source               destination
ACCEPT     icmp --  anywhere             anywhere             /* 000 accept all icmp */
ACCEPT     all  --  anywhere             anywhere             /* 001 accept all to lo interface */
REJECT     all  --  anywhere             loopback/8           /* 002 reject local traffic not on loopback interface */ reject-with icmp-port-unreachable
ACCEPT     all  --  anywhere             anywhere             state RELATED,ESTABLISHED /* 003 accept related established rules */
ACCEPT     tcp  --  anywhere             anywhere             multiport dports ssh /* 004 Allow inbound SSH */
ACCEPT     tcp  --  anywhere             anywhere             multiport dports http /* 005 Allow inbound HTTP */
ACCEPT     all  --  anywhere             anywhere             state RELATED,ESTABLISHED
ACCEPT     icmp --  anywhere             anywhere
ACCEPT     all  --  anywhere             anywhere
ACCEPT     tcp  --  anywhere             anywhere             state NEW tcp dpt:ssh
REJECT     all  --  anywhere             anywhere             reject-with icmp-host-prohibited
DROP       all  --  anywhere             anywhere             /* 999 drop all */

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination
REJECT     all  --  anywhere             anywhere             reject-with icmp-host-prohibited

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
```


## 2.代码讲解
### 2.1 `class firewall`

`firewall`类用于管理Iptables软件包和服务，会根据内核类型申明不同的类进行管理。

```puppet
class firewall (
  $ensure       = running,
  $pkg_ensure   = present,
  $service_name = $::firewall::params::service_name,
  $package_name = $::firewall::params::package_name,
) inherits ::firewall::params {
  case $ensure {
    /^(running|stopped)$/: {
      # Do nothing.
    }
    default: {
      fail("${title}: Ensure value '${ensure}' is not supported")
    }
  }

  case $::kernel {
    'Linux': {
      class { "${title}::linux":
        ensure       => $ensure,
        pkg_ensure   => $pkg_ensure,
        service_name => $service_name,
        package_name => $package_name,
      }
    }
    'FreeBSD': {
    }
    default: {
      fail("${title}: Kernel '${::kernel}' is not currently supported")
    }
  }
}
```
以Linux为例，`firewall::linux`会根据操作系统的不同调用对应的firewall::linux::xxx类:
```puppet

  case $::operatingsystem {
    'RedHat', 'CentOS', 'Fedora', 'Scientific', 'SL', 'SLC', 'Ascendos',
    'CloudLinux', 'PSBM', 'OracleLinux', 'OVS', 'OEL', 'Amazon', 'XenServer': {
      class { "${title}::redhat":
        ensure       => $ensure,
        enable       => $enable,
        package_name => $package_name,
        service_name => $service_name,
        require      => Package['iptables'],
      }
    }
    'Debian', 'Ubuntu': {
      class { "${title}::debian":
        ensure       => $ensure,
        enable       => $enable,
        package_name => $package_name,
        service_name => $service_name,
        require      => Package['iptables'],
      }
    }
    ...
    }
```

以RedHat为例，`firewall::linux::redhat`会根据操作系统和版本的不同跳转到相应的逻辑。通过这个模块可以发现，`firewall`类仅完成了安装软件包
和管理服务状态，但要维护一个支持多平台和版本的模块并非易事，需要投入大量的精力进去，这也是社区模式可以得到众多公司认可的原因。

```puppet
  # RHEL 7 and later and Fedora 15 and later require the iptables-services
  # package, which provides the /usr/libexec/iptables/iptables.init used by
  # lib/puppet/util/firewall.rb.
  if ($::operatingsystem != 'Amazon')
  and (($::operatingsystem != 'Fedora' and versioncmp($::operatingsystemrelease, '7.0') >= 0)
  or  ($::operatingsystem == 'Fedora' and versioncmp($::operatingsystemrelease, '15') >= 0)) {
    service { 'firewalld':
      ensure => stopped,
      enable => false,
      before => Package[$package_name],
    }
  }

  if $package_name {
    package { $package_name:
      ensure => $package_ensure,
      before => Service[$service_name],
    }
  }

  if ($::operatingsystem != 'Amazon')
  and (($::operatingsystem != 'Fedora' and versioncmp($::operatingsystemrelease, '7.0') >= 0)
  or  ($::operatingsystem == 'Fedora' and versioncmp($::operatingsystemrelease, '15') >= 0)) {
  ...
  # Redhat 7 selinux user context for /etc/sysconfig/iptables is set to unconfined_u
  case $::selinux {
    #lint:ignore:quoted_booleans
    'true',true: {
      case $::operatingsystemrelease {
        /^(6|7)\..*/: { $seluser = 'unconfined_u' }
        default: { $seluser = 'system_u' }
      }
    }
    #lint:endignore
    default:     { $seluser = undef }
  }

  file { "/etc/sysconfig/${service_name}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    seluser => $seluser,
  }
}
```
在上述代码中，需要理解以下新知识点：

第一点，`versioncmp`函数用于比较两个版本号并返回比较结果，例如:

```$result = versioncmp(a, b)```

  - a大于b，返回1
  - a等于b，返回0
  - a小于b，返回-1

第二点，要理解运算的优先级顺序，在上述代码出现了一段比较复杂的条件语句:

```puppet
if ($::operatingsystem != 'Amazon')
  and (($::operatingsystem != 'Fedora' and versioncmp($::operatingsystemrelease, '7.0') >= 0)
  or  ($::operatingsystem == 'Fedora' and versioncmp($::operatingsystemrelease, '15') >= 0))
```

首先()的优先级最高，因此以下表达式会优先进行计算：
 - ($::operatingsystem != 'Amazon')
 - (($::operatingsystem != 'Fedora' and versioncmp($::operatingsystemrelease, '7.0') >= 0))
 - ($::operatingsystem == 'Fedora' and versioncmp($::operatingsystemrelease, '15') >= 0))

其次，`==`的优先级等于`!=`高于`>=`高于`and`。
最后是最外层的and/or运算`if statement1 and statement2 or statement 3`，那么其运算顺序是哪一种?

- if (statement1 and statement2) or (statement 3)
- if statement1 and (statement2 or statement 3)

答案是前一种，因为`and`的优先级高于`or`

第三点，掌握case条件语句的语法。

case条件语句和if条件语句类似，均是选择其中的一个Puppet代码块进行执行，但其更适合用于字符串和数值的匹配。

```puppet
case $facts['name'] {
  'A':       { include role::case1 } 
  'B', 'C':  { include role::case2  } 
  /^(D|E)$/: { include role::case3  } 
  default:   { include role::default_case }
}
```

### 2.2 `type firewall`
资源类型`firewall`用于管理防火墙规则，以下举例说明如何在真实环境中使用该类型：

####2.2.1 为apache开启80和443端口

```puppet
firewall { '100 allow http and https access':
    dport  => [80, 443],
    proto  => tcp,
    action => accept,
  }
```
####2.2.2 丢弃FIN/RST/ACK包如果没有对应的SYN包

```puppet
firewall { '002 drop NEW external website packets with FIN/RST/ACK set and SYN unset':
  chain     => 'INPUT',
  state     => 'NEW',
  action    => 'drop',
  proto     => 'tcp',
  sport     => ['! http', '! 443'],
  source    => '! 10.0.0.0/8',
  tcp_flags => '! FIN,SYN,RST,ACK SYN',
}
```
#####2.2.3 SNAT 10.1.2.0/24

```puppet
firewall { '100 snat for network foo2':
  chain    => 'POSTROUTING',
  jump     => 'MASQUERADE',
  proto    => 'all',
  outiface => 'eth0',
  source   => '10.1.2.0/24',
  table    => 'nat',
}
```

### 2.3 `type firewallchain`

资源类型`firewallchain`用于管理管理防火墙的规则链，以下举例说明如何在真实环境中使用该类型:

#####2.3.1 默认丢弃INPUT链上的包
```puppet
  firewallchain { 'INPUT:filter:IPv4':
    ensure => present,
    policy => drop,
    before => undef,
  }
```


需要说明的是，这个模块有一定的 局限性，如只支持管理iptable和ip6tables。此外，在和Neutron同时使用时会遇到iptable规则的冲突问题。

## 3.扩展阅读

 - 运算符优先级 https://docs.puppet.com/puppet/4.10/lang_expressions.html#order-of-operations 
 - case条件语句 https://docs.puppet.com/puppet/4.10/lang_conditional.html#case-statements   

## 4.动手练习

1. 本章给出的第一个示例learn_firewall.pp存在一些问题,当修改防火墙规则时，旧的规则不会被删除，请修复这个问题
2. 为OpenStack Nova服务编写firewall规则，开放相应的服务端口
