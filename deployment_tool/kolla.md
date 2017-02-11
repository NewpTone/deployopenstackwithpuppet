# Kolla
## 简介
***
Kolla是OpenStack Big Tent Governace下的一个项目，项目的目标是
>To provide production-ready containers and deployment tools for operating
OpenStack clouds.

Kolla使用Docker容器和Anisble playbooks来实现这个目标。Kolla是开箱即用的，即使你是个新手也可以很快的使用kolla快速部署你的openstack集群。Kolla也允许你根据实际的需求来定制化的部署。

kolla目前已经可以部署以下openstack项目
* [Aodh](http://docs.openstack.org/developer/aodh/)
* [Barbican](http://docs.openstack.org/developer/barbican/)
* [Bifrost](http://docs.openstack.org/developer/bifrost/)
* [Ceilometer](http://docs.openstack.org/developer/ceilometer/)
* [Cinder](http://docs.openstack.org/developer/cinder/)
* [CloudKitty](http://docs.openstack.org/developer/cloudkitty/)
* [Congress](http://docs.openstack.org/developer/congress/)
* [Designate](http://docs.openstack.org/developer/designate/)
* [Glance](http://docs.openstack.org/developer/glance/)
* [Gnocchi](http://docs.openstack.org/developer/gnocchi/)
* [Heat](http://docs.openstack.org/developer/heat/)
* [Horizon](http://docs.openstack.org/developer/horizon/)
* [Ironic](http://docs.openstack.org/developer/ironic/)
* [Keystone](http://docs.openstack.org/developer/keystone/)
* [Kuryr](http://docs.openstack.org/developer/kuryr/)
* [Magnum](http://docs.openstack.org/developer/magnum/)
* [Manila](http://docs.openstack.org/developer/manila/)
* [Mistral](http://docs.openstack.org/developer/mistral/)
* [Murano](http://docs.openstack.org/developer/murano/)
* [Neutron](http://docs.openstack.org/developer/neutron/)
* [Nova](http://docs.openstack.org/developer/nova/)
* [Rally](http://docs.openstack.org/developer/rally/)
* [Sahara](http://docs.openstack.org/developer/sahara/)
* [Senlin](http://docs.openstack.org/developer/senlin/)
* [Swift](http://docs.openstack.org/developer/swift/)
* [Tempest](http://docs.openstack.org/developer/tempest/)
* [Trove](http://docs.openstack.org/developer/trove/)
* [Vmtp](http://vmtp.readthedocs.io/en/latest/)
* [Watcher](http://docs.openstack.org/developer/watcher/)
* [Zaqar](http://docs.openstack.org/developer/zaqar/)

可以部署的基础组件包括
* [Ceph](http://ceph.com/) 做cinder/nova/glance存储后端
* [collectd (https://collectd.org),
  [InfluxDB (https://influxdata.com/time-series-platform/influxdb/), and
  [Grafana (http://grafana.org) for performance monitoring.
* [Elasticsearch (https://www.elastic.co/de/products/elasticsearch) and
   [Kibana (https://www.elastic.co/de/products/kibana) 日志分析
* [HAProxy (http://www.haproxy.org/) and
  [Keepalived (http://www.keepalived.org/) 高可用
* [Heka (http://hekad.readthedocs.org/) 分布式可扩展的日志系统
* [MariaDB and Galera Cluster (https://mariadb.com/kb/en/mariadb/galera-cluster/) 高可用数据库
* [MongoDB (https://www.mongodb.org/) Ceilometer和Gnocchi的数据库后端
* [Open vSwitch (http://openvswitch.org/) 
* [RabbitMQ (https://www.rabbitmq.com/) 消息队列

## Kolla体验
***
可以参照kolla官方文档https://github.com/openstack/kolla/blob/master/doc/quickstart.rst 进行部署。

## Kolla解决的问题
***

### 可配置的灵活架构

可以看下默认的多节点架构
```bash
# These initial groups are the only groups required to be modified. The
# additional groups are for more control of the environment.
[control]
# These hostname must be resolvable from your deployment host
control01
control02
control03

# The above can also be specified as follows:
#control[01:03]     ansible_ssh_user=kolla

# The network nodes are where your l3-agent and loadbalancers will run
# This can be the same as a host in the control group
[network]
network01

[compute]
compute01

# When compute nodes and control nodes use different interfaces,
# you can specify "api_interface" and another interfaces like below:
#compute01 neutron_external_interface=eth0 api_interface=em1 storage_interface=em1 tunnel_interface=em1

[storage]
storage01

[baremetal:children]
control
network
compute
storage

# You can explicitly specify which hosts run each project by updating the
# groups in the sections below. Common services are grouped together.
[kibana:children]
control

[elasticsearch:children]
control

[haproxy:children]
network

[mariadb:children]
control

[rabbitmq:children]
control

[mongodb:children]
control

[keystone:children]
control

[glance:children]
control

[nova:children]
control

[neutron:children]
network

[cinder:children]
control

[memcached:children]
control

[horizon:children]
control

[swift:children]
control

[heat:children]
control

[murano:children]
control

[ironic:children]
control

[ceph-mon:children]
control

[ceph-rgw:children]
control

[ceph-osd:children]
storage



# Additional control implemented here. These groups allow you to control which
# services run on which hosts at a per-service level.
#
# Word of caution: Some services are required to run on the same host to
# function appropriately. For example, neutron-metadata-agent must run on the
# same host as the l3-agent and (depending on configuration) the dhcp-agent.

# Glance
[glance-api:children]
glance

[glance-registry:children]
glance

# Nova
[nova-api:children]
nova

[nova-conductor:children]
nova

[nova-consoleauth:children]
nova

[nova-novncproxy:children]
nova

[nova-scheduler:children]
nova

[nova-spicehtml5proxy:children]
nova

[nova-compute-ironic:children]
nova

# Neutron
[neutron-server:children]
control

[neutron-dhcp-agent:children]
neutron

[neutron-l3-agent:children]
neutron

[neutron-lbaas-agent:children]
neutron

[neutron-metadata-agent:children]
neutron
```

默认我们会把haproxy放到network节点，如果我想把haproxy放到一个单独的节点，那么我只需要到这样修改
```bash
-[haproxy:children]
-network
+[haproxy]
+haproxy01
+haproxy02
```
### 配置文件管理

每个openstack服务都运行在一个容器中，那kolla是怎么管理openstack的配置的呢? 我们拿nova-compute的配置管理来举例
#### 首先kolla会使用ansible为nova-compute生成一份配置文件放在/etc/kolla/nova-compute/目录下。

```bash
#nova_custom_config默认是/etc/kolla/configs/nova
#node_config_directory默认是 /etc/kolla
- name: Copying over nova.conf
  merge_configs:
    vars:
      service_name: "{{ item }}"
    sources:
      - "{{ role_path }}/templates/nova.conf.j2"
      - "{{ node_custom_config }}/global.conf"
      - "{{ node_custom_config }}/database.conf"
      - "{{ node_custom_config }}/messaging.conf"
      - "{{ node_custom_config }}/nova.conf"
      - "{{ node_custom_config }}/nova/{{ item }}.conf"
      - "{{ node_custom_config }}/nova/{{ inventory_hostname }}/nova.conf"
    dest: "{{ node_config_directory }}/{{ item }}/nova.conf"
  with_items:
    - "nova-api"
    - "nova-compute"
    - "nova-compute-ironic"
    - "nova-conductor"
    - "nova-consoleauth"
    - "nova-novncproxy"
    - "nova-scheduler"
    - "nova-spicehtml5proxy"
```
大家可能会注意到kolla使用merge_configs来完成配置文件的合并，那么merge_configs是干什么的呢?顾名思义，merge_configs就是把多个配置文件合成一个,kolla为什么要这样做呢？
openstack配置选项非常多但是真正需要管理的则很少，对这部分选项kolla使用模版的方式管理，同时由于merge_configs的使用，使得用户可以非常方便的添加自己的定制化选项。比如你部署kolla在一台虚拟机上，你必须使用QEMU hypervisor来替代KVM hypervisor。那么你可以在/etc/kolla/config/nova/nova-compute.conf中添加以下配置
```
[libvirt]
virt_type=qemu
```
merge_configs的代码在 ansible/action_plugins/merge_configs.py
#### 启动容器时/etc/kolla以docker卷的形式挂载到/var/lib/kolla/config_files目录下

```bash
- name: Starting nova-libvirt container
  kolla_docker:
    action: "start_container"
    common_options: "{{ docker_common_options }}"
    image: "{{ nova_libvirt_image_full }}"
    name: "nova_libvirt"
    pid_mode: "host"
    privileged: True
    volumes:
      - "{{ node_config_directory }}/nova-libvirt/:{{ container_config_directory }}/:ro"
      - "/etc/localtime:/etc/localtime:ro"
      - "/lib/modules:/lib/modules:ro"
      - "/run/:/run/"
      - "/dev:/dev"
      - "/sys/fs/cgroup:/sys/fs/cgroup"
      - "kolla_logs:/var/log/kolla/"
      - "libvirtd:/var/lib/libvirt"
      - "nova_compute:/var/lib/nova/"
      - "nova_libvirt_qemu:/etc/libvirt/qemu"
  when: inventory_hostname in groups['compute']
```

#### 容器启动脚本会根据nova-compute.json来将配置文件拷贝到/etc并设置合适的权限

```bash
{
    "command": "nova-compute",
    "config_files": [
        {
            "source": "{{ container_config_directory }}/nova.conf",
            "dest": "/etc/nova/nova.conf",
            "owner": "nova",
            "perm": "0600"
        }{% if nova_backend == "rbd" %},
        {
            "source": "{{ container_config_directory }}/ceph.*",
            "dest": "/etc/ceph/",
            "owner": "nova",
            "perm": "0700"
        }{% endif %}
    ]
}
```
关于kolla配置文件的管理还可以参考[这里](https://github.com/openstack/kolla/blob/master/doc/deployment-philosophy.rst)


### nova-fake测试控制平台性能
[这里](https://github.com/openstack/kolla/blob/master/doc/nova-fake-driver.rst)


### compute节点升级问题

由于所有服务都运行在容器中，那么是不是我升级compute节点时，该节点的虚机都会进入关机状态呢，kolla使用super-privilege的容器来解决了这个问题具体可以参考kolla PTL的文章https://sdake.io/2015/01/28/an-atomic-upgrade-process-for-openstack-compute-nodes/

### 平滑升级

kolla为升级也编写了upgrade.yaml这个playbook,我们还是拿nova-compute的升级为例
```bash
# kolla/ansible/roles/nova/tasks/upgrade.yml
---
# Create new set of configs on nodes
- include: config.yml

# TODO(inc0): since nova is creating new database in L->M, we need to call it.
# It should be removed later
- include: bootstrap.yml

- include: bootstrap_service.yml

- name: Checking if conductor container needs upgrading
  kolla_docker:
    action: "compare_image"
    common_options: "{{ docker_common_options }}"
    name: "nova_conductor"
    image: "{{ nova_conductor_image_full }}"
  when: inventory_hostname in groups['nova-conductor']
  register: conductor_differs

# Short downtime here, but from user perspective his call will just timeout or execute later
- name: Stopping all nova_conductor containers
  kolla_docker:
    action: "stop_container"
    common_options: "{{ docker_common_options }}"
    name: "nova_conductor"
  when:
    - inventory_hostname in groups['nova-conductor']
    - conductor_differs['result']

- include: start_conductors.yml

- include: start_controllers.yml
  serial: "30%"

- include: start_compute.yml
  serial: "10%"

- include: reload.yml
  serial: "30%"
```

## 使用
***

### 查看log

```bash
cd /var/lib/docker/volumes/kolla_logs/
```

### 进入容器调试

```bash
docker exec -it service_name  bash
```
### root权限问题

出于安全考虑很多kolla服务都是运行在非root下，进入容器后拿不到root权限，我们还以nova_compute为例,可以修改/etc/kolla/nova_compute/config.json改为以下
```bash
{
    "command": "nova-compute",
    "config_files": [
        {
            "source": "/var/lib/kolla/config_files/nova.conf",
            "dest": "/etc/nova/nova.conf",
            "owner": "nova",
            "perm": "0600"
        },
        {
            "source": "/var/lib/kolla/config_files/nova.sudo",
            "dest": "/etc/sudoers.d/nova.sudo",
            "owner": "root",
        }    ]
}
```
然后在/etc/kolla/nova-compute添加nova.sudo
```bash
nova       ALL=(ALL)       NOPASSWD: ALL
```
重启容器后即可sudo到root用户下调试

### 定制化build镜像

参考 https://github.com/openstack/kolla/blob/master/doc/image-building.rst

## 总结
***
优点
* 配置管理灵活方便
* 可以平滑升级
* 部署简单
* 环境隔离
* 多种安装源
* 支持的部署的服务多

缺点
* 对新手的友好程度
* debug不方便
    