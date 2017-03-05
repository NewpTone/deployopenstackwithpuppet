# Fuel

## What is Fuel?

Fuel 是由 Mirantis 公司开发的一个开源的 OpenStack 部署和管理工具，也是最为流行和易用的 OpenStack 部署管理工具。Mirantis 使用 Fuel 来快速的给客户交付一套生产可用的 OpenStack。Fuel 使用了 Puppet/Cobbler/Mcollective 等开源工具，同时使用 Python/Ruby 开发了部分自有服务，Fuel 的最大特点是它能提供 Web 界面用于安装部署和管理 OpenStack，除此之外它还有如下特点：

* 硬件的自动发现
* 通过 WebUI 对硬件进行配置，如网络配置，磁盘分区配置
* 可以管理多个 OpenStack 集群
* 完善的 HA  架构支持
* 部署前的检查和网络连通性验证
* 部署后的集群健康性检查

## Online demo

如果想快速的体验 Fuel，可以去 http://demo.fuel-infra.org:8000/ 体验 Fuel 的 demo 版本。

## Fuel 架构

Fuel 的架构包含：

* **Fuel Master Node, **安装了 Fuel 的服务器，用于完成 Provisioning, Configuration 以及 Fuel Slave 的 PXE booting 等功能。
* **Fuel Slave Node,**Fuel Slave Node 就是用于部署控制，计算，存储服务的服务器。

![](/images/fuel/fuel-arch.png)

Fuel 内部由众多组件组成，其中一些是 Fuel 自研发的\(Nailgun, OSTF, Astute\)，一些是第三方的开源组件\(Puppet, Cobbler, MCollective\)。

* Fuel 的 UI 是一个单页应用（JS）。
* **Nailgun** 是 Fuel 的核心组件，使用 Python 开发，它对外提供 REST API，它的主要功能是管理和保存配置数据，并处理部署的编排逻辑。它通过数据库来保存配置数据，通过 AMQP 来下发指令。
* **Astute** 相当于 Nailgun 的 worker，它接收 Nailgun 下发的指令，并完成对应的工作，它主要的工作主要是与 Cobbler/Puppet 等进行交互，使得这些服务对外提供一个抽象的异步接口。它通过 XML-RPC 来对 Cobller 进行管理和调用，通过 MCollective 来进行在节点上运行 Puppet 或者执行脚本。Astute 与 Nailgun 之间通过 AMQP 来进行数据通信。
* **Cobbler** 提供 provisioning 服务，Fuel 正在测试使用 Ironic 来替换 Cobbler（POC 阶段）
* **Puppet** 提供软件的部署服务。
* **Mcollective Agent** 用于执行脚本，运行 Puppet 等任务。
* **OSTF**\(OpenStack Testing Framwork, or Health Check\) 是 Fuel 的健康检查组件，它是一个独立的组件，可以脱离 Fuel 单独使用。它的主要作用是 OpenStack 的部署后功能性校验。

Fuel 架构中最核心的部分就是 Fuel Master Node。它包含了所有用于管理其他节点的所有服务，包括安装操作系统，创建 OpenStack 云环境等等。其中 Nailgun 是最重要的服务。它是一个 RESTful 的应用，包含了所有的业务逻辑。用户通过 Fuel Web 接口或者 CLI 接口来与它进行交互。例如创建新的环境，编辑配置，将节点与角色关联，并开始 OpenStack 集群的部署等等。

Nailgun 将所有的配置数据存储在 PostgreSQL 中，其中包含了节点的硬件配置，角色，环境等配置，以及当前的部署状态信息等等。

## 服务器发现 {#Fuel架构-服务器发现}

被管理节点启动时（PXE）会通过 master 节点上的 PXE  服务器提供的一个特殊的 bootstrap 镜像启动。这个镜像会运行一个特殊的脚本，即 Nailgun agent。nailgun-agent.rb 会收集节点的硬件信息并通过 REST API 将这些信息注册到 Nailgun 中，这样就完成了服务器的自动发现，可以在面板中给这些被发现的主机分配角色。

![](/images/fuel/nailgun.png)

## 集群部署 {#Fuel架构-集群部署}

当用户配置了一个新环境后，部署过程就开始了。Nailgun 服务会创建一个带有环境配置信息的 JSON 文件，并将这个文件发送到 RabbitMQ 上。这个信息应该由进行部署的进程收到，这个进程叫做 Astute。

![](/images/fuel/astute-1.png)

Astute 工作进程会监听 RabbitMQ 队列。它使用它的 Astute 库来完成所有的部署工作。首先，它会对环境的节点提供 provisioning 服务。Astute 使用 XML-RPC 来在 Cobbler 中设置节点的配置，并通过 MCollective agent 来重启节点来让 Cobbler 安装操作系统。Cobbler 是一个批量部署系统，它通过 DHCP 和 TFTP 服务来提供 PXE 服务。

Astute 把被管理节点需要执行的操作发送到 RabbitMQ 中。MCollective server 会在所有安装完操作系统的节点上启动并监听 MQ 中的消息，当收到消息后，会执行响应的操作并传递接收到的对应参数。MCollective agent 就是一些 Ruby 脚本，这些脚本用于完成相应的操作。

当被管理节点的操作系统安装完成后，Astute 就会开始部署 OpenStack 服务。首先，它使用 **uploadfile agent **将节点的配置文件分发到每个节点上，文件路径为 **/etc/astute.yaml。**这个文件包含了用于部署此节点的所有的变量和配置。

接下来，Astute 使用 **puppetsync **agent 来同步所有的 Puppet 模块和 manifest 文件。同步是通过 rsync 连接到 Master 节点的 rsync server 完成的，它会下载最新版本的 Puppet 模块和 manifest 文件。

![](/images/fuel/astute-puppet.png)

当模块同步完成后，Astute 会通过运行 Puppet 的** site.pp** 来进行部署工作。MCollective agent 通过 **daemonize **工具来运行 puppet，类似于这种命令：

| `deamonize puppet apply /etc/puppet/manifests/site.pp` |
| :--- |


Astute 会周期性的检查 agent 的执行进度，如果部署完成，它会通过 RabbitMQ  将状态报告至 Nailgun。

Puppet 会读取** astute.yaml** 文件的内容作为 fact 变量，并将其解析到 **$fuel\_settings **这个变量中。

当 Puppet 运行结束后，Astute 获取 Puppet 运行结果的概要文件，并将结果汇报至 Nailgun。用户可以通过 Fuel Web 或者 CLI 来查看运行的进度和结果。

Fuel 还提供 **puppet-pull** 脚本，开发者可以使用这个脚本来手动从 Master 同步 manifest 并在节点上运行。

Astute 还会完成一些其他的操作，例如：

* 生成和上传 SSH key
* 使用 **net\_verify.py** 来验证网络的连通性
* 部署完成后上传 CirrOS 镜像到 Glance 中
* 当有新的节点加入时，更新所有节点的 **/etc/hosts**
* 当 Ceph 节点部署后更新 RadosGW map

当一个环境被删除时，Astute 通过 Mcollective agent 来删除所有点的的启动删除，并重启节点，这些节点会通过 bootstrap 镜像重新引导，可以用于新环境的部署。
