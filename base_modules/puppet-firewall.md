# `puppet-firewall`模块

1. [先睹为快](#先睹为快)
2. [代码讲解](#代码讲解)
3. [推荐阅读](#推荐阅读) 
4. [动手练习](#动手练习)


iptables是一个配置Linux内核防火墙的命令行工具，用于设定一些特殊的规则，允许或拒绝数据包通过。

puppet-firewall模块是由Puppet公司维护的官方模块。通过自定义资源类型来管理用户的firewall规则,另外还引入了firewall chaing resource
管理iptables chains, 当前支持iptables和ip6tables。

`puppet-firewall`项目地址：'https://github.com/puppetlabs/puppetlabs-firewall'

## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

先别激动，这个模块的使用是有风险的，操作不慎会把自己也拒之门外，请确保可以通过除ssh外的方式登陆。

编写learn_firewall.pp文件:

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

在终端下输入：
   
   ```puppet apply -v learn_firewall.pp```
  

细心的读者，我这段代码写的有些问题，不知道你能不能找出来

## 核心代码讲解
### Class firewall
根据内核种类的不同来调用不同的class来实现软件包和服务管理

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
你以为到这里就结束了吗，还没有firewall::linux还会根据操作系统的不同进一步的调用firewall::linux::下的class
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
    'Archlinux': {
      class { "${title}::archlinux":
        ensure       => $ensure,
        enable       => $enable,
        package_name => $package_name,
        service_name => $service_name,
        require      => Package['iptables'],
      }
    }
```

接下来我们看看firewall::linux::redhat怎么实现的

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
    if $ensure == 'running' {
      exec { '/usr/bin/systemctl daemon-reload':
        require => Package[$package_name],
        before  => Service[$service_name],
        unless  => "/usr/bin/systemctl is-active ${service_name}",
      }
    }
  }

  service { $service_name:
    ensure    => $ensure,
    enable    => $enable,
    hasstatus => true,
    require   => File["/etc/sysconfig/${service_name}"],
  }

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

### Type firewall
这个Type帮你管理防火墙规则，实现放在lib/puppet/type/firewall.rb 里，使用ruby实现，我们在这里就不详细讲解代码，主要讲讲如何使用这个type

##### 为apache开启80和443端口
```puppet
firewall { '100 allow http and https access':
    dport  => [80, 443],
    proto  => tcp,
    action => accept,
  }
```
##### 丢弃FIN/RST/ACK包如果没有对应的SYN包
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
##### SNAT 10.1.2.0／24子网
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

### Type firewallchain
管理防火墙的规则链
##### 默认丢弃INPUT链上的包
```puppet
  firewallchain { 'INPUT:filter:IPv4':
    ensure => present,
    policy => drop,
    before => undef,
  }
```


## 小结
这个模块还是有他自己的局限性，比如只能管理iptable和ip6tables。另外这个模块在和neutron同时使用时也会遇到一些冲突问题。

## 动手练习
1. 本章给出的示例有些问题,当你修改防火墙规则时旧的规则不会被删除，请你修复这个问题
2. 为openstack环境编写firewall模块
