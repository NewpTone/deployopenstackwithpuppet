# 准备工作

Openstack自动化部署的活儿不能说抡起袖子说干就干，首先你要做好一些准备工作，因为Openstack是一个复杂的技术栈组合，部署工作同样不简单，在你准备进入每个特定章节前，我们已为你准备好了相应的知识指北。


## 基础知识

* 对Linux基础知识有所了解，推荐《 鸟哥的Linux私房菜 基础学习篇》 
* 对Puppet基础知识有所了解  推荐 [官方学习文档](https://learn.puppet.com/)
* 对Openstack部署有所了解  推荐 [Installation Guide for Red Hat Enterprise Linux 7 and CentOS 7](http://docs.openstack.org/liberty/install-guide-rdo/)


## 资源准备

* 请确保你至少有一台可用的虚拟机，`2 vCPU`, `4G RAM`, `30G Disk`, 至少有一块`NIC`，操作系统为`CentOS 7.1/7.2`，并且可以连接上Internet
* 请确保操作系统上已安装了`git`命令行工具，并可以正常访问`https://github.com`

## 环境搭建

你可以使用我们准备的安装脚本来配置实验环境，请在终端下执行以下命令:

```bash
sudo curl http://pom.nops.cloud/scripts/install_example_environment.sh | bash
```
建议为你的虚拟机制作好快照，在调试代码时，我们尽可能使用纯净的测试环境。

## 其他准备

* 请系好安全带，我们准备起飞了 :D
