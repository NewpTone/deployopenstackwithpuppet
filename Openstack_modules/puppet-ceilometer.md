# puppet-ceilometer

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理ceilometer服务？](#核心代码讲解)
    - [class ceilometer](##class ceilometer)
    - [class ceilometer::api](##class ceilometer::api)
    - [class ceilometer::collector](##class ceilometer::collector)
    - [class ceilometer::db](##class ceilometer::db)
    - [class ceilometer::keystone::auth](##class ceilometer::keystone::auth)
    - [class ceilometer::agent::auth](##class ceilometer::agent::auth)
    - [class ceilometer::agent::polling](#class ceilometer::agent::polling)
    - [class ceilometer::agent::notification](#class ceilometer::agent::notification)
3. [小结](#小结)
4. [动手练习 - 光看不练假把式](#动手练习)

**本节作者：韩亮亮**

**建议阅读时间 1h**

ceilometer是openstack的数据收集模块，它把收集OpenStack内部发生的大部分事件，为计费和监控以及其它服务提供数据支撑。ceilometer的架构如下：
![](../images/03/ceilometer.png)
ceilometer服务
---
| 名称 | 说明 |
|--------|:-----:|
| openstack-ceilometer-api | 用于调用和查看collector收集的数据 |
| openstack-ceilometer-collector | 用于收集和记录polling和notification传过来的事件和计量数据 |
| openstack-ceilometer-notification | 用于监听消息队列，把感兴趣的监听消息变成Events和Samples，并发送到pipeline。 |
| openstack-ceilometer-polling | 用于获取openstack组件的信息，并生成监控数据，有三种启动类型：compute、central、ipmi。 |
ceilometer数据
---
| 名称 | 说明 |
|--------|:-----:|
| Sample | 某一个时间点获取到的监控数据 |
| Event | 就是一个事件、一个动作，如创建虚拟机、创建硬盘等。|
ceilometer收集数据方式
---
| 名称 | 说明 |
|--------|:-----:|
| Bus listener agent | 通过监听消息队列来获取信息，官方首选。|
| Polling agents | 通过调用API来收集信息。|
## 先睹为快
由于ceilometer依赖很多服务，所以最好先部署一个openstack，我们可以使用下一站章节的puppet-openstack-integration或devstack部署一套简易版openstack。

部署ceilometer：
在examples/site.pp里添加下面的代码,因为默认的site.pp里没有创建endpoint,role。
```puppet
  class { 'ceilometer::keystone::auth':
    password      => 'tralalayouyou'        #这个参数是puppet-openstack-integratioin中默认的。
  }
```
然后执行以下命令

```bash
# puppet apply examples/site.pp
```
等一会ceilometer就安装完成了。
验证：
```bash
# source openrc
# ceilometer event-list
```

## 核心代码讲解
### class ceilometer
class ceilometer中包括ceilometer组、用户的创建、软件包的安装，AMQP的选择及配置。
```puppet
  package { 'ceilometer-common':
    ensure => $package_ensure,
    name   => $::ceilometer::params::common_package_name,
    tag    => ['openstack', 'ceilometer-package'],
  }
```
puppet-ceilometer中对rpc的选择主要提供了两种：RabbitMQ和amqp，所提供的参数如下:
```puppet
  if $rpc_backend in [$::os_service_default, 'ceilometer.openstack.common.rpc.impl_kombu', 'rabbit'] {
    oslo::messaging::rabbit {'ceilometer_config':
      rabbit_host                 => $rabbit_host,
      rabbit_port                 => $rabbit_port,
      rabbit_hosts                => $rabbit_hosts,
      rabbit_userid               => $rabbit_userid,
      rabbit_password             => $rabbit_password,
      rabbit_virtual_host         => $rabbit_virtual_host,
      rabbit_ha_queues            => $rabbit_ha_queues,
......
    }
  } elsif $rpc_backend == 'amqp' {
    oslo::messaging::amqp { 'ceilometer_config':
      server_request_prefix  => $amqp_server_request_prefix,
      broadcast_prefix       => $amqp_broadcast_prefix,
      group_request_prefix   => $amqp_group_request_prefix,
      container_name         => $amqp_container_name,
      idle_timeout           => $amqp_idle_timeout,
      trace                  => $amqp_trace,
......
    }
  } else {
    nova_config { 'DEFAULT/rpc_backend': value => $rpc_backend }
  }
```
ceilometer通过调用oslo的oslo::messaging::notifications和oslo::cache两个define
对oslo_messaging_notifications和cache两个section进行配置。

### class ceilometer::api
在class ceilometer::api中先是定义了以下几个依赖关系：
```puppet
  Ceilometer_config<||> ~> Service[$service_name]
  Class['ceilometer::policy'] ~> Service[$service_name]

  Package['ceilometer-api'] -> Service[$service_name]
  Package['ceilometer-api'] -> Class['ceilometer::policy']
```
在上面的代码中我们可以看到有两种符号'->'和'~>'，这两者都是描述依赖，只不过不同的是‘->‘是在执行完前面的资源
之后执行后面的资源，而'~>'则是如果前面的资源有变动执行后面的资源。
同时，ceilometer api支持两种管理方式，独立启动服务和通过httpd管理，默认是独立启动，我们可以通过给class ceilometer::api传递service_name参数进行修改，代码如下：
```puppet
  if $service_name == $::ceilometer::params::api_service_name {
    service { 'ceilometer-api':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::api_service_name,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      require    => Class['ceilometer::db'],
      tag        => 'ceilometer-service',
    }
  } elsif $service_name == 'httpd' {
    include ::apache::params
    service { 'ceilometer-api':
      ensure => 'stopped',
      name   => $::ceilometer::params::api_service_name,
      enable => false,
      tag    => 'ceilometer-service',
    }
    Class['ceilometer::db'] -> Service[$service_name]

    # we need to make sure ceilometer-api/eventlet is stopped before trying to start apache
    Service['ceilometer-api'] -> Service[$service_name]
  } else {
    fail('Invalid service_name. Either ceilometer/openstack-ceilometer-api for running as a standalone service, or httpd for being run by a httpd server')
  }
```
其余代码则是对参数进行配置，略过。

### class ceilometer::collector
class ceilometer::collector用于安装ceilometer的collector服务，依然是装包、配置文件、启动服务。
不过，在中间我们发现了一段代码，不是我们原先熟悉的package的方式安装，而是用了ensure_resource，这两种方式
的不同，在于当我们使用package的方式安装软件包，定义重复时会报错，而ensure_resource不会，代码如下：
```puppet
  ensure_resource( 'package', [$::ceilometer::params::collector_package_name],
    { ensure => $package_ensure }
  )
```

### class ceilometer::db
class ceilometer::db应该和db目录下的几个文件放在一起看，ceilometer默认使用MySQL数据库，首先ceilometer::db::mysql调用::openstacklib::db::mysql创建ceilometer的数据库，代码如下:
```puppet
  ::openstacklib::db::mysql { 'ceilometer':
    user          => $user,
    password_hash => mysql_password($password),
    dbname        => $dbname,
    host          => $host,
    charset       => $charset,
    collate       => $collate,
    allowed_hosts => $allowed_hosts,
  }
```
然后触发dbsync.而class ceilometer::db则调用oslo::db配置ceilometer中db相关参数。
```puppet
  oslo::db { 'ceilometer_config':
    db_max_retries => $database_db_max_retries,
    connection     => $database_connection,
    idle_timeout   => $database_idle_timeout,
    min_pool_size  => $database_min_pool_size,
    max_retries    => $database_max_retries,
    retry_interval => $database_retry_interval,
    max_pool_size  => $database_max_pool_size,
    max_overflow   => $database_max_overflow,
  }
```
### class ceilometer::keystone::auth
ceilometer::keystone::auth模块是用来创建ceilometer的endpoint和role，其中有这么一段代码：
```puppet
  ::keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => $service_description,
    service_name        => $service_name_real,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    roles               => ['admin', 'ResellerAdmin'],
    public_url          => $public_url_real,
    admin_url           => $admin_url_real,
    internal_url        => $internal_url_real,
  }
```
我们可以看到这里调用keystone::resource::service_identity这个define的时候前面有::符号，这就要讲到
puppet中的一个概念:域。
puppet中的域分为4种：顶级域、节点域、父域和本地域。在所有的类、定义或节点之外的就是顶级域，如在site.pp
中定义了一个$v的参数，那我们可以在任意位置之中使用$::v来调用它。
节点定义中节点名称后面的一对大括号就是节点域，节点域中定义的变量只能在该节点内调用。
父域和本地域的关系在于继承，如果class A通过关键字inherits引用了class B，如下：
```puppet
class A{
  $variable = 'v1'
  ...
}
class B inherits A {
  ...
}
```
那么我们可以在class B中通过$::A::variable的方式调用该变量.

返过来看我们这段代码， ::keystone::resource::service_identity 这个调用前面使用::是在顶级域中搜索
keystone模块，这么看是不是就清晰多了。

### class ceilometer::agent::auth
class ceilometer::agent::auth用于配置ceilometer中的keystone配置，默认密码没有配置，所以在调用该
class的时候必需传该参数。在class里会把传进的参数传到ceilometer_config,在class ceilometer::config
里调用。

### class ceilometer::agent::polling
class ceilometer::agent::polling用于安装ceilometer polling agent,当然主要的还是那三板斧，
安装软件包、配置参数、启动服务。除这之外我们可以看到根据central_namespace、compute_namespace、ipmi_namespace三个参数，进行了不同的配置，并且通过inline_template调用ruby把namespaces这个数组转换
为字符串。代码如下：
```puppet
  $namespaces = [$central_namespace_name, $compute_namespace_name, $ipmi_namespace_name]
  $namespaces_real = inline_template('<%= @namespaces.find_all {|x| x !~ /^undef/ }.join "," %>')
```
inline_template用于在代码里使用嵌入式ruby，它里面的所有参数都会被传递并执行,在<%=和%>分隔符之间的所有代码都以Ruby代码来执行。

### class ceilometer::agent::notification
这个class用于配置ceilometer的notification agent，没有什么好讲的，三步：安装软件包，启动服务，配置参数。

## 小结
在puppet-ceilometer模块中还有一些其他的class,如：ceilometer::policy、 ceilometer::client、  ceilometer::config等，就留给读者自己去阅读了
## 动手练习
1. 安装ceilometer，并且安装compute和central两个客户端
2. 配置ceilometer运行在httpd下
3. 使用amqp替换RabbitMQ