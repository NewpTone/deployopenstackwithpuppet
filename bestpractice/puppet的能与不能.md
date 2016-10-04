# Puppet的能与不能

Openstack云平台是一个复杂的软件栈，涉及到大量的配置，服务，软件包等等多种系统资源的管理，人工管理的方式必然带来最终不可维护，人工失误等诸多问题。因此，我们需要使用一套统一框架解决配置管理上的问题。我们在过去发现了一点就是，工程师们通常喜欢在一个系统/工具上去套所有的应用场景。

首先，我们要明白任何一个工具/语言/系统都不是万能的。我们在使用一个工具/语言/系统前，必须深刻理解它的能力和局限。我们既然选择了Puppet作为配置管理系统，就应知道它能做什么，不能做什么。


## 什么场景下选择使用Puppet?

Puppet适合用于以下场景：

- network,host,dns等文件的配置管理
- ssh,ntp,nscd等服务的状态管理
- MySQL,Apache,RabbitMQ等软件的包管理
- Openstack软件的包安装，配置文件管理以及服务状态的管理
- Puppet原生resource type，如ssh,host等
- Puppet第三方模块中的扩展resource，如keystone_user,mysql_database等


## 什么场景下不选择使用Puppet?

Puppet不适合使用以下场景：

- 源码文件管理

  有人可能会使用`file`resource来管理一些项目的脚本，比如zabbix的plugin scripts，这些代码文件通常作为静态文件放置在files/目录下，在agent应用catalog的阶段，从puppetserver下载到各个服务器上。这样做有好多缺点：
   - 首先, 每次代码文件的更新必须要更新相应模块，业务代码和部署代码完全耦合。
   - 其次，所有线上业务没统一的代码管理方式，在我们内部，所有项目必须使用RPM包的方式进行统一管理
   - 最后，每次执行Puppet Agent都会对每个文件单独计算hash值，并在服务器端做hash值比较，且会把旧文件备份到备份文件目录下，此操作会消耗客观的CPU和IO资源。

- 软件包的依赖管理

   例如在计算节点上，nova-compute依赖bridge-utils包，有些工程师喜欢在nova::compute里去添加一个`package`资源来确保在计算节点上安装此包。正确的做法是在nova的spec文件里，对openstack-nova-compute组件新增一条包依赖关系。
   我们应该明确包的依赖管理应该交给软件包管理工具去做。

- 二进制文件的管理

  我们可能会为一个业务系统添加一下方便管理，查询，统计或者清理的脚本，一些工程师的做法是将这些二进制可执行文件也丢到了puppet module的file/目录下，随着项目的发展会出现大量的二进制文件，那么它们的归宿，要么放到该项目的tools目录，或者单独作为一个项目存在，例如openstack_tools。

- 服务的初始化操作

  Puppet中有个`exec`资源，有些工程师拿它来写非常复杂的bash脚本。这就类似使用Python的subprocess去写非常复杂的bash脚本一样，实现方式非常丑陋，而且低效。例如Nova服务的`db sync`操作，复杂的实现逻辑已经封装到了Python脚本中，Puppet只是通过exec{'nova-db-sync'}去调用`nova-manage db sync`cli接口。

  因此在遇到业务逻辑非常复杂或者代价太大就应该交给项目去实现，对外提供操作简单的接口，然后交给Puppet去调用，而不是由Puppet去实现。

```
 exec { 'nova-db-sync':
    command => "/usr/bin/nova-manage ${extra_params} db sync",
    refreshonly => true,
    logoutput => on_failure
 } 
```

- 服务状态的监控和恢复

  有些工程师认为可以把Puppet的runinterval改成60s，这样就可以使用Puppet做频繁的状态收敛来确保服务一直是处于运行状态，虽然在一定程度上，可以确保服务的运行状态，但这里有两个问题：
  - Puppet既不是监控系统也不是专业的服务状态管理，60s的执行间隔对于服务来说，简直是太长了
  - Server端每次编译catalog会消耗大量资源，在集群数量增长或者Puppet代码逻辑复杂度提高后，你将会发现catalog的编译时间都已经超过了60s的执行间隔。


- 角色间或节点间的依赖管理处理

  Puppet本身没有编排能力，只能处理同个节点内类之间或者服务之间的依赖关系，这是Puppet最大的硬伤。因此，Puppet公司后来就收购了Mcollective来弥补编排的短板。我们这里推荐使用Ansible来做集群编排，Ansible作为后起之秀，提供了基于YAML格式的配置管理和编排能力。
