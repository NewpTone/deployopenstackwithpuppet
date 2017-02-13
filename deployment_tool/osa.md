# Openstack-Ansible
## 简介
***
OpenStack-Ansible 是 OpenStack 社区的官方项目，他从通过源代码部署到生产环境当中，从而可以更加容易的去的运维、升级、及扩展集群。同时OpenStack-Ansible（OSA）使用Ansible IT自动化引擎在Ubuntu Linux上部署一个OpenStack环境。为了隔离和易于维护，您可以将OpenStack组件安装到Linux容器（LXC）中。


***注意了解本章需要你有一定的 Ansible和 OpenStack的基本概念。本次我们通过一个 OpenStack-Ansible部署一套AIO环境


OpenStack-Ansible为OpenStack-Ansible支持的每个单独角色提供单独的角色存储库。有关单个角色文档，请参阅OpenStack-Ansible文档中的角色文档。
参考文档：
http://docs.openstack.org/developer/openstack-ansible/developer-docs/advanced-role-docs.html


目前已经可以配置以下基础组件包括
* galera_server[]
* haproxy_server
* memcached_server
* rabbitmq_server
* repo_build
* repo_server
* rsyslog_server

可以部署的Openstack组件包括
* os_aodh
* os_barbican
* os_ceilometer
* os_cinder
* os_designate
* os_glance
* os_gnocchi
* os_heat
* os_horizon
* os_ironic
* os_keystone
* os_magnum
* os_neutron
* os_nova
* os_rally
* os_sahara
* os_swift
* os_tempest
* os_trove

其他组件
* ansible-plugins
* apt_package_pinning
* ceph_client
* galera_client
* lxc_container_create
* lxc_hosts
* pip_install
* openstack_openrc
* openstack_hosts
* rsyslog_client
## Openstack-ansible 安装Openstack
***
环境准备,需要准备如下配置：
*8 vCPU’s
*50GB free disk space on the root partition
*8GB RAM
***
***
最小化配置需求：
* CPU主板支持hardware-assisted的虚拟化
* 8 CPU Cores
* 80GB的主分区，或者60GB的第二块分区。（如果使用第二块分区需要使用bootstrap_host_data_disk_device参数）。更多的细节可以去看如下链接：

官方建议配置：
* CPU主板支持hardware-assisted的虚拟化
* 8 CPU Cores
* 80GB的主分区，或者60GB的第二块分区。（如果使用第二块分区需要使用bootstrap_host_data_disk_device参数）。更多的细节可以去看如下链接：
* 16GB RAM
* 参考文献：http://docs.openstack.org/developer/openstack-ansible/developer-docs/quickstart-aio.html


开始构建AIO环境
通过OpenStack-Ansible部署一套AIO环境有四步曲，但是第一步是可选项，此步骤需要你自己完成。
* 环境配置
* 安装bootstrap和Ansible
* 初始化主机的bootstrap
* 运行Playbook

注意：当部署一套新的集群时，我们建议将当前机器的内核及软件包升级到最新的版本。并且如下的命令都是通过Root用户来运行。可以在虚拟机中执行AIO构建以进行演示和评估，但是虚拟机性能会很差。对于生产环境中建议为特定角色使用多节点方式。

本次部署环境使用Ubuntu 14.04 LTS，Ansible 版本为2.2.0，首先在节点所有将Package 更新
```bash
$ sudo apt-get dist-upgrade
```

git clone最新版本的openstack-ansible
```bash
$ sudo su -
$ git clone https://github.com/openstack/openstack-ansible
$ cd /opt/openstack-ansible
```

根据自己需求来部署对应的Openstack集群版本
```bash
# # List all existing tags.
# git tag -l

# # Checkout the stable branch and find just the latest tag
# git checkout stable/newton
# git describe --abbrev=0 --tags

# # Checkout the latest tag from either method of retrieving the tag.
# git checkout 15.0.0.0rc1
```

设定参数在部署过程中会使用
```bash
export BOOTSTRAP_OPTS="bootstrap_host_data_disk_device=vdb"
export ANSIBLE_ROLE_FETCH_MODE=git-clone
```
环境执行工具的安装和初始化
```bash
$ scripts/bootstrap-ansible.sh
```
执行命令环境准备
```bash
$ scripts/bootstrap-aio.sh
```
最后执行部署命令
```bash
$ scripts/run-playbooks.sh
```

安装过程需要一段时间才能完成，但这里有一些一般估计：
* 带SSD存储的裸机系统：30-50分钟
* 具有SSD存储的虚拟机：约45-60分钟
* 系统与传统硬盘：90-120分钟


一旦playbook完全执行，可以尝试在/etc/openstack_deploy/user_variables.yml中的各种设置更改，并且只运行单个剧本。例如，要运行Keystone服务的剧本，请执行
```bash
# cd /opt/openstack-ansible/playbooks
# openstack-ansible os-keystone-install.yml
```

重新构建环境
有时，销毁所有容器并重建AIO是最佳的方案。虽然最佳方案是AIO被完全破坏和重建，但这并不是最佳的方案。因此，可以执行以下操作
```bash
# # Move to the playbooks directory.
# cd /opt/openstack-ansible/playbooks

# # Destroy all of the running containers.
# openstack-ansible lxc-containers-destroy.yml

# # On the host stop all of the services that run locally and not
# #  within a container.
# for i in \
       $(ls /etc/init \
         | grep -e "nova\|swift\|neutron\|cinder" \
         | awk -F'.' '{print $1}'); do \
    service $i stop; \
  done

# # Uninstall the core services that were installed.
# for i in $(pip freeze | grep -e "nova\|neutron\|keystone\|swift\|cinder"); do \
    pip uninstall -y $i; done

# # Remove crusty directories.
# rm -rf /openstack /etc/{neutron,nova,swift,cinder} \
         /var/log/{neutron,nova,swift,cinder}

# # Remove the pip configuration files on the host
# rm -rf /root/.pip

# # Remove the apt package manager proxy
# rm /etc/apt/apt.conf.d/00apt-cacher-proxy
```

### 下图是AIO的部署逻辑图,此图不是按比例的，并且甚至不是100％准确，此图表仅用于信息目的:
未完待续
### OpenStack-ansible配置管理
未完待续
### OpenStack-ansible升级管理
未完待续

## 总结
优点
* 部署简单
* 环境隔离
* 支持的部署的服务多

缺点
* 对新手的友好程度
