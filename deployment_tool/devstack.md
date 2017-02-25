# 1.为什么需要Devstack ？

OpenStack是一个十分复杂的分布式系统，部署难度较大，调试也较困难。对于开发者，首先需要一个allinone的开发环境，可以随时修改代码并查看结果。各大厂商的部署工具一般都支持allinone的快速部署，比如红帽的RDO工具等。不过这些厂商的代码包通常是随着OpenStack的大版本发布而更新，不能实时与社区代码同步，而对于开发者而言，往往需要的是最新的代码，精确到最新的一次commit，因此使用厂商提供的部署工具难以满足开发需求。幸运的是社区已经提供了现成的快速部署工具，即DevStack(Develop OpenStack)，从英文名称上也能看出这是专为开发OpenStack量身打造的工具。

![DevStack Logo](../images/devstack/devstack.png)

DevStack不依赖于任何自动化部署工具，纯Bash脚本实现，因此不需要花费大量时间耗在部署工具准备上，而只需要简单地编辑配置文件，然后运行脚本即可实现一键部署OpenStack环境。利用DevStack基本可以部署所有的OpenStack组件，但并不是所有的开发者都需要部署所有的服务，比如Nova开发者可能只需要部署核心组件就够了，其它服务比如Swift、Heat、Sahara等其实并不需要。DevStack充分考虑这种情况，一开始的设计就是可扩展的，除了核心组件，其它组件都是以插件的形式提供，开发者只需要根据自己的需求定制配置自己的插件即可。

DevStack除了给开发者快速部署最新的OpenStack开发环境，社区项目的功能测试也是通过DevStack完成，开发者提交的代码在合并到主分支之前，必须通过DevStack的所有功能集测试。另外，前面提到DevStack是基于代码仓库的master分支部署，如果你想尝试OpenStack的最新功能或者新项目，也可以通过DevStack工具快速部署最新代码的测试环境。

# 2. 三步玩转DevStack

刚刚提到DevStack的强大之处，是不是“蠢蠢欲动"想要小试牛刀？不过在开始之前，我得友情提醒下，DevStack运行后会安装大量OpenStack依赖的软件包和Python库，如果你怕弄乱你的系统，建议开一个虚拟机（你说用容器？you can，you up)，在虚拟机里跑DevStack就不用担心会弄坏你的系统了。目前DevStack支持Ubuntu 14.04/16.04、Fedora 23/24、CentOS/RHEL 7以及Debian 和OpenSUSE操作系统，不过官方建议使用Ubuntu 16.04，因为该操作系统社区测试最全面，出现的问题最少。

OK，让我们开始一步步走起吧。

## 2.1 创建stack用户

为了系统的安全，DevStack最好不要在root用户下直接运行，因此需要创建一个专门的用户stack，该用户需要有免密码sudo权限，配置如下:

```
adduser stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers # 建议使用visudo
su stack
```

如果已经下载了DevStack代码，DevStack也提供了一个专门的脚本创建stack用户，该脚本位于`devstack/tools/create-stack-user.sh`，直接运行该脚本即可。

最后请务必检查当前工作用户为stack，并且能够不输入密码执行sudo命令。

## 2.2 配置DevStack

在DevStack根目录下创建`local.conf`配置文件，包含admin密码、数据库密码、RabbitMQ密码以及Service密码：

```
[[local|localrc]]
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
```

你也可以直接从`sample`目录下拷贝一个模板文件，然后在模板文件中修改。

部署一个最简单的OpenStack环境以上配置就够了，是不是特别简单？

## 2.3 Let DevStack Fly

```
./stack.sh
```

就这么简单？是的，一键部署，只需要一个命令！接下来你唯一需要做的，就是砌一杯咖啡静静地等待，取决于你的网络，通常需要等待半个小时。部署完后，会输出Dashboard地址以及默认创建的两个账号，一个是管理员账号admin，另一个是普通账号demo，如下：

