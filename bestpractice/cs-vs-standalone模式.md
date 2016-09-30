# 服务器/客户端 vs 单机模式

## Standalone(单机模式)

Puppet可以很容易地以单机模式下执行配置管理的工作。在这种模式下Puppet将会在本地    编译并且执行catalog，无需和Puppet Server通讯，适合一些简单的配置管理任务或者Puppetserver节点的自部署工作。

`puppet`命令支持多种使用方式，可以在终端下输入:
```bash
   puppet -v apply test.pp  # 最常用的使用方式
   puppet apply -e 'include ::ntp::server'  #执行一段puppet代码
   puppet apply --catalog catalog.json #指定执行一个catalog文件
```

## Client/Server(客户端/服务器端模式)

C/S模式是大家都熟悉的运行模式。在这种模式下，Puppet agent端被部署在了被管理的服务器上，Puppet master(server)端部署在管理服务器上。

TODO：C/S流程图


## 如何选择？

脱离业务场景去谈孰优孰劣都是不合时宜的。

### 适合单机模式的场景
如果是个人开发环境的配置管理，少数服务器的配置管理，以及业务逻辑比较简单的情况下，推荐使用单机模式，简单方便。

### 适合C/S模式的场景

在涉及正式线上环境的情况下，我们推荐是C/S模式。优势非常明显：

#### 1. 安全管理和权限控制
   
配置管理代码中其实包含了大量的敏感信息，其一旦发生泄漏或者权限被越界，就发导致严重的安全问题。

在单机模式下，每台服务器都会拿到完整的puppet代码和hiera数据，试想一台Apache服务器上放着MySQL服务器的配置管理代码和管理员用户名密码是何其危险的事情！

另外，在CS模式下，agent端和server端通过SSL进行通信，并且可以根据节点的FQDN做细粒度的控制，试想一台伪造自己是数据库服务器的节点，在向服务器端请求就轻而易举地拿到了数据库节点的catalog也是非常危险的事情。

#### 2.支持高级特性

在C/S模式下，通过开启storeconfigs参数，配合PuppetDB，可以使用Puppet中诸如exported_resources等高级特性。


#### 3.集中式管理

在单机模式下，若要批量执行puppet配置管理任务，一般选择使用集群管理工具例如clustershell等做批量的变更操作。
在C/S模式下，agent既可以定期地从server端获取最新的catalog，也可以由Server端主动地发送更新指令。
此外，在C/S模式下，agent端在完成配置应用的任务后，可以发送report给Server端或者其他服务器。

 


