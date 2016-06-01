# puppet-firewall

1. [先睹为快－一言不和，立马动手?](#先睹为快)
2. [核心代码－如何管理apache服务](＃核心代码讲解)
3. [小结](#小结) 
4. [动手练习](#动手练习)

**本节作者：周维宇**    

**建议阅读时间 1h**

puppet-firewall模块是由puppetlabs公司维护的官方模块，让你可以通过puppet管理你的firewall规则.
# 先睹为快

是不是还想按着上面章节写的一样，马上尝试使用一下这个模块，少侠别激动，这个模块用起来是有风险的，不小心会把自己关在外面哦，请确保你可以通过除了ssh外的其他方式访问。

编写 learn_firewall.pp文件
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
  class profile::ssh {
    firewall { '100 allow ssh access':
      dport  => [22],
      proto  => tcp,
      action => accept,
    }
  }
  class my_fw::post {
    firewall { '999 drop all':
      proto  => 'all',
      action => 'drop',
      before => undef,
    }
  }
  
```
在终端下输入：
   
   ```puppet apply -v learn_firewall.pp```
  

好了，除了ssh外，所有端口的访问都被防火墙挡到了外面.

# 核心代码讲解
## class firewall
这个类负责管理软件包和服务
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

## Type firewall
这个Type帮你管理防火墙规则，实现放在lib/puppet/type/firewall.rb 里，使用ruby实现，我们在这里就不详细讲解代码，主要讲讲如何使用这个type

####为apache开启80和443端口
```puppet
firewall { '100 allow http and https access':
    dport  => [80, 443],
    proto  => tcp,
    action => accept,
  }
```
####丢弃FIN/RST/ACK包如果没有对应的SYN包
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
####SNAT 10.1.2.0／24子网
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

## Type firewallchain
管理防火墙的规则链
####默认丢弃INPUT链上的包
```puppet
  firewallchain { 'INPUT:filter:IPv4':
    ensure => present,
    policy => drop,
    before => undef,
  }
```


## 小结


## 动手练习