```
This is your host IP address: 172.16.0.41
This is your host IPv6 address: ::1
Horizon is now available at http://172.16.0.41/dashboard
Keystone is serving at http://172.16.0.41:5000/
The default users are: admin and demo
The password: secret
```

注意以上部署的是一个精简版的OpenStack环境，默认只包含核心组件和Horizon，包括Keystone、Glance、Nova、Neutron、Cinder、Horizon等，其它服务则需要通过配置文件开启对应的插件完成，将在下面小节介绍。

## 2.4 关于下载速度优化

由于众所周知的原因，运行DevStack时下载OpenStack依赖包和Python库时非常慢，拉取OpenStack源码也非常耗时。为了避免这个问题，很多人都会从以下几个方面优化下载速度，加快部署速率：

### 1. 使用国内的镜像源

对于Ubuntu系统就是修改APT源，比如[阿里云镜像源](http://mirrors.aliyun.com/)，只需要修改`/etc/apt/source.list`配置文件即可，替换为需要使用的镜像源。如：

```
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
```

### 2. 使用国内的pip源

只需要在当前家目录`.pip`目录创建`pip.conf`配置文件，以使用阿里云为例，配置文件内容如下：

```
cat ~/.pip/pip.conf
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/
[install]
trusted-host=mirrors.aliyun.com
```

### 3.修改OpenStack源码地址

DevStack默认会从git.openstack.org下拉取代码，国内访问速度很慢，建议替换为github地址或者国内的trystack仓库，在`[[local|localrc]]`配置下增加以下配置项：

```
GIT_BASE=http://git.trystack.cn
```

如果你本地已经有最新的OpenStack源码了，也可以指定你本地的源码路径，比如使用本地的Nova源代码并且使用`new_feature`分支:

```
[[local|localrc]]
NOVA_REPO=/home/int32bit/nova
NOVA_BRANCH=new_feature
```

需要注意的是，国内源存在同步滞后，可能包不兼容或者下载某些包失败问题，出现这种情况时只需要重新替换原来的镜像源，然后重新运行`./stack.sh`即可。

## 3.使用DevStack环境开发

DevStack使用了Linux的终端复用工具screen，不同的服务运行在不同的window中，screen的使用方法可参考[官方文档](https://www.gnu.org/software/screen/manual/screen.html)。通常情况下，我们都是针对OpenStack的某个组件进行开发，比如Nova，只需要找到Nova的源码路径，修改对应的源码，然后重启对应的服务即可。比如你修改了nova源码下的`nova/compute/manager.py`代码，则需要重启nova-compute服务，重启步骤如下：

* 使用`screen -ls`命令查找stack session。
* 
```
# screen -ls
os3:~> screen -list
There is a screen on:
     28994.stack     (08/10/2016 09:01:33 PM)        (Detached)
1 Socket in /var/run/screen/S-sdague.
```
* 通过`screen -r socket` attach到前台运行，其中`socket`为scrren的名称，以上为`28994.stack`。
* 使用`ctrl-a n`和`ctrl-a p`遍历windows，直到找到nova-compute服务。
* 使用`ctrl-c` 杀掉nova-compute进程。
* 使用上下方向键遍历历史命令，找到跑nova-compute服务的命令，重新运行即可。

有些服务跑在Web服务器中，比如Keystone服务，此时重启Keystone服务只需要重启Apache服务即可。

如果你需要修改oslo代码或者python-xxxclient代码就相对麻烦点，因为这些代码不同于OpenStack源码，它默认不是从代码仓库中拉取，而是从已发布的pypi仓库中直接安装。你需要覆盖默认配置，手动配置代码仓库源:

```
[[local|localrc]]
LIBS_FROM_GIT=oslo.policy
OSLOPOLICY_REPO=/home/sdague/oslo.policy
OSLOPOLICY_BRANCH=better_exception
```

由于这些公共库需要被许多不同的项目依赖，因此社区的推荐做法是需要重新部署整个DevStack环境:

```
./unstack.sh && ./stack.sh
```

这个过程虽然不用重复从网络上下载包，相比第一次部署节省了不少时间，但仍然还是挺耗时间的，不利于单步调试。个人更倾向于改什么就重启什么服务，比如我修改了oslo.db代码，并且主要是解决Nova问题，那我只需要重启Nova服务即可，暂时不需要重新部署整个DevStack。而若修改了client代码，不需要重启任何服务，直接就可以测试功能。当然这种方式没有考虑其它服务的依赖，可能引入新问题，因此在确定开发完成后，最好还是完完全全走一遍unstack、stack流程。

# 4.使用DevStack部署其它OpenStack服务

前面我们使用DevStack部署了一个精简版的OpenStack环境，其中只包含了几个核心组件。其它OpenStack服务是通过插件形式安装，DevStack支持部署的所有插件列表可参考[DevStack Plugin Registry](http://docs.openstack.org/developer/devstack/plugin-registry.html)，截至2017年2月份，DevStack共包含132个安装插件。其中包含：

* trove: 数据库服务。
* sahara: 大数据服务。
* ironic: 裸机服务。
* magnum: 容器编排服务。
* manila: 文件共享服务。
* cloudkitty: 计费服务。
* ...

需要开启部署某个服务，只需要使用`enable_plugin`配置指定对应插件即可，该配置项语法为:

```
enable_plugin plugin_name [code repo]
```

其中`plugin_name`为插件名称，可以在插件列表中找到，`code repo`为代码仓库地址，不配置就使用默认的地址。

比如我们需要开启Sahara服务，只需要在`local.conf`增加以下配置项:

```
enable_plugin sahara https://github.com/openstack/sahara.git
enable_plugin sahara-dashboard https://github.com/openstack/sahara-dashboard.git
```

注意以上我们同时开启了两个Sahara相关的插件，前者是Sahara插件，而后者是dashboard的Sahara插件，若不配置该插件，在dashboard中将看不到Sahara面板。

除了OpenStack服务外，DevStack还支持其它和Openstack相关的插件，比如默认情况下都是使用本地文件系统存储作为OpenStack存储后端，如果需要测试Ceph后端，则需要开启[devstack-plugin-ceph](https://github.com/openstack/devstack-plugin-ceph)插件，该插件会自动部署一个单节点Ceph集群，然后就可以配置Glance、Nova、Cinder、Manila等服务使用Ceph后端了。

```
enable_plugin devstack-plugin-ceph git://git.openstack.org/openstack/devstack-plugin-ceph
ENABLE_CEPH_CINDER=True     # ceph backend for cinder
ENABLE_CEPH_GLANCE=True     # store images in ceph
ENABLE_CEPH_C_BAK=True      # cinder-backup volumes to ceph
ENABLE_CEPH_NOVA=True       # allow nova to use ceph resources
```

# 总结

本章首先介绍了DevStack的功能，然后详细介绍了如何使用DevStack快速部署一个OpenStack环境，最后介绍了使用DevStack部署其它OpenStack服务。DevStack项目是由社区维护的、专门为OpenStack开发人员准备的快速部署开发环境的脚本工具，该脚本工具具有非常灵活的扩展性，能够通过配置定制化部署OpenStack服务。除此之外，社区项目的功能测试也是通过DevStack完成的。由此可见，DevStack是社区一个非常重要的项目，DevStack出现问题不仅影响开发者开发，还将可能导致社区的CI系统奔溃。DevStack使用Shell脚本实现，如果想学习Shell编程，DevStack源码将是一个很好的学习案例。

# 参考

1. [DevStack官方文档](http://docs.openstack.org/developer/devstack/): http://docs.openstack.org/developer/devstack/
2. [Developing with Devstack](http://docs.openstack.org/developer/devstack/development.html): http://docs.openstack.org/developer/devstack/development.html
3. [devstack ceph plugin](https://github.com/openstack/devstack-plugin-ceph): https://github.com/openstack/devstack-plugin-ceph
