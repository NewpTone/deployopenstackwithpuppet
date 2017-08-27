# puppet-openstack-cookiebutter

1. [先睹为快](#先睹为快)
2. [模块讲解](#模块讲解)
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

本篇是选读章节，和Openstack部署没有直接的管理，本节推荐从事开发并维护自研Puppet module的读者。

## 1.先睹为快

`puppet-cookiebutter`模块用于快速生成一个符合PuppetOpenstack代码风格的新module。
不想看下面大段的代码说明，已经跃跃欲试了？

Ok，我们开始吧！
   
打开虚拟机终端并输入以下命令：

```bash
# 请使用pip安装cookiecutter
$ cookiecutter puppet-openstack-cookiecutter/
project_name [YOURPROJECTNAME without 'puppet-']: test
version [0.0.1]:
year [2016]:
```
接着进入到puppet-test模块查看其目录结构，包含manifests/，spec/和lib/目录，manifests目录下创建了通用代码目录，例如db/下的mysql.pp, posygresql.pp, sync.pp等。
同时puppet-test添加了LICENSE和README等文件，在此基础上可以开始进行新module的开发工作：

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

## 模块讲解

在介绍`puppet-openstack-cookiebutter`模块之前，先了解一下`Cookiecutter`:

 > 一个用于创建项目模板的命令行工具集，最初的目的是用于创建Python项目。

使用该工具可以非常快速地生成一个Python软件包项目：
```bash
cookiecutter https://github.com/audreyr/cookiecutter-pypackage.git
```
关于cookiecutter的使用就不再展开，更详细的文档说明请参见：

* Documentation: https://cookiecutter.readthedocs.io
* GitHub: https://github.com/audreyr/cookiecutter
* PyPI: https://pypi.python.org/pypi/cookiecutter

本节不涉及任何代码的讲解，仅简要介绍一下其工作原理：cookiecutter使用了Python的Jinja2库对预置模板进行渲染，在puppet-openstack-cookiebutter模块中有一个目录是`puppet-{{cookiecutter.project_name}}`，其目录结构如下：
```bash
.
|-- lib
|   `-- puppet
|       |-- provider
|       |   `-- {{cookiecutter.project_name}}_config
|       `-- type
|-- manifests
|   |-- db
|   `-- keystone
|-- spec
|   |-- classes
|   `-- unit
|       |-- provider
|       |   `-- {{cookiecutter.project_name}}_config
|       `-- type
`-- tests
```
可以看到模板变量`{{cookiecutter.project_name}}`，那么在何处定义呢？

打开`cookiecutter.json`文件就可以看到：
```json
{
    "project_name": "YOURPROJECTNAME without 'puppet-'",
    "version": "0.0.1",
    "year":"2016"
}
```

## 3.小结

`puppet-openstack-cookiebutter`是一个辅助性模块，通过它可以快速地创建一个Openstack服务模块的所有基础代码目录和文件。如果在公司内部恰巧有开发内部模块的需求，那么通过它可以快速地构建出一个新模块。

## 4.动手练习

1. 阅读contrib/bootstrap.sh脚本并解释其使用用途
2. 在puppet-{{cookiecutter.project_name}}中添加一个新文件guide.md，并生成一个新模块puppet-cook
