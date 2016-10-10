# 漫谈Puppet4

0. [激动人心的改进](#激动人心的改进)
   - [速度，速度，还是速度](#速度，速度，还是速度)
   - [稳定性和鲁棒性的提升](#稳定性和鲁棒性的提升)
   - [全新的Parser](#全新的Parser)
2. [“不变"的agent](#“不变"的agent)
3. [不兼容的改动](#不兼容的改动)
   - [包管理方式的变化](#包管理方式的变化)
   - [配置文件/目录的路径变化](#配置文件/目录的路径变化)
   - [其他路径变化](#其他路径变化)
   - [`Directory Environment`正式启用](#`Directory Environment`正式启用)
   - [不再使用Ruby1.8.7](#不再使用Ruby1.8.7)
   - [下一代Puppet语言的改动](#下一代Puppet语言的改动)
   - [`Puppet Kick`等将被移除](#`Puppet Kick`等将被移除)
   - [HTTP API的变化](#HTTP API的变化)
   - [`puppet doc`和`tagmail`被移除](#`puppet doc`和`tagmail`被移除)
   - [Resource Type/Providers的变化](#Resource Type/Providers的变化)
   - [内部API和实现的变化](#内部API和实现的变化)
4. [被废弃的特性](#被废弃的特性)


## 激动人心的改进

Puppet4的第一个正式版本于2015年4月15日发布，截止到2016年9月22日，Puppet已正式发布了4.7.0版本。

Puppet4与3.x版本相比有两点不同：很多的变化，很大的变化。毫不夸张地说Puppet4是一个全新的项目！

### 速度，速度，还是速度

Puppet4使用函数式编程语言Clojure对Puppet Master进行了重写，Puppetlabs公司并为此新建了一个项目:[puppetserver](https://github.com/puppetlabs/puppetserver)。此外，PuppetDB也使用Clojure进行了重写。

如此脱胎换骨的变化，最主要的目的是为了提升性能，官方给出的数据是:

   > 相比Puppet3，Puppet4有2~3倍的性能提升。

这是一个非常吸引人的提升！要知道从Puppet2到Puppet3所带来约50%的性能提升，就让我们感动不已了！

在以往的实际生产中，我们遇到过多次来自于master端的性能瓶颈，在一个数千台规模有近百个Openstack集群规模的环境中，我们使用了多台物理+虚拟服务器来作为puppet master节点，管理着大量的服务，一旦遇到高并发的编排任务时，master端的CPU几乎处于100%的状态，超时时间设置为120秒的情况下，仍然会出现不少由于编译catalog超时而导致agent报错的情况。即使我们通过改进代码，水平扩展，组件拆分，参数调优，更换硬件等多种组合办法，但是受Puppet本身的语言性能瓶颈，对于Puppetmaster的性能我们并不满意。而Puppet4从根本上改进了性能问题。

PuppetDB也是主要瓶颈之一，像resource export,virtual resource等高级特性，以及facts,catalog的缓存都会使用到PuppetDB，虽然这些高级特性很炫酷而且也很实用，但是非常非常消耗资源。这使得我们在过去非常地谨慎甚至刻意去削减像Puppet高级特性的使用，这也是PuppetOpenstack社区禁止提交含有这些高级特性的代码的原因之一（另一个原因是有些高级特性无法再单机模式下使用）。

### 稳定性和鲁棒性的提升

此外，Puppet4一开始就拥有面向服务的架构：
 - 由于Clojure语言的天生优势，拥有良好的并发和互斥控制能力，而且可以使用丰富的Java Library，是作为后端服务开发的理想选择。
 - Puppetlabs公司开发了一个Clojure框架[Trapperkeeper framework](https://github.com/puppetlabs/trapperkeeper)：为了支撑长期运行的应用和服务而生，从而保证Puppet服务的稳定性和鲁棒性。

### 全新的Parser

 - 新的Parser支持lambdas和iteraion！再也不用使用tricky的creates_resources函数了：

```puppet
$a = [1,2,3] each($a) |$value| { notice $value }
```

 - 全新的parser还直接支持数据类型检查，再也不用stdlib里的validate_string等函数了:

```puppet
class ntp ( 
    Boolean $service_manage = true, 
    Boolean $autoupdate     = false, 
    String  $package_ensure = 'present', 
    # ... 
) { 
   # ... 
}
```

 - 另外一个亮点是直接支持插值式函数调用:

```puppet
notice "This is a random number: ${fqdn_rand(30)}
```
 - 支持链式赋值，代码可以变得更简洁了：

```puppet
$a = $b = 10
```

除了以上几点，还有其他诸多特性，不再一一举例。


## “不变”的agent

目前，puppet-agent仍然使用Ruby来维护。不过JVM可以支持Ruby的Java版本：JRuby。因此在未来，puppet-agent不排除可能会从JRuby过渡到Clojure。

## 不兼容的改动

Puppet4既然做了重写，因此有大量与Puppet3不兼容的变化。这些细节对于Puppet3用户来说是最关心的地方。

### 包管理方式的变化

过去，我们需要在服务器上单独安装Puppet,Facter,Hiera,Mcollective等多个组件才能获得相应的功能和特性。

在Puppet4中，安装Puppet不再需要安装多个软件包，而是采用AIO(All-in-One)的方式来简化软件包的管理，例如`puppet-agent`中包含以下组件：
 - Facter 3.4.x
 - CFacter 0.4
 - Hiera 1.3.x
 - Mcollective 2.9.x
 - Ruby 2.1.5
 - OpenSSL 1.0.0r


Puppetlabs将这种AIO的包管理方式称之为Puppet Collections(PC)，每个PC其实对应着一个软件仓库(repo)，为用户提供了Facter/Ruby/Puppet等组件的匹配矩阵。
下表给出了PC中主要软件包中整合的组件。

|软件包名|包含组件|
| --- | --- |
|`puppet-agent`|Puppet, Facter, Hiera, MCollective, pxp-agent, root certificates, Ruby, Augeas|
|`puppetserver`|Puppet Server，依赖`puppet-agent`|
|`puppetdb`|PuppetDB|
|`puppetdb-termini`|PuppetServer与PuppetDB交互的Plugin|


要在服务器上启用新版本的Puppet4，只需要执行一行简单的命令：

- 在基于RPM的系统下使用以下命令：
```code
yum localinstall http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
```

- 在基于Deb的系统下使用以下命令：
```code
# curl -O http://apt.puppetlabs.com/puppetlabs-release-pc1-wheezy.deb ; dpkg -i puppetlabs-release-pc1-wheezy.deb
```

通过这种集中式的软件仓库管理方式，用户可以移除过去puppetlabs-release中的production，dependencies，devel等多个仓库。

**注意**  `puppet-agent`不会自动升级老版本的`puppet`软件包(建议使用deb或rpm来管理软件包的升级)

### 配置文件/目录的路径变化

 1. 软件包的安装目录变更为`/opt/puppetlabs`
 3. 可执行文件已移动到`/opt/puppetlabs/bin`
 4. `confdir`从`/etc/puppet/`变为`/etc/puppetlabs/puppet`
 5. `ssldir`从`$vardir/ssl`变为`$confdir/ssl`
 6. puppetserver的配置文件放置在`/etc/puppetlabs/puppetserver`
 7. mcollective的配置文件放置在`/etc/puppetlabs/mcollective`
 8. 所有的module/manifest/data从`confdir`移到`codedir`
   - `codedir`默认路径是`/etc/puppetlabs/code`
   - 包含`environments`目录
   - 包含全局的`modules`目录（可选）
   - 包含hiera.yaml配置文件
   - 包含`hieradata`目录

### 其他路径变化

 - `puppet agent`的`vardir`已经移动到`/opt/puppetlabs/puppet/cache`
 - `rundir`已经移动到`/var/run/puppetlabs`
 
### `Directory Environment`正式启用

过去多年的Config File Environment将被正式移除。默认的environmentpath是`$codedir/environments`。

以新建一个`production`环境为例：
   - 将modules放置到`$codedir/environments/production/modules`
   - 将main manifest放置到`$codedir/environments/production/manifests`

你仍然可以使用`$codedir/modules`作为全局modules，并用`default_manifest`设置来配置一个全局的`main manifest`。


### 不再使用Ruby1.8.7

由于使用了AIO的包管理方式，Puppet不再使用系统自带的Ruby解释器，将直接使用Ruby 2.1.5版本。

### 下一代Puppet语言的改动

重点来了，Puppet4最重要的变化是重写了parser和evaluator，在Puppet 3.x中可以通过在puppet配置文件中开启`Future Parser`来使用，在Puppet4中该parser已经成为”present parser“，那么过去的parser正式[退出舞台](https://tickets.puppetlabs.com/browse/PUP-3274)。

新parser包含了迭代，变量类型检查等诸多新特性。并且，新parser对于数值，空字符串和'udenf/nil'比较提供更好的检查机制。

除了核心模块的变动以外，还有一些炫酷的特性。

 - 在PuppetMaster加载新的Puppet代码不再需要重启server服务
 - EPP(Embeded Puppet)将支持直接使用Puppet来编写inline和基于文件模，不再需要使用ERB，避免用户在Puppet和Ruby之间来回切换。
 - 支持使用Puppet来编写functions。

### `Puppet Kick`等将被移除

所有的项目在历史发展过程中，都会有很多的妥协和不良设计，Puppet项目从2到3很多旧有的特性只是被标记为废弃，并没有从代码库中移除，借助Puppet4版本的重构，大约60000行"technical debt"类型的代码被移除。
较为熟知的有以下:
 - `puppet kick`命令
 - `inventory`服务
 - `couchDB`facts terminus
 - `ActiveRecord`stored config
 - puppet.conf中`master`section


### HTTP API的变化

Puppet4中的另一个重要变化是master和agent通讯的URLs发生了变化。因此Puppet3的agent将无法和Puppet4的server端通信。例如：

- 在Puppet3中url是"http://localhost:8140/production/node/foo"
- 在Puppet4中url变成了"http://localhost:8140/puppet/v3/node/foo?environment=production"。

### `puppet doc`和`tagmail`被移除

由于`puppet doc`命令依赖RDoc，而RDoc与最新版本的ruby不兼容，因此在Puppet4代码中被移除，如果要继续使用，可以通过[puppetlabs-strings](https://forge.puppetlabs.com/puppetlabs/strings/)模块来提供类似的功能。

同理，`tagmail`被移除，可以通过[puppetlabs-tagmail](https://forge.puppetlabs.com/puppetlabs/tagmail)模块来找到它。


### Resource Type/Providers的变化

 这里举几个重要的变化：

 - 在Puppet3中，若用户没有设置allow_virtual属性，会有废弃的警告信息，在Puppet4中该警告会被移除，allow_vritual默认会从false变为true。


### 内部API和实现的变化

这些变化只会影响到Puppet内部ruby方法和库的调用接口，对终端用户的使用没有任何影响。


## 被废弃的特性

### Rack和WEBrick Web服务器被废弃

Rack和WEBrick Web服务器过去常用于开发和简单验证，目前已在Puppet 4.1中标记为弃用，计划在5.0中移除。

## 核心配置参数

Puppet4有多达[200个配置参数](https://docs.puppet.com/puppet/latest/reference/configuration.html)，不过用户需要关心的参数大约为30个。

### Agent端

#### 基础参数

 - `server`: Puppet Master的地址，默认值是`puppet`
  - `ca_server`: Puppet CA的地址，仅在多master模式使用
  - `report_server`: Puppet report server的地址，仅在多master模式使用
 - `certname`：node的证书名称，默认使用FQDN
 - `environment`：agent向master端请求的environment。默认是`prodcution`。

#### 运行相关

 - `noop`: agent仅在模拟运行并输出运行结果
 - `nice`: 指定agent运行的nice值，防止agent在应用catalog时占用过多的CPU资源
 - `report`: 是否发生report，默认为true。
 - `tags`： 限制Puppet只运行含有指定tags的resources。
 - `trace`, `profile`, `graph`,`show_diff`：用于debug agent运行结果
 - `usecacheonfailure `: 在master端无法返回一个正确的catalog时，是否回退执行上一个正确的catalog。默认是true，如果是开发环境，建议修改为false。
 - `prerun_command`和`postrun_command`：在Puppet执行前后运行的命令，若返回值非0，则Puppet执行失败。

#### 服务相关

 - `runinterval`: Puppet的运行间隔
 - `waitforcert`: Puppet请求证书签名的频率。当agent端第一次启动时，agent会提交一个CSR(certificate signing request)到ca server，该证书可能是自动签名(autosign)，或者需要人工批准，而这段时间无法预估，因此需要设置一个时间段，默认是2m。
 - `splay`和`splaylimit`：为每次Agent的定时执行添加一个随机数时间，用于避免惊群效应的发生。
 - `daemonize`:是否以进程方式运行，配合cron使用时，应设置为false。
 - `onetime`: 是否执行完成后退出，配合cron使用时，应设置为true。

### Server端

## 参考文档

 - https://docs.puppet.com/puppet/4.0/reference/whered_it_go.html
 - https://docs.puppet.com/puppet/4.0/reference/release_notes.html
 - https://puppet.com/blog/welcome-to-puppet-collections
 - http://www.infoworld.com/article/2687553/devops/puppet-server-drops-ruby-for-clojure.html
 - https://docs.puppet.com/puppet/latest/reference/puppet_collections.html


