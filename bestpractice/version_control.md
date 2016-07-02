# 提交规范

> 注意： 本文仅是建议，非强制要求。

Puppet Modules使用git做版本控制工具，因此我们这里不会去重复git文档中的基础知识点。

我们这里主要提及的有以下几点：

  - 每次commit中应该包含哪些代码？
  - commit message的格式应该怎么写？
  - 代码提交是否应该和其他系统关联？


> 代码规范的程度体现了一个程序员的素质，映射出一家公司对待技术的态度。

那么代码规范体现在以下几点：
   - 使用版本控制工具进行管理
   - 符合一门语言的通用代码风格要求
   - 完整的文档，包含commit消息，代码注释，架构文档等
   - 不使用花式技巧

接下来，着重介绍代码



# 1.提交规范说明

- 每次提交只包含相关的Puppet代码逻辑和单元测试
- 第一行是commit的简短描述
- 在第一行和后面段落之间插入一个空行
- 提供针对本次commit的详细描述（可选）
- 本次提交的类型,Type是:(BF|NF|RF|OT|BugFix|NewFeature|ReFactor|Other)
- 关联JIRA issue，Jira: link链接
- 每行不能超过72个字符

## 1.1 Type类型说明

| **Type类型** | 全称 | 说明 |
| --- | --- | --- |
| BF | BugFix | 漏洞，问题修复 |
| NF | NewFeature | 新特性开发 |
| RF | ReFactor | 代码重构，架构重构，文档补充等 |
| OT | OTher | 其他类型，例如，添加.gitreview，添加.gitignore，添加mailmap等与项目无关操作 |

## 1.2 Label类型说明

| **Label类型** | 全称 | 说明 |
| --- | --- | --- |
| Type | Commit-Type | 必填，本次提交的类型 |
| Jira | Jira-Link | 必填，Jira的链接 |
| FC | Forward Compatibility | 可选，是否向前兼容，原则上不允许不向前兼容的代码 |
| CT | CriTicality | 可选，危险程度，一般只适用于线上变更项目 |

## 1.3 格式样例

```git
commit 7c027d40e2b616ba57f7c69f8162a6311461a566
Author: [removed]
Date:   Fri Aug 28 10:14:28 2015 -0700
    Ensure setuptools is somewhat recent
 
    Due to bugs in older setuptools version parsing
    we need to set a relatively new version of setuptools
    so that parsing works better (and/or correctly).
 
    This seems especially important on 2.6 which due to
    a busted setuptools (and associated pkg_resources) seems
    to be matching against incorrect versions.
 
    Type: BF
    Jira: DEVOPS-453
    Change-Id: Ib859c7df955edef0f38c5673bd21a4767c781e4a
```



