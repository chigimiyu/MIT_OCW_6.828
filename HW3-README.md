---
title: HW3_README
date: 2018-01-23 12:15:31
tags: MIT-6.828, 计算机原理, C
categories: MIT-6.828
---
## 实验准备
1. 从github上下载xv6-public的代码: 
1. 然后在代码根目录下打开控制台,输入:
``` make qemu-nox-gdb```
1. 这里的gdb不能直接用make gdb打开,需要先添加一个.gdbinit文件到用户目录(~/.gdbinit),里面写上add-auto-load-safe-path /home/extraSpace/jos/xv6-public/.gdbinit
上面的路径是我xv6-public的路径,这些操作会在你用gdb的时候弹出提示,或者你直接根据我的操作稍作修改.

## 实验内容
### part One:
这里需要在每一个系统调用的时候打印出系统调用的名字和返回的值.例子如下:
```
fork -> 2
exec -> 0
......
```
提示中要你看看syscall.c/syscall()函数.先看看下面这个函数:
```
static int (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
};

```
> In plain English, syscalls is a static array of pointer to function taking void and returning int. The array indices are constants and their associated value is the corresponding function address.[这是stackoverflow的一个答案](https://stackoverflow.com/questions/26023270/c-function-explanation)
上面的答案说得很清楚: 首先可以把这个当作一个数组初始化对待,也就是说syscall[SYS_fork]的值是sys\_fork. 而至于为什么[SYS_fork]之类的可以做下标是因为,在syscall.h里有这样的申明:
```
#define SYS_fork    1
#define SYS_exit    2
......
```
sys\_fork是一个函数名,在这里就是代表该函数的地址.于是syscall就是根据不同的下标返回不同的函数地址.syscall[index]()就可以表示执行该函数了.最大的不同无非是这里的数组是一个指针,而且是指向函数的指针.
