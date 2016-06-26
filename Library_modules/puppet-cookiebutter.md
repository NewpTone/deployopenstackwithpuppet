# puppet-openstack-cookiebutter

1. [先睹为快](#先睹为快)
2. [模块讲解](#模块讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)


**本节作者：余兴超**    
**阅读级别：选读 **  
**阅读时间: 1小时**

## 先睹为快

本篇是选读章节，和Openstack部署没有任何关系。但推荐希望维护内部module的工程师阅读。
`puppet-cookiebutter`模块的作用是快速生成一个符合PuppetOpenstack module风格的新module。
二话不说，我们先来生成一个`puppet-test`:
```bash
# 请使用pip安装cookiecutter
$ cookiecutter puppet-openstack-cookiecutter/
project_name [YOURPROJECTNAME without 'puppet-']: test
version [0.0.1]:
year [2016]:
```
接着进入到puppet-test模块，我们来看看其目录结构，包含了manifests/，spec/和lib/目录，同时也添加了license和readme等文件，在此基础上就可以开始做新module的开发工作：
```bash
|-- LICENSE
|-- README.md
|-- lib
|   `-- puppet
|       |-- provider
|       |   `-- test_config
|       |       `-- ini_setting.rb
|       `-- type
|           `-- test_config.rb
|-- manifests
|   |-- config.pp
|   |-- db
|   |   |-- mysql.pp
|   |   |-- postgresql.pp
|   |   `-- sync.pp
|   |-- db.pp
|   |-- init.pp
|   |-- keystone
|   |   `-- auth.pp
|   |-- logging.pp
|   |-- params.pp
|   `-- policy.pp
|-- metadata.json
|-- spec
|   |-- classes
|   |   |-- test_db_mysql_spec.rb
|   |   |-- test_db_postgresql_spec.rb
|   |   |-- test_db_spec.rb
|   |   |-- test_keystone_auth_spec.rb
|   |   |-- test_logging_spec.rb
|   |   `-- test_policy_spec.rb
|   |-- shared_examples.rb
|   `-- unit
|       |-- provider
|       |   `-- test_config
|       |       `-- ini_setting_spec.rb
|       `-- type
|           `-- test_config_spec.rb
`-- tests
    `-- init.pp
```

# 模块讲解

在介绍`puppet-openstack-cookiebutter`模块之前，我们先介绍一下`Cookiecutter`:
一个用于创建项目模板的命令行工具集，最初的目的仅用于创建Python软件包项目。更多的介绍请参见：

* Documentation: https://cookiecutter.readthedocs.io
* GitHub: https://github.com/audreyr/cookiecutter
* PyPI: https://pypi.python.org/pypi/cookiecutter
