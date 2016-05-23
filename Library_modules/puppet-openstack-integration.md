# puppet-openstack-integration

1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - scenario](#核心代码讲解)
   - [scenario-aio.pp](###scenario-aio )
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

Puppet Openstack integration项目确保我们可以持续地测试和验证使用Puppet modules部署的Openstack集群。

> 建议在阅读其他module前，优先阅读本节内容。



## 先睹为快

如果你想要使用puppet modules部署一套all-in-one的openstack集群，那么可以在虚拟机(Ubuntu 14.04或者CentOS 7.x)的终端下执行以下命令：

```bash
git clone git://git.openstack.org/openstack/puppet-openstack-integration
cd puppet-openstack-integration
./all-in-one.sh
```
或者

```bash
curl -sL http://git.openstack.org/cgit/openstack/puppet-openstack-integration/plain/all-in-one.sh | bash
```

整个过程约需要20分钟。

我们分析以下这是怎么做到的？

all-in-one.sh是一个逻辑比较简单的脚本，其调用了run_tests.sh脚本。
这个脚本的主要作用有3点：
  - 安装Puppet相关软件包，
  - 执行puppet apply命令，完成相应服务的安装配置
  - 安装配置tempest并相应运行smoke测试
  
这里面主要讲解一下是如何实现服务的安装配置，主要使用的是run_puppet函数。
```bash
# 函数定义
PUPPET_ARGS="${PUPPET_ARGS} --detailed-exitcodes --color=false --test --trace"

PUPPET_FULL_PATH=$(which puppet)

function run_puppet() {
    local manifest=$1
    $SUDO $PUPPET_FULL_PATH apply $PUPPET_ARGS fixtures/${manifest}.pp
    local res=$?

    return $res
}
```
在下面连续调用了两次run_puppet函数：
```bash
# SCENARIO即要运行的manifests文件，决定了安装哪些服务
print_header "Running Puppet Scenario: ${SCENARIO} (1st time)"
run_puppet $SCENARIO
RESULT=$?
set -e
if [ $RESULT -ne 2 ]; then
    print_header 'SELinux Alerts (1st time)'
    catch_selinux_alerts
    exit 1
fi

# Run puppet a second time and assert nothing changes.
set +e
print_header "Running Puppet Scenario: ${SCENARIO} (2nd time)"
run_puppet $SCENARIO
RESULT=$?
set -e
if [ $RESULT -ne 0 ]; then
    print_header 'SELinux Alerts (2nd time)'
    catch_selinux_alerts
    exit 1
fi
```


## 核心代码讲解

目前Openstack Intra一共使用了三个测试场景，用于跑puppetopenstack的集成测试: scenario001, scenario002，scenario003.

而scenario-aio manifest是提供给想要了解和学习PuppetOpenstack项目的用户。它们之间的区别参见下表：

|     -      | scenario001 | scenario002 | scenario003 | scenario-aio |
|:----------:|:-----------:|:-----------:|:-----------:|:-------------:
| ssl        |     yes     |      yes    |      yes    |      no      |
| ipv6       |   centos7   |    centos7  |    centos7  |      no      |
| keystone   |      X      |       X     |       X     |       X      |
| tokens     |    uuid     |     uuid    |    fernet   |     uuid     |
| glance     |     rbd     |     swift   |     file    |     file     |
| nova       |     rbd     |       X     |       X     |       X      |
| neutron    |     ovs     |      ovs    | linuxbridge |      ovs     |
| cinder     |     rbd     |     iscsi   |             |    iscsi     |
| ceilometer |      X      |             |             |              |
| aodh       |      X      |             |             |              |
| gnocchi    |     rbd     |             |             |              |
| heat       |             |             |       X     |              |
| swift      |             |       X     |             |              |
| sahara     |             |             |       X     |              |
| trove      |             |             |       X     |              |
| horizon    |             |             |       X     |       X      |
| ironic     |             |       X     |             |              |
| zaqar      |             |       X     |             |              |
| ceph       |      X      |             |             |              |
| mongodb    |             |       X     |             |              |