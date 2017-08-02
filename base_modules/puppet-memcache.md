# `puppet-memcached`

1. [先睹为快](#1.先睹为快)
2. [代码解析](#2.代码解析)
3. [小结](#小结) 
4. [动手练习](#动手练习)


Memcached是一个高性能的分布式内存对象缓存系统，用于动态Web应用以减轻数据库负载，最初由LiveJournal的Brad Fitzpatrick开发，目前得到了广泛的使用。它通过在内存中缓存数据和对象来减少读取数据库的次数，从而提高动态、数据库驱动网站的速度。

`puppet-memcached`是由Steffen Zieger(saz)维护的一个模块。同时，他还维护了`puppet-sudo`,`puppet-ssh`等模块。

`puppet-memcached`项目地址：https://github.com/saz/puppet-memcached

## 1.先睹为快

不想看下面大段的代码说明，已经跃跃欲试了？

Ok，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
$ puppet apply -e "class { 'memcached': }"
```

在看到赏心悦目的绿字后，Puppet已经完成了Memcached服务的安装，配置和启动。这是如何做到的呢？

我们打开`puppet-memcached`模块下`manifests/init.pp`文件来一探究竟吧。


## 2.代码解析

`puppet-memcached`模块的代码结构非常简洁，所有的工作都在`Class memcached`中完成：

### 2.1 `Class memcached`

1.以下代码完成了对`Memcached`软件包管理：

```puppet
  package { $memcached::params::package_name:
    ensure   => $package_ensure,
    provider => $memcached::params::package_provider
  }

  if $install_dev {
    package { $memcached::params::dev_package_name:
      ensure  => $package_ensure,
      require => Package[$memcached::params::package_name]
    }
  }
```
此处，值得一提的是：在`package`资源类型中，需要重写参数`provider`默认值的情况并不常见，该参数用于设置管理软件包的后端，常见的可选项有：`yum`,`apt`,`pip`等。

2.下述代码完成了对`Memcached`服务的管理：

```puppet
  if $service_manage {
    service { $memcached::params::service_name:
      ensure     => $service_ensure,
      enable     => $service_enable,
      hasrestart => true,
      hasstatus  => $memcached::params::service_hasstatus,
    }
  }
```

在`service`资源类型中，需要设置参数`hasstatus`的情况也并不多见，该参数用于设置目标服务是否具有查看服务状态的脚本，默认为`true`。如果该服务的软件包中并没有提供查看服务运行状态的脚本，可以添加`status`参数，来用于指定一个手动运行的命令：若返回值为0，则认为服务是运行状态；若返回值非0，则认为服务是非运行状态。

### 2.2 `memcached_sysconfig.erb`模板

在`class memcached`中使用了`file`资源对`Memcached`配置文件进行管理：

```puppet
  if ( $memcached::params::config_file ) {
    file { $memcached::params::config_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template($memcached::params::config_tmpl),
      require => Package[$memcached::params::package_name],
      notify  => $service_notify_real,
    }
  }
```

### 2.2.1 什么是模板

第一次见到了模板(`template`)，这是Puppet用于管理配置文件的常用方法。

模板是指含有可执行代码和数据的特殊文本格式文件，通过渲染最终生成纯文本文件。使用模板的目标就是通过一些简单的输入（传递几个参数）就可以产生复杂的文本输出。

在`memcached::params`中查询到RHEL下的`$memcached::params::config_tmpl`值为`${module_name}/memcached_sysconfig.erb`。

`.erb`又称为`Embedded Ruby`模板语言，Puppet可以通过函数`template`和`inline_template`来渲染模板文件。

下面取自`templates/memcached_sysconfig.erb`文件的部分代码片段。

```
<%-
result = []
if @verbosity
  result << '-' + @verbosity.to_s
end

...

if @extended_opts
  result << '-o ' + @extended_opts.join(',')
end
result << '-t ' + @processorcount.to_s

# log to syslog via logger
if @syslog && @logfile.empty?
	result << '2>&1 |/bin/logger &'
# log to log file
elsif !@logfile.empty? && !@syslog
  result << '>> ' + @logfile + ' 2>&1'
end
-%>
<%- if scope['osfamily'] != 'Suse' -%>
PORT="<%= @tcp_port %>"
USER="<%= @user %>"
MAXCONN="<%= @max_connections %>"
<% Puppet::Parser::Functions.function('memcached_max_memory') -%>
CACHESIZE="<%= scope.function_memcached_max_memory([@max_memory]) %>"
OPTIONS="<%= result.join(' ') %>"
<%- else -%>
MEMCACHED_PARAMS="<%= result.join(' ') %>"
...
MEMCACHED_USER="<%= @user %>"

...
<%- end -%>
```

### 2.2.2 模板标签

首先，在ERB模板中，标签(tag)是一个重要的概念。例如：
 - ```<% CODE %>```以成对出现，表示这是一段可执行代码
 - ```<%= EXPRESSION %>```以成对出现，表示是插入值的表达式
 - ```<%# COMMENT %>```成对出现，表示为一段注释
 - ```<%%```或```%%>```，表示```<%```或```%>```字符

如果在标签中加入```-```符，则会移除缩进和换行。

在`memcached_sysconfig.erb`代码片段中，以下为插入值的表达式，最终会将$tcp_port,$user,$max_connections变量的值插入到Memcached的配置文件中：
```
PORT="<%= @tcp_port %>"
USER="<%= @user %>"
MAXCONN="<%= @max_connections %>"
```
而下述代码则为一段可执行代码，用于判断`$osfamily`的值是否为'Suse'：
```
<%- if scope['osfamily'] != 'Suse' -%>
```

### 2.2.3 模板变量

模板可以访问Puppet中的变量，在模板中访问变量时会有一个范围(scope)的概念，调用该模板的class或define中的变量为该模板的局部变量，可以直接使用变量名进行调用。

在ERB模板中有两种方式来访问变量：
  - `@variable`
  - `scope['variable']`

在ERB模板中，变量的命名规范是是以`@`开头，例如下述代码片段中，在渲染该模板文件时，Puppet会去`class memcached`中去搜寻与`@tcp_port`对应的`$tcp_port`变量，查询到该变量的默认值是11211

```
PORT="<%= @tcp_port %>"
```



  
## 推荐阅读
  
  
##动手练习
  
1. 限制memcached最大使用内存为50%
2. 关闭对防火墙规则的管理
