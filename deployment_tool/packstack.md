# Packstack


## 简介
Packstack主要是由Redhat推出的用于概念验证（PoC）环境快速部署的工具。Packstack是一个命令行工具，它使用Python封装了Puppet模块，通过SSH在服务器上部署OpenStack。

Packstack支持三种运行模式：
 - 快速运行
 - 交互式运行
 - 非交互式运行

Packstack支持两种部署架构：

 - All-in-One，即所有的服务部署到一台服务器上
 - Multi-Node，即控制节点和计算机分离
 
 
 因为Redhat官方有非常详细的使用文档，因此本文将简要地介绍Packstack的快速运行以及交互式运行方式来部署All-in-One的Openstack。
 本文的重点会放在说明如何开发PackStack的Plugin来扩展Packstack的功能以满足定制化的需求。
 
 
 ## 部署前准备
 
 在开始部署前，我们需要准备一台虚拟机，它的规格如下：
 
 |硬件名称|要求
 | -- | -- |
 |内存 至少4G |
 |
