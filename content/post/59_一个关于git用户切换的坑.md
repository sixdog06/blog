---
title: "一个关于git用户切换的坑"
date: 2021-07-28
draft: false
toc: true
categories: ["杂谈"]
tags: ["git"]
---

这几天公司培训, 要做一个培训的项目, 因为不想远程连接工位的电脑开发, 所以在自己的电脑上配置好了环境, 但是遇到了一个git环境切换无法push的坑.

因为用ssh clone项目的时候总是被端口阻止, 所以我用的http的方式clone. 在push的时候发现报了一个错误`remote: GitLab: Author 'myname@email.com' is not a member of team`, 我发现邮箱的地址是我github的用户地址. 于是我用`git config user.email "myname@companymail.com"`配置了邮箱的地址, 然后再次push. 这个时候依然报了`remote: GitLab: Author 'myname@email.com' is not a member of team`.

明明本地配对了为什么还是不能push呢, 我首先想到是全局的环境配置错了, 所以用`git config --global user.email "myname@companymail.com"`配置了全局的公司邮箱, 发现还是无法push, 这个时候其实已经掉进坑了. 因为这个问题其实根本不在git到底是用的global还是local环境的配置. git文档说得很清楚: **When reading, the values are read from the system, global and repository local configuration files by default.** local的config本来就是优先级最高的.

所以这个时候其实我的`user.name`和`user.email`都已经配置好了, 但是在前面的commit的时候, 我的user信息是依然我自己github的user信息. 那么就需要用`git commit --amend --reset-author`把之前已经有的commit更改为公司的user提交的.

最后再push, 终于成功了!

## 参考
1. [Git push failed with error: “GitLab: Author not member of team”](https://stackoverflow.com/questions/56177751/git-push-failed-with-error-gitlab-author-not-member-of-team)
2. [git-config](https://git-scm.com/docs/git-config)