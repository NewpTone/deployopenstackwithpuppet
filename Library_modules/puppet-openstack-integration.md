# puppet-openstack-integration

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - scenario](#核心代码讲解)
   - [scenario-aio.pp](###scenario-aio )
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

Puppet Openstack integration项目确保我们可以持续地测试和验证使用Puppet modules部署的Openstack集群。

> 建议在阅读其他module前，优先阅读本节内容。

**本节作者：余兴超**    

**建议阅读时间 50分钟**

## 先睹为快

如果你想要使用puppet modules部署一套all-in-one的openstack集群，那么可以在虚拟机(Ubuntu 14.04或者CentOS 7.x)的终端下执行以下命令：

```bash
git clone git://git.openstack.org/openstack/puppet-openstack-integration
cd puppet-openstack-integration
./all-in-one.sh
```
或者

```bash
curl -sL http://git.openstack.org/cgit/openstack/puppet-openstack-integration/plain/all-in-one.sh | bash
```

整个过程约需要20分钟。

我们分析以下这是怎么做到的？

all-in-one.sh是一个逻辑比较简单的脚本，其调用了run_tests.sh脚本。
这个脚本的主要作用有3点：
  - 安装Puppet相关软件包，
  - 执行puppet apply命令，完成相应服务的安装配置
  - 安装配置tempest并相应运行smoke测试
  
这里面主要讲解一下是如何实现服务的安装配置，主要使用的是run_puppet函数。
```bash
# 函数定义
PUPPET_ARGS="${PUPPET_ARGS} --detailed-exitcodes --color=false --test --trace"

PUPPET_FULL_PATH=$(which puppet)

function run_puppet() {
    local manifest=$1
    $SUDO $PUPPET_FULL_PATH apply $PUPPET_ARGS fixtures/${manifest}.pp
    local res=$?

    return $res
}
```
在下面连续调用了两次run_puppet函数：
```bash
# SCENARIO即要运行的manifests文件，决定了安装哪些服务
print_header "Running Puppet Scenario: ${SCENARIO} (1st time)"
run_puppet $SCENARIO
RESULT=$?
set -e
if [ $RESULT -ne 2 ]; then
    print_header 'SELinux Alerts (1st time)'
    catch_selinux_alerts
    exit 1
fi

# Run puppet a second time and assert nothing changes.
set +e
print_header "Running Puppet Scenario: ${SCENARIO} (2nd time)"
run_puppet $SCENARIO
RESULT=$?
set -e
if [ $RESULT -ne 0 ]; then
    print_header 'SELinux Alerts (2nd time)'
    catch_selinux_alerts
    exit 1
fi
```


## 核心代码讲解

目前Openstack Intra一共使用了三个测试场景，用于跑puppetopenstack的集成测试: scenario001, scenario002，scenario003.

而scenario-aio manifest是提供给想要了解和学习PuppetOpenstack项目的用户。它们之间的区别参见下表：

|     -      | scenario001 | scenario002 | scenario003 | scenario-aio |
|:----------:|:-----------:|:-----------:|:-----------:|:-------------:
| ssl        |     yes     |      yes    |      yes    |      no      |
| ipv6       |   centos7   |    centos7  |    centos7  |      no      |
| keystone   |      X      |       X     |       X     |       X      |
| tokens     |    uuid     |     uuid    |    fernet   |     uuid     |
| glance     |     rbd     |     swift   |     file    |     file     |
| nova       |     rbd     |       X     |       X     |       X      |
| neutron    |     ovs     |      ovs    | linuxbridge |      ovs     |
| cinder     |     rbd     |     iscsi   |             |    iscsi     |
| ceilometer |      X      |             |             |              |
| aodh       |      X      |             |             |              |
| gnocchi    |     rbd     |             |             |              |
| heat       |             |             |       X     |              |
| swift      |             |       X     |             |              |
| sahara     |             |             |       X     |              |
| trove      |             |             |       X     |              |
| horizon    |             |             |       X     |       X      |
| ironic     |             |       X     |             |              |
| zaqar      |             |       X     |             |              |
| ceph       |      X      |             |             |              |
| mongodb    |             |       X     |             |              |


### scenario-aio

这里我们以scenario-aio来解释它是如何部署起一个Openstack All-in-One的环境的。
scenario-aio的文件路径为: `fixtures/scenario-aio.pp`
```puppet
#从类的名称我们就可以知道aio安装了mq，mysql，keystone，glance，neutron等服务
include ::openstack_integration  
include ::openstack_integration::rabbitmq
include ::openstack_integration::mysql
include ::openstack_integration::keystone
include ::openstack_integration::glance
include ::openstack_integration::neutron
include ::openstack_integration::nova
include ::openstack_integration::cinder
include ::openstack_integration::horizon
include ::openstack_integration::provision
# aio中还配置了tempest，除了默认支持的nova，keystone，glance等服务外，开启了对于horizon和cinder的测试集
class { '::openstack_integration::tempest':
  horizon => true,
  cinder  => true,
}
```
那么接下来，我们进入到这些被调用的类中一探究竟。为了节省篇幅，我们分别挑选了mq和glance进行解释和说明。

### class openstack_integration::rabbitmq

我们可以理解为在openstack_integration的manifests目录下，所有和服务相关的类都是转发层，即对某个服务模块的调用。

在openstack_integration::rabbitmq中，通过调用class rabbitmq完成了对rabbitmq的安装和配置，并创建了一个路径为'/'的vhost，更多对rabbitmq类的介绍，请参见puppet-rabbitmq模块。

```puppet
class openstack_integration::rabbitmq {

  include ::openstack_integration::params
  include ::openstack_integration::config

  if $::openstack_integration::config::ssl {
    file { '/etc/rabbitmq/ssl/private':
      ensure                  => directory,
      owner                   => 'root',
      mode                    => '0755',
      selinux_ignore_defaults => true,
      before                  => File["/etc/rabbitmq/ssl/private/${::fqdn}.pem"],
    }
    openstack_integration::ssl_key { 'rabbitmq':
      key_path => "/etc/rabbitmq/ssl/private/${::fqdn}.pem",
      require  => File['/etc/rabbitmq/ssl/private'],
      notify   => Service['rabbitmq-server'],
    }
    class { '::rabbitmq':
      package_provider      => $::package_provider,
      delete_guest_user     => true,
      ssl                   => true,
      ssl_only              => true,
      ssl_cacert            => $::openstack_integration::params::ca_bundle_cert_path,
      ssl_cert              => $::openstack_integration::params::cert_path,
      ssl_key               => "/etc/rabbitmq/ssl/private/${::fqdn}.pem",
      environment_variables => $::openstack_integration::config::rabbit_env,
    }
  } else {
    class { '::rabbitmq':
      package_provider      => $::package_provider,
      delete_guest_user     => true,
      environment_variables => $::openstack_integration::config::rabbit_env,
    }
  }
  rabbitmq_vhost { '/':
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }

}
```
### class openstack_integration::glance

挑选glance的原因在于其代码相比其他服务更简洁一些，读者理解起来会稍微容易一些。
我们可以看到其
 - 调用glance::api和glance::resgistry完成了glance服务的配置
 - 调用glance::notify::rabbitmq完成了MQ的配置
 - 调用glance::db::mysql完成数据库的配置
 - 调用glance::client完成client的配置
 - 调用glance::keystone::auth完成glance keystone相关的配置
 - 通过传递的参数值，选择调用glance::backend::file/glance::backend::rbd/glance::backend::swift完成后端存储的配置

```puppet
class openstack_integration::glance (
  $backend = 'file',
) {

  include ::openstack_integration::config
  include ::openstack_integration::params

  if $::openstack_integration::config::ssl {
    openstack_integration::ssl_key { 'glance':
      notify => [Service['glance-api'], Service['glance-registry']],
    }
    Package<| tag == 'glance-package' |> -> File['/etc/glance/ssl']
    $key_file  = "/etc/glance/ssl/private/${::fqdn}.pem"
    $crt_file = $::openstack_integration::params::cert_path
    Exec['update-ca-certificates'] ~> Service['glance-api']
    Exec['update-ca-certificates'] ~> Service['glance-registry']
  } else {
    $key_file = undef
    $crt_file  = undef
  }

  rabbitmq_user { 'glance':
    admin    => true,
    password => 'an_even_bigger_secret',
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }
  rabbitmq_user_permissions { 'glance@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }
  class { '::glance::db::mysql':
    password => 'glance',
  }
  include ::glance
  include ::glance::client
  class { '::glance::keystone::auth':
    public_url   => "${::openstack_integration::config::base_url}:9292",
    internal_url => "${::openstack_integration::config::base_url}:9292",
    admin_url    => "${::openstack_integration::config::base_url}:9292",
    password     => 'a_big_secret',
  }
  case $backend {
    'file': {
      include ::glance::backend::file
      $backend_store = ['file']
    }
    'rbd': {
      class { '::glance::backend::rbd':
        rbd_store_user => 'openstack',
        rbd_store_pool => 'glance',
      }
      $backend_store = ['rbd']
      # make sure ceph pool exists before running Glance API
      Exec['create-glance'] -> Service['glance-api']
    }
    'swift': {
      Service<| tag == 'swift-service' |> -> Service['glance-api']
      $backend_store = ['swift']
      class { '::glance::backend::swift':
        swift_store_user                    => 'services:glance',
        swift_store_key                     => 'a_big_secret',
        swift_store_create_container_on_put => 'True',
        swift_store_auth_address            => "${::openstack_integration::config::keystone_auth_uri}/v3",
        swift_store_auth_version            => '3',
      }
    }
    default: {
      fail("Unsupported backend (${backend})")
    }
  }
  $http_store = ['http']
   $glance_stores = concat($http_store, $backend_store)
  class { '::glance::api':
    debug                     => true,
    database_connection       => 'mysql+pymysql://glance:glance@127.0.0.1/glance?charset=utf8',
    keystone_password         => 'a_big_secret',
    workers                   => 2,
    stores                    => $glance_stores,
    default_store             => $backend,
    bind_host                 => $::openstack_integration::config::host,
    auth_uri                  => $::openstack_integration::config::keystone_auth_uri,
    identity_uri              => $::openstack_integration::config::keystone_admin_uri,
    registry_client_protocol  => $::openstack_integration::config::proto,
    registry_client_cert_file => $crt_file,
    registry_client_key_file  => $key_file,
    registry_host             => $::openstack_integration::config::host,
    cert_file                 => $crt_file,
    key_file                  => $key_file,
  }
  class { '::glance::registry':
    debug               => true,
    database_connection => 'mysql+pymysql://glance:glance@127.0.0.1/glance?charset=utf8',
    keystone_password   => 'a_big_secret',
    bind_host           => $::openstack_integration::config::host,
    workers             => 2,
    auth_uri            => $::openstack_integration::config::keystone_auth_uri,
    identity_uri        => $::openstack_integration::config::keystone_admin_uri,
    cert_file           => $crt_file,
    key_file            => $key_file,
  }
  class { '::glance::notify::rabbitmq':
    rabbit_userid       => 'glance',
    rabbit_password     => 'an_even_bigger_secret',
    rabbit_host         => $::openstack_integration::config::ip_for_url,
    rabbit_port         => $::openstack_integration::config::rabbit_port,
    notification_driver => 'messagingv2',
    rabbit_use_ssl      => $::openstack_integration::config::ssl,
  }
}
```