# `puppet-swift`模块

0. [基础知识](#基础知识)
1. [先睹为快](#先睹为快)
2. [核心代码讲解 - 如何做到管理swift服务？](#核心代码讲解)
    - [class swift](##class swift)
    - [class swift::proxy](##class swift::proxy)
    - [class swift::storage](##class swift::storage)
    - [class swift::keystone::auth](##class swift::keystone::auth)
    - [class swift::ringbuilder](##class swift::ringbuilder)
    - [class swift::ringserver](##class swift::ringserver)
    - [class swift::deps](##class swift::dips)
3. [小结](#小结)
4. [动手练习 - 光看不练假把式](#动手练习)


## 0.基础知识
Swift最初源自于Rackspace公司开发的高可用分布式对象存储服务CloudFiles，于2010年贡献给OpenStack开源社区作为最早的核心项目，为用户提供了对象存储，虚机镜像存储，块设备快照存储等诸多功能。Swift可以运行在廉价的标准X86硬件存储上，无需配置RAID（磁盘冗余阵列），通过在软件层面引入一致性哈希算法和数据冗余性，以牺牲一定的数据一致性来最终达到高可用性和可伸缩性，支持多租户模式、容器和对象读写操作，适合解决非结构化数据存储问题。

### 0.1 Swift基础概念
 - 账户（Account）:这里账户不是账号和密码的概念，可以理解为存储区域（Storage area）。
 - 容器（container）:容器有自己的metadata，包含了一组object。
 - 对象（object）:包含具体数据和metadata。
 - 集群（cluster）:表示一个Swift存储集群。
 - 区域（region）:表示一个集群中物理隔离的部分。
 - 区（zone）:表示物理隔离的节点，可用于控制故障域。
 - 节点（node）:表示运行Swift进程的物理服务器。

### 0.2 Swift组件介绍

Swift服务由众多的组件构成，其架构如下图所示：
![](../images/03/swift.png)

| 名称 | 说明 |
|--------|:-----:|
|swift-proxy-server|对外提供对象服务 API，会根据环的信息来查找服务地址并转发用户请求至相应的账户、容器或者对象服务；由于采用无状态的 REST 请求协议，可以进行横向扩展来均衡负载。|
|swift-account|提供账户元数据和统计信息，并维护所含容器列表的服务，每个账户的信息被存储在一个 SQLite 数据库中。|
|swift-container|提供容器元数据和统计信息，并维护所含对象列表的服务，每个容器的信息也存储在一个 SQLite 数据库中。|
|swift-object|提供对象元数据和内容服务，每个对象的内容会以文件的形式存储在文件系统中，元数据会作为文件属性来存储，建议采用支持扩展属性的 XFS 文件系统。|
|swift-replicator|会检测本地分区副本和远程副本是否一致，具体是通过对比散列文件和高级水印来完成，发现不一致时会采用推式（Push）更新远程副本，例如对象复制服务会使用远程文件拷贝工具 rsync 来同步；另外一个任务是确保被标记删除的对象从文件系统中移除。|
|swift-updater|当对象由于高负载的原因而无法立即更新时，任务将会被序列化到在本地文件系统中进行排队，以便服务恢复后进行异步更新；例如成功创建对象后容器服务器没有及时更新对象列表，这个时候容器的更新操作就会进入排队中，更新服务会在系统恢复正常后扫描队列并进行相应的更新处理。|
|swift-auditor|检查对象，容器和账户的完整性，如果发现比特级的错误，文件将被隔离，并复制其他的副本以覆盖本地损坏的副本；其他类型的错误会被记录到日志中。|
|swift-account-reaper|移除被标记为删除的账户，删除其所包含的所有容器和对象。|
|authentication server|验证访问用户的身份信息，并获得一个对象访问令牌（Token），在一定的时间内会一直有效；验证访问令牌的有效性并缓存下来直至过期时间。|
|cache server|缓存的内容包括对象服务令牌，账户和容器的存在信息，但不会缓存对象本身的数据；缓存服务可采用 Memcached 集群，Swift 会使用一致性散列算法来分配缓存地址。|

## 1.先睹为快

不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
Swift服务比较独立，下面编写learn_swift.pp实现all-in-one部署:


```puppet

$swift_local_net_ip='127.0.0.1'

$swift_shared_secret='changeme'

Exec { logoutput => true }

package { 'curl': ensure => present }


class { '::memcached':
  listen_ip => $swift_local_net_ip,
}

class { '::swift':
  # not sure how I want to deal with this shared secret
  swift_hash_suffix => $swift_shared_secret,
  package_ensure    => latest,
}

# === Configure Storage

class { '::swift::storage':
  storage_local_net_ip => $swift_local_net_ip,
}

# create xfs partitions on a loopback device and mounts them
swift::storage::loopback { '2':
  require => Class['swift'],
}

# sets up storage nodes which is composed of a single
# device that contains an endpoint for an object, account, and container

swift::storage::node { '2':
  mnt_base_dir         => '/srv/node',
  weight               => 1,
  manage_ring          => true,
  zone                 => '2',
  storage_local_net_ip => $swift_local_net_ip,
  require              => Swift::Storage::Loopback[2] ,
}

class { '::swift::ringbuilder':
  part_power     => '18',
  replicas       => '1',
  min_part_hours => 1,
  require        => Class['swift'],
}


# TODO should I enable swath in the default config?
class { '::swift::proxy':
  proxy_local_net_ip => $swift_local_net_ip,
  pipeline           => ['healthcheck', 'cache', 'tempauth', 'proxy-server'],
  account_autocreate => true,
  require            => Class['swift::ringbuilder'],
}
class { ['::swift::proxy::healthcheck', '::swift::proxy::cache']: }

class { '::swift::proxy::tempauth':
  account_user_list => [
    {
      'user'    => 'admin',
      'account' => 'admin',
      'key'     => 'admin',
      'groups'  => [ 'admin', 'reseller_admin' ],
    },
    {
      'user'    => 'tester',
      'account' => 'test',
      'key'     => 'testing3',
      'groups'  => [],
    },
  ]
}
```
在终端执行以下命令:
```bash
$ puppet apply -v learn_swift.pp
```
等待Puppet命令执行完成，一个单节点的Swift节点部署完成，可以通过swift命令行工具来使用你的对象存储系统了。

## 2.核心代码讲解
### 2.1 `class swift`

`swift`类用于完成以下工作：

  * 安装Swift软件包
  * 管理swift.conf配置文件
  * 管理swift相关目录

### 2.2 `class swift::proxy`

`swift::proxy`用于配置swift proxy服务：

```puppet
class swift::proxy(
  $proxy_local_net_ip,
  $port                      = '8080',
  $pipeline                  = ['healthcheck', 'cache', 'tempauth', 'proxy-server'],
  $workers                   = $::processorcount,
  $allow_account_management  = true,
  ...
  $package_ensure            = 'present',
  $service_provider          = $::swift::params::service_provider
) inherits ::swift::params {

  #所有swift_config资源的执行将触发swift-proxy-server的重启
  Swift_config<| |> ~> Service['swift-proxy-server']

  # validate函数用于检查参数的数据类型，若不匹配将抛出异常
  validate_bool($account_autocreate)
  validate_bool($allow_account_management)
  validate_array($pipeline)

  if($write_affinity_node_count and ! $write_affinity) {
    fail('Usage of write_affinity_node_count requires write_affinity to be set')
  }

  # member函数用于判断右侧参数是否在左侧参数中
  if(member($pipeline, 'tempauth')) {
    $auth_type = 'tempauth'
  } elsif(member($pipeline, 'swauth')) {
    $auth_type = 'swauth'
  } elsif(member($pipeline, 'keystone')) {
    $auth_type = 'keystone'
  } else {
    warning('no auth type provided in the pipeline')
  }

  if(! member($pipeline, 'proxy-server')) {
    warning('pipeline parameter must contain proxy-server')
  }

  if($auth_type == 'tempauth' and ! $account_autocreate ){
    fail('account_autocreate must be set to true when auth_type is tempauth')
  }

  if ($log_udp_port and !$log_udp_host) {
    fail ('log_udp_port requires log_udp_host to be set')
  }

  package { 'swift-proxy':
    ensure => $package_ensure,
    name   => $::swift::params::proxy_package_name,
    tag    => ['openstack', 'swift-package'],
  }

  concat { '/etc/swift/proxy-server.conf':
    owner   => 'swift',
    group   => 'swift',
    require => Package['swift-proxy'],
  }

  $required_classes = split(
    inline_template(
      "<%=
          (@pipeline - ['proxy-server']).collect do |x|
            'swift::proxy::' + x.gsub(/-/){ %q(_) }
          end.join(',')
      %>"), ',')
  concat::fragment { 'swift_proxy':
    target  => '/etc/swift/proxy-server.conf',
    content => template('swift/proxy-server.conf.erb'),
    order   => '00',
    before  => Class[$required_classes],
  }

  Concat['/etc/swift/proxy-server.conf'] -> Swift_proxy_config <||>
  ...
}
```

### 2.3 class swift::storage

`swift::storage`完成了配置rsync server的工作, 我们在基础模块章节中已介绍过，这里不再赘述。

### 2.4 `class swift::storage::disk`
`swift::storage::disk`是一个重要的类，用于管理磁盘分区和文件系统的创建。

puppet```
define swift::storage::disk(
  $base_dir     = '/dev',
  $mnt_base_dir = '/srv/node',
  $byte_size    = '1024',
  $ext_args     = '',
) {

  include ::swift::deps

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      ensure  => directory,
      owner   => 'swift',
      group   => 'swift',
      require => Anchor['swift::config::begin'],
      before  => Anchor['swift::config::end'],
    }
  }

  exec { "create_partition_label-${name}":
    command => "parted -s ${base_dir}/${name} mklabel gpt ${ext_args}",
    path    => ['/usr/bin/', '/sbin','/bin'],
    onlyif  => ["test -b ${base_dir}/${name}","parted ${base_dir}/${name} print|tail -1|grep 'Error'"],
    before  => Anchor['swift::config::end'],
  }

  swift::storage::xfs { $name:
    device       => "${base_dir}/${name}",
    mnt_base_dir => $mnt_base_dir,
    byte_size    => $byte_size,
    loopback     => false,
    subscribe    => Exec["create_partition_label-${name}"],
  }

}
```
首先，`swift::storage::disk`会调用"create_partition_label-${name}"exec创建分区表，若存在则跳过，默认会使用整块磁盘, 如sdb。
也可以通过ext_args参数来传递额外的parted参数。例如，传入'mkpart primary 0% 100%'来创建第一个分区，例如sdb1。

其次，通过声明`swift::storage::xfs`来指定磁盘xfs文件系统的格式化，并将其挂载到默认为'/srv/node'目录下。

接下来，继续解析`swift::storage::xfs`代码。

### 2.5 swift::storage::xfs
`swift::storage::xfs`完成以下三项功能：

1.完成xfs文件系统的创建：
```puppet
  exec { "mkfs-${name}":
    command => "mkfs.xfs -f -i size=${byte_size} ${target_device}",
    path    => ['/sbin/', '/usr/sbin/'],
    unless  => "xfs_admin -l ${target_device}",
    before  => Anchor['swift::config::end'],
  }
```
2.判断设备的挂载类型
```puppet
  case $mount_type {
    'path': { $mount_device = $target_device }
    'uuid': { $mount_device = dig44($facts, ['partitions', $target_device, 'uuid'])
              unless $mount_device { fail("Unable to fetch uuid of ${target_device}") }
            }
    default: { fail("Unsupported mount_type parameter value: '${mount_type}'. Should be 'path' or 'uuid'.") }
  }
```

3.挂载文件系统
```
  swift::storage::mount { $name:
    device       => $mount_device,
    mnt_base_dir => $mnt_base_dir,
    loopback     => $loopback,
  }
```
接下来，进入到`swift::storage::mount`中。

### 2.6 swift::storage::mount

`swift::storage::mount`执行真正的文件系统挂载操作：

1.管理指定的挂载目录
```puppet
  file { "${mnt_base_dir}/${name}":
    ensure  => directory,
    owner   => 'swift',
    group   => 'swift',
    require => Anchor['swift::config::begin'],
    before  => Anchor['swift::config::end'],
  }
```
2.调用mount资源和exec做双重挂载
```puppet
  mount { "${mnt_base_dir}/${name}":
    ensure  => present,
    device  => $device,
    fstype  => $fstype,
    options => "${options},${fsoptions}",
  }

  # double checks to make sure that things are mounted
  exec { "mount_${name}":
    command   => "mount ${mnt_base_dir}/${name}",
    path      => ['/bin'],
    unless    => "grep ${mnt_base_dir}/${name} /etc/mtab",
    # TODO - this needs to be removed when I am done testing
    logoutput => true,
    before    => Anchor['swift::config::end'],
  }

```
3.管理挂载目录权限
```puppet
  exec { "fix_mount_permissions_${name}":
    command     => "chown -R swift:swift ${mnt_base_dir}/${name}",
    path        => ['/usr/sbin', '/bin'],
    refreshonly => true,
    before      => Anchor['swift::config::end'],
  }
```
注意，refreshonly属性表明该资源的执行只能通过被其他资源触发。

### 2.7 swift::ringbuilder

`swift::ringbuilder`用于创建account, container以及object的builder文件，并且调用`swift::ringbuilder::rebalance`对ring文件进行rebalance操作。

```puppet
class swift::ringbuilder(
  $part_power = undef,
  $replicas = undef,
  $min_part_hours = undef
) {

  include ::swift::deps
  Class['swift'] -> Class['swift::ringbuilder']

  swift::ringbuilder::create{ ['object', 'account', 'container']:
    part_power     => $part_power,
    replicas       => $replicas,
    min_part_hours => $min_part_hours,
  }

  Swift::Ringbuilder::Create['object'] -> Ring_object_device <| |> ~> Swift::Ringbuilder::Rebalance['object']

  Swift::Ringbuilder::Create['container'] -> Ring_container_device <| |> ~> Swift::Ringbuilder::Rebalance['container']

  Swift::Ringbuilder::Create['account'] -> Ring_account_device <| |> ~> Swift::Ringbuilder::Rebalance['account']

  swift::ringbuilder::rebalance{ ['object', 'account', 'container']: }
```

### 2.8 swift::ringserver
此类的工作：
* 通过创建一个rsync服务器来启动一个ringdatabase服务

## 小结
本章咱们介绍了swift的相关概念，通过一个小列子来部署一套all-in-one的swift环境，并且讲解了puppet-swift相关核心代码中的一些小知识点。
## 动手练习
如何部署一个多节点的swift的集群？要求一个API节点，一个Stoage节点。
