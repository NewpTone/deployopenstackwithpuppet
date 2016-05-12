# Hiera

# 1.简介和历史

Hiera是基于键值查询的数据配置工具，Hiera是一个可选工具，它的目标是：Hiera makes Puppet better by keeping site-specific data out of your manifests **.**

它的出现使得代码逻辑和数据可以分离管理。

在Puppet 2.x版本时代，Hiera作为一个独立的组件出现，若要使用则需要单独安装。在3.x版本之后，Hiera被整合到Puppet的代码中去。Hiera是Hierarchal单词的缩写，表明了其层次化数据格式的特点。

## 1.1 实例说明

在使用hiera前，一个常见的manifests文件是这么编写的：
```puppet
node "kermit.example.com" {
  class { "ntp":
    servers    => [ '0.us.pool.ntp.org iburst','1.us.pool.ntp.org iburst','2.us.pool.ntp.org iburst','3.us.pool.ntp.org iburst'],
    autoupdate => false,
    restrict   => [],
    enable     => true,
  }
}
 
node "grover.example.com" {
  class { "ntp":
    servers    => [ 'kermit.example.com','0.us.pool.ntp.org iburst','1.us.pool.ntp.org iburst','2.us.pool.ntp.org iburst'],
    autoupdate => true,
    restrict   => [],
    enable     => true,
  }
}
 
node "snuffie.example.com", "bigbird.example.com", "hooper.example.com" {
  class { "ntp":
    servers    => [ 'grover.example.com', 'kermit.example.com'],
    autoupdate => true,
    enable     => true,
  }
}
```

在使用了Hiera之后，manifests文件发生了如下变化：

```puppet
node "kermit.example.com", "grover.example.com", "snuffie.example.com" {
  include ntp
  # or:
  # class { "ntp": }
}
```


所有的数据设置移到了hiera中:

```yaml
---
ntp::restrict:
 -
ntp::autoupdate: false
ntp::enable: true
ntp::servers:
  - 0.us.pool.ntp.org iburst
  - 1.us.pool.ntp.org iburst
  - 2.us.pool.ntp.org iburst
  - 3.us.pool.ntp.org iburst
```

# 2.hiera.yaml配置文件

hiera.yaml是Hiera唯一的配置文件，它其中只有少数几个配置参数，但决定了Hiera不同的使用方式。

## 2.1 文件路径

在puppet.conf中通过设置hiera\_config参数来设置hiera.yaml文件的路径，默认值为：$confdir/hiera.yaml      

> 注意Puppet 4.x以上时，默认值变更为$codedir/hiera.yaml

## 2.2 参数详解

以下为hiera.yaml配置文件的默认值:

```yaml
---
:backends: yaml
:yaml:
  # on *nix:
  :datadir: "/etc/puppetlabs/code/environments/%{environment}/hieradata"
  # on Windows:
  :datadir: "C:\ProgramData\PuppetLabs\code\environments\%{environment}\hieradata"
:hierarchy:
  - "nodes/%{::trusted.certname}"
  - "common"
:logger: console
:merge_behavior: native
:deep_merge_options: {}
```



| 参数名称 | 类型 | 说明 |
| --- | --- | --- |
| :hierarchy | str或array | 每一行表示静态或动态的数据源，动态源是指使用了%{variable}格式的变量，hiera采用从上往下的顺序读取数据源。 |
| :backends | str或array | yaml或json，默认值:yaml |
| :logger | str | 决定warning和debug级别日志的发送位置: console (messages送到STDERR), puppet (messages送到Puppet日志系统), noop (messages静默) Puppet会将值覆盖为puppet，无论设置为其他任何一个值。|
| :merge_behavior [ ](http://docs.puppetlabs.com/hiera/3.0/configuring.html#mergebehavior) | str | native (default) — 仅合并最顶层key; deep — 递归合并; 在遇到冲突的key时, 低优先级会被使用。deeper — 递归合并; 在遇到冲突的key时, 高优先级会被使用。|
| :deep\_merge\_options | array | 当:merge\_behavior设置为deep或deeper时使用 |
| :yaml / :json :datadir | str |  数据源文件的查找路径 |

## Automatic Parameter Lookup

Hiera 是用来存储数据的地方，那么当Puppet 代码中需要从hiera 中读取某个数据时，我们可以在代码中使用hiera() 函数的方式，在hieradata 中查找某个键值存储的数据，例如在hieradata 文件test.yaml 中定义了：

``` foo: bar ```

那么，我可以在Puppet 代码中获取foo 这个键对应的值：

```puppet
$text = hiera('foo')
notify { "$text": }
```

foo 这个键对应的值通过hiera 函数获取到之后被保存在了$text 变量中。

除了使用hiera(), hiera\_include(), hiera\_array(), hiera\_hash() 等函数去hieradata 中读取之外，Puppet 还会自动从Hiera 中查找类参数，查找键为myclass:parameter\_one（即类名::参数名）。

在定义一个Puppet 类时，可以定义默认的参数值，例如下面的myclass 类的参数$parameter\_one 使用了默认值"default text"：

```puppet
class myclass ($parameter_one = "default text") {
  file {'/tmp/foo':
    ensure  => file,
    content => $parameter_one,
  }
}
```

当我们调用myclass 这个类时，Puppet 遵循如下方式来设定$parameter_one 这个参数的值：

 1. 如果在调用这个类的时候，显式的向其传递了参数值，那么Puppet 使用显式传递的值作为参数的值。
 2. 如果调用类时没有传递参数的值，那么Puppet 会自动从Hiera 中查询参数的值，查找时使用<CLASS NAME>::<PARAMETER NAME> 做为查找的键（例如上面的myclass 类的prarameter\_one 参数，查找键为myclass::parameter\_one）
 3. 如果方法1 和2 都没有获取到值，那么Puppet 会使用类定义中参数的默认值作为参数的值（例如myclass 中prameter\_one 参数的默认值为"default text"）
 4. 如果1 至3 都没有获取到值，那么Puppet 将会直接报错，代码的编译将被中断。

上面的方法2 是Puppet 最有趣的地方，因为Puppet 会自动从Hiera 中查找参数的值，我们可以在代码中使用include 语句来调用一个类，不需要对其传递任何参数值，所有的参数传递都可以将参数值写到Hiera 中，Puppet 会自动从Hiera 中读取类的参数。例如，我想调用上面定义的myclass 类，并且$parameter\_one 的参数值为"ustack"，参数的传递使用Hiera 来完成。那么我需要在Hiera 中写入下面的值：

```yaml
myclass::parameter\_one: 'ustack'
```

在代码中，调用myclass 类：

| include myclass |
| --- |

这里不用对myclass 传递参数，myclass 会自动读取Hiera 中对parameter\_one 定义的值，即$parameter\_one 的值在调用时为'ustack'



[http://docs.puppetlabs.com/hiera/latest/](http://docs.puppetlabs.com/hiera/latest/)
