# puppet-mysql

1. [先睹为快 - 一言不合，代码撸起?](#先睹为快)
2. [核心代码讲解 - 如何做到管理mysql服务？](#核心代码讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**建议阅读时间 40分钟**

几乎所有 openstack 核心组件都会用到数据库组件，其中 mysql 是使用最为广泛的数据库服务。数据库服务是 openstack 基础服务中最为重要的服务之一，在玩转 openstack 集群之前我们必须要学习数据库相关的知识。puppet-mysql 模块是由 puppetlabs 官方所维护的，此模块主要用于管理 mysql 客户端程序和服务端的 mysql 服务，以及管理备份脚本的支持，此模块中自定义了用于管理 mysql 数据库，用户，授权等的自定义资源。


##先睹为快
在解说puppet-mysql模块前，让我们来使用它部署一个mysql服务先吧。

在终端下执行以下命令:

```bash
puppet apply -e "class { '::mysql::server': }"
```

等待puppet执行完成后，在终端输入 `mysql` 就能直接连入 mysql 服务了。

#核心代码讲解
## class mysql::server
这个类主要用于 mysql server 的部署，服务的管理，以及 root 用户的管理。这些功能都是通过调用其他类来完成的：

```puppet
  include '::mysql::server::config'
  include '::mysql::server::install'
  include '::mysql::server::installdb'
  include '::mysql::server::service'
  include '::mysql::server::root_password'
  include '::mysql::server::providers'
```

这些类主要完成相关配置文件的安装，软件包的安装，初始化数据库，服务的启动，root 用户，密码的设定以及将密码写入家目录中的配置文件。


## class mysql::server::installdb
此类主要负责 mysql 数据库的初始化工作，它使用了模块中的自定义资源 `mysql_datadir` 用于完成数据库的初始化：

```puppet
    mysql_datadir { $datadir:
      ensure              => 'present',
      datadir             => $datadir,
      basedir             => $basedir,
      user                => $mysqluser,
      log_error           => $log_error,
      defaults_extra_file => $_config_file,
    }

    if $mysql::server::restart {
      Mysql_datadir[$datadir] {
        notify => Class['mysql::server::service'],
      }
    }
```

`mysql_datadir` 这个资源实际调用了 `mysql_install_db` 命令用于完成数据库的初始化，资源的参数也都作为这个命令的参数使用。还可以看到，如果在 `mysql::server` 类中设定了 restart 参数，那么一旦进行了数据库初始化操作，将会通知 mysql 服务重启。

## class mysql::server::config
config类主要负责mysql配置文件的管理，以及一些必要目录的创建。

```puppet
  $options = $mysql::server::options

  if $mysql::server::manage_config_file  {
    file { 'mysql-config-file':
      path                    => $mysql::server::config_file,
      content                 => template('mysql/my.cnf.erb'),
      mode                    => '0644',
      selinux_ignore_defaults => true,
    }
```
配置文件的管理，使用的是模板的方式，设置 mysql::server::override_options 就可以控制配置文件内容，例如

```puppet
$override_options = {
  'section' => {
    'item' => 'thing',
  }
}
```

这个变量最终生成的 mysql 配置文件内容将为：

```puppet
[section]
thing = X
```

## define mysql::db
`mysql::db` 这个 define 资源用于创建数据库，以及相关用户权限的授权，它的使用很简单：

```puppet
mysql::db { 'mydb':
  user     => 'myuser',
  password => 'mypass',
  host     => 'localhost',
  grant    => ['SELECT', 'UPDATE'],
}
```

这个类主要完成数据库的创建，用户的创建，以及授权的管理。


#小结
mysql 模块主要管理了 mysql 的服务，配置，用户以及数据库的创建。

#动手练习
1. 查看 mysql::server::backup 这个类的内容，用它来实现备份脚本的管理
2. 如何使用自定义资源 mysql_database 来创建数据库？


