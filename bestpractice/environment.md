# Environment

Environment这个概念是比较容易理解的，你可以联想到开发环境，测试环境，线上环境等等。
是的，environment的目的就是为了将不同类型的host分组。
我们都知道module的默认路径是放在/etc/puppet/modules。
假设我现在要开发一个puppet-apache模块，和线上环境使用的puppet-apache模块代码不一样，但是/etc/puppet/modules不是只能放一个模块吗？
因此，每个environment支持独立的Puppet modules和main manifest（节点定义文件）。

假如没有environemnt，而同时有生产，开发和测试环境，每套环境的Puppet代码都不尽相同，那么就需要搭建3台用于不同环境的Puppet Master。用Puppet Environment可以很容易的解决这个问题，使用Puppet Environment可以建立dev, production, test 三套环境，并且每套环境的代码都可以不同。这样就可以用一台Puppet Master管理多个集群环境。

## Directory Environments vs. Config File Environments

使用过2.x或者更早版本的同学，应该了解或使用过Config file environemtns。目前，Puppet支持两种定义环境的方式：

 - Directory Environments
 - Config File Environments

> 注意，Config File Env这种需要修改配置文件的方式已经被历史的潮流抛弃，所以我们只会介绍directory environment。

## 启用Directory Environment

在Puppet Master上启用Directory Environment，需要在puppet.conf中定义以下参数：

> environmentpath = /etc/puppet/environments

此参数定义了一个目录，此目录下的每一个子目录都是一个environment。

## Environment目录结构

上面说过，使用directory environment 的方式，每一个目录都是一个环境，这个目录可以包含环境自身的配置，模块和节点定义。directory environment（下面会使用**环境目录**替代）遵循下面的规律：

- 环境目录的名称即环境名称（知道为啥config file environment必须死了吧。）
- 环境目录必须放在environmentpath下，默认是在/etc/puppet/environements下
- 应该包含一个modules目录，属于该环境默认的module路径
- 应该包含一个manifests目录，属于该环境默认的节点定义路径
- 可以包含一个environment.conf文件，用于自定义当前环境modulepath和manifest设置来指定此环境的模块查找路径和节点定义路径。，比如说test和dev两个环境可以共用一个manifest目录。

在我们的线上业务中，一般使用了如下几个环境：

* dev
* test
* pre_production
* production

## 在Agent 端指定Environment

在Puppet master 上定义了多套环境之后，在agent 段需要指定本机使用的环境，否则就会使用默认的production 环境。在puppet.conf 中定义environment 参数来指定agent 所属的环境，例如指定agent 为liberty 环境：

| [agent]environment = liberty |
| --- |
