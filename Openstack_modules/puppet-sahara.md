# Puppet-sahara模块介绍

0. [基础知识 - 欲知部署之必先了解之](#基础知识)
    - [1.Why Sahara?](## 1. Why Sahara ?)
    - [2.Sahara的几个概念](## 2. Sahara的几个概念)
    - [3.Sahara组件介绍](## 3. Sahara组件介绍)
    - [4.谈谈Sahara部署](4. 谈谈Sahara部署)
1. [先睹为快 - 一言不合，立马动手?](#先睹为快)
2. [核心代码讲解 - 如何做到管理keystone服务？](#核心代码讲解)
    - [class keystone](###class keystone)
    - [class keystone::service](###class keystone::service)
    - [class keystone::endpoint](###class keystone::endpoint)
    - [define keystone::resource::service_identity](###define  keystone::resource::service_identity)
    - [class keystone::config](###class keystone::config) 
3. [小结](##小结)
4. [动手练习 - 光看不练假把式](##动手练习)

**本节作者：付广平**    

**建议阅读时间 2h**

# 基础知识

## 1. Why Sahara ?

近年来大数据可谓如火如荼，哪个企业不说搞大数据都要被嘲讽技术落后，程序员不张口闭口MapReduce、Nosql都不敢说自己学计算机的。而谈到大数据就必然和Hadoop粘一起，似乎谈大数据就等价于说Hadoop。

如今Hadoop再也不是当初的HDFS、MapReduce、Hbase这么简单了，现在大家谈的Hadoop往往表示的是一个庞大的Hadoop生态圈，包括了YARN、Spark、Sqoop、Hive、Impara、Alluxio等组件。面对如此庞大复杂的分布式系统，面临的首要挑战问题就是如何快速、高效部署和维护集群。

当面临小规模集群时，我们也许并不需要构建一套复杂的自动化部署工具，只需要从官方下载jar包分发到集群的各个节点，手动一一配置即可完成简单Hadoop集群部署。Hadoop部署非常灵活的同时也造成部署架构复杂，并且一旦规模大时，手动部署方式往往捉襟见肘，调试和维护难度系数直线上升。

面临以上集群部署和维护的痛点问题，很多公司基于社区版本开发了自己的Hadoop产品发行版以及一套完整的自动化部署工具，这些工具不仅能够支持节点自动发现以及可视化部署，还能实时监控集群的健康状态。主流的包括Cloudera公司开发的cloudera-manager工具，支持在Web页面快速部署大规模CDH集群，Hortonworks公司开发的Ambari工具也支持在Web页面上交互来完成HDP集群的部署。这些工具大大简化了部署和监控流程，降低了维护成本。

以上工具虽然很好地完成了Hadoop集群的自动化部署和监控，但其部署工具本身往往还需要手动部署，并且直接构建在物理集群之上，难以实现资源的按需使用以及弹性扩展，也不利于通过云服务的形式快速交付。

Openstack Sahara旨在基于IaaS之上自动化部署Hadoop集群，不仅支持原生Hadoop、Spark、Storm的快速部署，还集成了目前主流的部署工具，比如前面提到的cloudera-manager以及Ambari。也就是说，通过Sahara能够分分钟部署一个CDH或者HDP集群。

不仅如此，Sahara还实现了分布式计算即服务的接口，通过Sahara API能够在Web页面上方便地创建DataSource，然后通过表单交互的方式提交Hadoop Job，使开发者只需要专注于业务开发本身，而不需要关注底层实现，大大提高了开发效率。

Sahara是Openstack的高层服务，构建在Nova、Cinder、Neutron、Heat等之上。本章接下来将重点讨论如何在Openstack平台上部署Sahara组件。

## 2. Sahara的几个概念

本小节简单介绍下Sahara涉及的几个概念，主要针对感兴趣的读者能够快速了解Sahara，这些内容和部署关系不大，读者可直接跳过本节。

Sahara主要包含以下几个概念:

* Plugin，即Hadoop集群插件，不同的发行版和版本插件不同，如创建CDH集群使用cdh插件、创建Spark使用spark插件等，可以类似于驱动（driver）的概念。
* Image, Sahara创建集群的每一个节点都是虚拟机，Image即指定虚拟机使用的镜像，不同的插件对应镜像不同，使用前必须和插件绑定，即注册镜像。通常每个插件的镜像都会包含CentOS和Ubuntu两种镜像。
* Node Group Template，节点模板，主要包含以下内容:
  * 使用的插件，定义Hadoop集群发行版和版本。
  * 资源模板，如该节点使用的Flavor、Availability Zone、volume卷大小、安全组等。
  * 进程模板，定义该节点启动什么服务，比如namenode，datanode，spark-master,spark-slave,hue。
  * Hadoop配置参数，比如hdfs_client_java_heapsize,hadoop_job_history_dir等。
* Cluster Template，集群模板，定义集群拓扑，集群模板由Node Group Template构成，定义如几个datanode、几个spark-worker等，同时还定义Hadoop的一些配置信息，比如HDFS副本数等。
* Cluster，集群实例，集群实例必须由集群模板创建。

## 3. Sahara组件介绍

欲知如何部署Sahara，首先需要了解Sahara包含的组件以及模块。和Openstack其它大多数服务一样，Sahara同样需要依赖于消息队列、数据库等公共组件。

最开始Sahara只包含sahara-api一个服务，负责响应用户请求、访问数据库、创建集群等所有工作，造成单服务负载高并且缺乏HA支持。社区于是提出了下一代架构(https://wiki.openstack.org/wiki/Sahara/NextGenArchitecture)，新架构把sahara-api拆分成两个服务:

* sahara-api: 和大多数Openstack API服务类似，主要为用户提供RESTFul API接口。
* sahara-engine: 负责执行用户的各项任务，包括创建集群和提交用户提交的Job等。

访问数据库也单独分离出了一个独立的模块，称之为sahara-conductor，但注意和nova-conductor不一样，它只是一个模块，而不是一个服务，后期可能会发展成一个独立的服务来接管数据库访问。

Sahara官方的新架构图如下:

![sahara architecture](../images/sahara/sahara_architecture.png)

可见，Sahara服务相对来说还是比较简单的，只包含sahara-api和sahara-engine两个服务。下一小节中将开始介绍sahara的部署问题。

## 4. 谈谈Sahara部署

前面提到sahara服务相对简单，但不得不说，部署起来却大小坑不计其数。Sahara的工作原理本不应该在这里提及，但在不了解其工作原理的前提下部署Sahara，可以毫不夸张地说: No Way!

由于篇幅有限，对Sahara工作感兴趣的读者可以参考官方文档或者阅读源码，本文直接给出简化的工作流程仅供参考:

* 验证集群。主要检查集群模板是否合法，比如HDFS没有部署namenode、datanode数少于HDFS副本数等都属于不合法的集群。
* 调用Heat创建资源，比如虚拟机、网络、volume、安全组等。
* 通过ssh配置集群并启动集群服务，配置工作包括更新hosts文件、修改Hadoop xml文件等，启动服务如ResourceManager、NodeManager、Datanode、Namenode等等。
* 若集成的是厂商部署工具，则还需要调用其API部署集群，比如调用Cloudera-manager RESTFul API创建集群等。
* 等待所有服务启动完成后，集群创建完成。

从以上步骤可知，**Sahara部署前必须先部署Heat服务**，在M版本后这是必需的，M版之前可以使用direct engine，目前已经被彻底废弃。

sahara-engine是通过ssh连接虚拟机完成集群配置的，**因此sahara-engine必须能够和虚拟机所在网络连通。**

目前sahara-engine连通虚拟机的方式有以下几种:

* flat private network，这种方式不支持Neutron网络，不考虑。
* floating IPs，即给所有虚拟机分配公有IP。
* network namespace，通过网络命名空间访问，sahara-engine必须部署在网络节点，且不支持多网络节点情况(想想为什么？)。
* agent模式，这个尚未实现，主要想参考Trove的agent模式，通过消息队列通信。

以上4种方式其实只有中间两种方式可用，但若集成厂商的Hadoop发行版并且需要调用厂商工具API部署集群的情况，不支持network namespace模式，因为即使能通过进入netns方式ssh连接虚拟机，也不可能调用虚拟机内部的API服务（除非打通管理网和虚拟机网络）。**简而言之，CDH和HDP不支持netns模式。**

**因此，若要通过Sahara部署CDH或者HDP集群，请使用floating IPs模式，并开启虚拟机自动分配floating ip功能。**

关于Sahara的高可用，sahara-api由于是HTTP服务，高可用肯定是没有问题的，可以创建多个实例并放在LB之上即可。

但sahara-engine虽然和nova-conductor、nova-scheduler等服务一样都是消息消费服务，你可以通过部署多实例来提高服务的可用性，但并不能说实现了高可用。Sahara的任务通常都是分阶段的长任务，比如创建一个集群大概需要数分钟时间，但一个任务只能由一个sahara-engine实例全程负责，如果中途挂了，其它sahara-engine实例并不能接管工作。**尤其注意在集群扩容操作时，如果sahara-engine奔溃了，将导致集群可能永远处于中间状态，甚至导致集群瘫痪。**

OK，以上啰嗦了那么多，无非是想引导读者自己想明白Sahara应该怎么部署，sahara-api应该部署在哪个节点，sahara-engine应该怎么部署，相信读者已经自己能得到答案了。下一节将详细介绍puppet-sahara核心模块，该模块能通过puppet自动化部署Sahara服务。

# 核心代码讲解 - 如何一键部署Sahara？

