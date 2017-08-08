# `puppet-mysql`

1. [先睹为快](#1.先睹为快)
2. [代码讲解](#2.代码讲解)
3. [扩展阅读](#3.扩展阅读) 
4. [动手练习](#4.动手练习)

几乎所有OpenStack核心组件都会用到数据库组件, OpenStack支持的数据库后端有SQlite, MySQL, PostGreSQL。

而MySQL是使用最广泛的关系型数据库管理系统(Relational Database Management System：关系数据库管理系统), 数据库服务是OpenStack的基础服务，在部署和维护OpenStack集群之前，须要了解数据库相关的知识。
`puppet-mysql`模块是由Puppet官方所维护的项目，用于管理MySQL客户端程序和服务端的配置，以及管理备份脚本的支持，包括用于管理MySQL数据库，用户，授权等的自定义资源。
 
`puppet-mysql`项目地址：https://github.com/puppetlabs/puppetlabs-mysql

## 1.先睹为快
不想看下面大段的代码解析，已经跃跃欲试了？

OK，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
$ puppet apply -e "class { '::mysql::server': }"
```

等待终端完成命令执行后，在终端输入`mysql`就能直接连入MySQL服务了。

## 2.代码讲解

与其他模块不同的是，在puppet-mysql中并没有init.pp这个类(即`class mysql`)。熟悉Python的读者知道在每个Python模块中含有`__init__.py`文件，用于将当前目录注册为Python模块。然而对于Puppet模块来说，init.pp并不是强制的，即使不存在也不会影响Puppet识别其为Puppet模块。
### 2.1 `class mysql::server`

`mysql::server`类用于MySQL服务器端的部署，配置和服务的管理，以及root用户的管理。这些功能则 是通过声明其他类来完成的。值得注意的是被申明的类的命名域是`mysql::server::`，将与MySQL服务器端相关的类统一放到了同个目录下(manifests/server/)。

```puppet
  include '::mysql::server::config'
  include '::mysql::server::install'
  include '::mysql::server::installdb'
  include '::mysql::server::service'
  include '::mysql::server::root_password'
  include '::mysql::server::providers'
```

以上类主要完成以下操作:
 - 相关配置文件的安装
 - 软件包的安装
 - 初始化数据库
 - MySQL服务的启动
 - root用户/密码的设定

### 2.2 `class mysql::server::installdb`

`class mysql::server::installdb`用于MySQL数据库的初始化工作，它使用了自定义资源类型`mysql_datadir`来完成数据库目录的初始化：

```puppet
    mysql_datadir { $datadir:
      ensure              => 'present',
      datadir             => $datadir,
      basedir             => $basedir,
      user                => $mysqluser,
      log_error           => $log_error,
      defaults_extra_file => $_config_file,
    }
```

`mysql_datadir` 资源类型实际调用了`mysql_install_db`命令用于完成数据库目录的初始化，资源的属性将被传入作为该命令的参数。

### 2.3 `class mysql::server::config`

`mysql::server::config`类用于mysql配置文件和目录的管理，最核心的是对my.cnf文件的管理，以下代码中：

```puppet
  if $mysql::server::manage_config_file  {
    file { 'mysql-config-file':
      path                    => $mysql::server::config_file,
      content                 => template('mysql/my.cnf.erb'),
      mode                    => '0644',
      selinux_ignore_defaults => true,
    }
```
使用erb模板的方式完成了对my.cnf文件的管理，关于erb模板在前面的章节已经说明，这里不再赘述。

#### 2.3.1 如何动态地管理配置项?

使用模板带来的一个缺点是不灵活：所有的配置项需要提前写入到模板文件中，而模板不一定能做到包含所有的配置项和配置段落。

那么如何在生成配置文件时动态地添加配置项呢？

有多种手段来实现这个需求，我们可以先了解`puppet-mysql`是如何解决这个问题的。

在`mysql::server`类中有一个特殊的参数：

```puppet
...
  $override_options        = {},
...
  # Create a merged together set of options.  Rightmost hashes win over left.
  $options = mysql_deepmerge($mysql::params::default_options, $override_options)
```
参数`$override_options`是一个为空的哈希字典，通过变量名称可以判断，这是参数用于重写MySQL的默认选项。
参数`$mysql::params::default_options`是一个含有MySQL配置项默认值的哈希字典，其默认值如下：

```puppet
  $default_options = {
    'client'          => {
      'port'          => '3306',
      'socket'        => $mysql::params::socket,
    },
    'mysqld_safe'        => {
      'nice'             => '0',
      'log-error'        => $mysql::params::log_error,
      'socket'           => $mysql::params::socket,
    },
  ...
```
`mysql_deepmerge`是由`puppet-mysql`模块实现的自定义函数，用于对2个哈希字典执行合并操作。

例如：

```ruby
  $hash1 = {'one' => 1, 'two' => 2, 'three' => { 'four' => 4 } }
  $hash2 = {'two' => 'dos', 'three' => { 'five' => 5 } }
  $merged_hash = mysql_deepmerge($hash1, $hash2)
```
最终得到的结果是：$merged_hash = { 'one' => 1, 'two' => 'dos', 'three' => { 'four' => 4, 'five' => 5 } }

接下来，设置mysql::server::override_options 就可以实现动态管理配置文件的目的，例如:

```puppet
$override_options = {
  'newsection' => {
    'item' => 'value',
  }
}
```

这个变量最终生成的my.cnf 配置文件内容将新增以下配置：

```puppet
[newsection]
item = value
```

## `define mysql::db`
`define mysql::db` 用于创建数据库，以及相关用户和密码以及权限，以下是一段代码示例：

```puppet
mysql::db { 'mydb':
  user     => 'myuser',
  password => 'mypass',
  host     => 'localhost',
  grant    => ['SELECT', 'UPDATE'],
}
```
OpenStack服务在对其进行了封装后使用，本书会在后续的`puppet-openstacklib`章节中提及。


### 3.扩展阅读 

- 编写自定义函数 https://docs.puppet.com/puppet/4.10/lang_write_functions_in_puppet.html

### 4.动手练习

1. 阅读mysql::server::backup代码并使用其来实现数据库备份脚本的管理
2. 请使用`puppet-mysql`模块创建数据库keystone
