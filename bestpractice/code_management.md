# 模块管理

不同于其他的Openstack项目，puppet modules是一个数量庞大的存在。以我们当前在使用中的puppet modules为例，就已经多达96个（破百计日可待）。

## 依赖管理

目前有三种管理依赖的方式：

 - [Git submodules](http://git-scm.com/book/en/Git-Tools-Submodules) 通过git submodule的方式管理各个子模块
 - [Puppet module tool](http://puppetlabs.com/blog/module-of-the-week-puppet-module-tool-part-1/) 可以使用puppet forge基于module名称和版本来搜索和安装module
 - [Librarian-puppet](http://librarian-puppet.com/) ruby bundler的扩展，使用Puppetfile来管理

我们分别就这三种方式依次介绍一下，我们这里不说哪种方法最好，但我们会说明我们根据什么原因最终选择了哪种方法。

1.Puppet module tool

该方法使用metadata.json文件来管理每个module之间的依赖关系，以puppet-nova为例:

```json
 "dependencies": [
    { "name": "puppetlabs/apache", "version_requirement": ">=1.0.0 <2.0.0" },
    { "name": "duritong/sysctl", "version_requirement": ">=0.0.1 <1.0.0" },
    { "name": "openstack/cinder", "version_requirement": ">=8.0.0 <9.0.0" },
    { "name": "openstack/glance", "version_requirement": ">=8.0.0 <9.0.0" },
    { "name": "puppetlabs/inifile", "version_requirement": ">=1.0.0 <2.0.0" },
    { "name": "openstack/keystone", "version_requirement": ">=8.0.0 <9.0.0" },
    { "name": "puppetlabs/rabbitmq", "version_requirement": ">=2.0.2 <6.0.0" },
    { "name": "puppetlabs/stdlib", "version_requirement": ">=4.0.0 <5.0.0" },
    { "name": "openstack/openstacklib", "version_requirement": ">=8.0.0 <9.0.0" },
    { "name": "openstack/oslo", "version_requirement": "<9.0.0" }
  ]
```

2.Librarian-puppet

librarian-puppet支持从Modulefile或者metadata.json读取依赖，或者使用独立的Puppetfile。例如，社区的puppet-openstack_integration项目里就包含了Puppetfile:

```
## OpenStack modules
mod 'aodh',
  :git => 'https://git.openstack.org/openstack/puppet-aodh',
  :ref => 'master'

mod 'barbican',
  :git => 'https://git.openstack.org/openstack/puppet-barbican',
  :ref => 'master'
  ...
```
可以使用以下命令安装其所依赖的module:
```bash
  librarian-puppet install --verbose
```
3.git submodule

git submodule可以同时管理多个独立的项目，同时保持提交的独立。这也是目前我们所选择的方式。
我们根据Puppet Module的类型将其划分成了三个项目（你可以理解为modules的group）：

 - sunfire  内部自研服务模块
 - storm  Openstack服务相关模块
 - karma  运维系统相关模块

我们会为storm创建多个分支，例如:liberty,mitaka。在dev和test环境会使用git命令来切换代码，而在生产环境则会使用RPM包的方式来管理。这样做的好处是：

 - 遵循线上代码统一使用软件包管理的方式
 - dev和test环境可以随时修复代码并且灵活切换






  
  

