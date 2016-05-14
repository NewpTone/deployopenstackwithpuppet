# Environment

Puppet Environment 用于隔离不同的环境，在每个环境中，可以有不同的Puppet 模块和独立的站点清单（main manifest）。

例如，我有生产，开发和测试环境，每套环境的Puppet 代码都不尽相同，那么我是否需要搭建3 台用于不同环境的Puppet Master ？用Puppet Environment 可以很容易的解决这个问题，使用Puppet Environment 可以建立dev, production, test 三套环境，并且每套环境的代码都可以不同。这样就可以用一台Puppet Master 管理多个异构的集群环境。

## Directory Environments vs. Config File Environments

Puppet 支持两种定义环境的方式：Directory Environments 和Config File Environments。注意，两种方式是互不兼容的，只能选择其中一种方式来定义环境。

Directory environments 将会在未来取代config file environment，因此，一般我们都使用Directory Environment 的方式来定义环境。

## 启用Directory Environment

在Puppet Master 上启用Directory Environment，需要在配置文件中定义：

> environmentpath = /etc/puppet/environments



此参数定义了一个目录，此目录下的每一个子目录都是一个environment，例如有如下结构

| /etc/puppet/environments  - prod  - dev  - test |
| --- |

这样就建立了prod/dev/test 三个环境，接下来可以给每个环境定义自己的模块路径（存放代码）和main manifest 路径（节点定义）。

## Structure of an Environment

上面说过，使用directory environment 的方式，每一个目录都是一个环境，这个目录可以包含环境自身的配置，模块和节点定义。directory environment 遵循下面的规律：

- .目录名就是环境名
- .目录必须是environmentpath 下的子目录，通常是/etc/puppet/environements 的子目录
- .包含一个modules 的子目录，此目录为所属环境的默认模块查询路径
- .包含一个manifests 的子目录，作为此环境的节点定义路径
- .可以包含一个conf 的配置文件，用于自定义当前环境的modulepath 和manifeset 参数

在environment.conf 中，可以自己定义modulepath 和manifest 参数来指定此环境的模块查找路径和节点定义路径。

在我们的线上业务中，一般使用了如下几个环境：

- .production：生产环境（Nova 的Puppet 版本为IceHouse，其余组件为Juno 版本）
- .nova\_ihouse：生产环境（Nova 的Puppet 版本为IceHouse，其余组件为Juno 版本）
- .test：测试环境
- .liberty：最新Liberty 版本的环境

对应的三个Puppet 项目也会有不通分支对应不通环境版本的代码：

- .sunfire
  - .liberty：Liberty 版本的Puppet 代码（CentOS7）
  - .master：对应 nova\_ihouse 环境的代码
  - .juno：使用了Juno 版本的Puppet-nova 代码，其余组件也为Juno 版本
- .storm
  - .liberty：Liberty 版本的Puppet 代码（CentOS7）
  - .master：对应 nova\_ihouse 环境的代码
  - .juno：使用了Juno 版本的Puppet-nova 代码，其余组件也为Juno 版本
- .karma
  - .liberty：Liberty 版本的Puppet 代码（CentOS7）
  - .master：对应 nova\_ihouse 环境的代码

## 在Agent 端指定Environment

在Puppet master 上定义了多套环境之后，在agent 段需要指定本机使用的环境，否则就会使用默认的production 环境。在puppet.conf 中定义environment 参数来指定agent 所属的环境，例如指定agent 为liberty 环境：

| [agent]environment = liberty |
| --- |
