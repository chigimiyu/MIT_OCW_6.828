# lab1
## lab内容说明
总共分为三部分:
1. 熟悉x86的汇编语言,qemu的x86模拟器以及电脑开机启动的过程
1. 学习kernel里的boot loader
1. 学习最简单的kernel
## Execrise 1--熟悉x86的语法
1. Simulating the x86
	这个就是打开控制台输入相应的命令,没什么好说的.
1. The PC's Physical Address Space
	这里要注意的是32位系统的内存空间为了向16位系统兼容的一个设置,也就是0x00000000~0x00100000这1MB是留出来的.它的构造是在16位系统的20根地址总线的8086背景下的.除了BIOS还有一些16位外接设备.32位的外接设备则放在内存空间的最上端.也就是0xFFFFFFFF往下走.
1. The ROM BIOS
从```[f000:fff0] 0xffff0: ljmp $0xf000,$0xe05b```可以看到第一条指令的地址是0xf000:0xfff0;此时还是实模式,也就是说其物理地址是0x000ffff0.为什么是这么长是因为这里是32位系统,也就是32根地址总线,也就是8个十六进制数长的数字串来表示.(地址总线的根数决定了的最大内存的大小.)也就是说这时还在读取BIOS指令执行阶段.
## Execrise 2--熟悉gdb的debug语法
用si慢慢的查看,可以看到
1. BIOS执行完后就会查找位于boot sector的boot loader加载进内存,并把控制权给它.
1. 从boot/boot.s和boot/main.c一开始的说明:
> 1. This program(boot.S and main.c) is the bootloader.
	2. (boot.s)Start the CPU: switch to 32-bit protected mode, jump into C.
	3. (main.c)This a dirt simple boot loader, whose sole job is to boot an ELF kernel image from the first IDE hard disk.
就可以知道boot loader的功能主要是两个:1. 将内存模式转化成实模式到32位的保护模式(boot.s实现)	2. 通过IDE disk device register用特殊的I/O命令,从硬盘里读取kernel的内容到内存(main.c实现).
1. 而两个文件的整合就是obj/boot/boot.asm.并且这一段代码放在了物理地址0x7x00处.也就是hard disk的第一个扇区.
## Execrise 3 
1. b *0x7c00然后c运行至物理地址0x7c00处,这里是boot loader开始执行的地方.
1. 通过x/Ni可以看到反汇编命令,一路下来几乎与boot.s是一致的,除了在
```
  #这是boot.s的部分
  movw    $PROT\_MODE\_DSEG, %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS
  movw    %ax, %ss                # -> SS: Stack Segment
  # Set up the stack pointer and call into C.
  movl    $start, %esp
  call bootmain
  #============================================================
  #这是通过gdb看到的部分
   0x7c32:	mov    $0xd88e0010,%eax
   0x7c38:	mov    %ax,%es
   0x7c3a:	mov    %ax,%fs
   0x7c3c:	mov    %ax,%gs
   0x7c3e:	mov    %ax,%ss
   0x7c40:	mov    $0x7c00,%sp
   0x7c43:	add    %al,(%bx,%si)
   0x7c45:	call   0x7d13
```
可以看到 movw %ax, %ds 没有执行,然后还多了一行add %al,(%bx,%si).为什么,不知道
1. 慢慢往下走可以看到call bootmain就是call 0x7d13,但是真的执行时又是call 0x7d15了. 
```
   0x7d15:	push   %ebp
   0x7d16:	mov    %esp,%ebp
   0x7d18:	push   %esi
   0x7d19:	push   %ebx
   0x7d1a:	push   $0x0
   0x7d1c:	push   $0x1000
   0x7d21:	push   $0x10000
   0x7d26:	call   0x7cdc
```
前面两个操作是定例,也就是在调用子程序时把当前程序的信息压入栈中.并更新当前栈顶信息.

回答下列问题:
+ Q1:At what point does the processor start executing 32-bit code? What exactly causes the switch from 16- to 32-bit mode?
	A1:.code32后面的代码.因为.code32是AT&T语法的伪指令,表示用32位编译. 至于为什么要从16位模式到32位模式,因为不转换成32位保护模式,我们没法读取到内存1Mb以外的数据,bootloader放在了0x7c00处(还处于1MB范围内),但kernel已经超出1MB范围了.想要加载kernek就需要转换.
+ Q2:What is the last instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?
	A2:boot loader的最后一条指令7d6b:call \*0x10018,根据boot.asm可以知道,这条指令是从ELF header中找到的program的entry point,调用执行.这样就算是开始加载操作系统了.那么通过可以知道boot loader最后一条是跳到0x10018所存指针指向的地址,查看0x10018附近的值,可以看到就是0x0010000c.
```	
(gdb) x/10x 0x10018
0x10018:	0x0010000c	0x00000034	0x00013cdc	0x00000000
``` 
那么查看0x0010000c所存的指令是:
```
(gdb) x/10i 0x0010000c
   0x10000c:	movw   $0x1234,0x472
   0x100015:	mov    $0x110000,%eax
   0x10001a:	mov    %eax,%cr3
   0x10001d:	mov    %cr0,%eax
   0x100020:	or     $0x80010001,%eax
   0x100025:	mov    %eax,%cr0
   0x100028:	mov    $0xf010002f,%eax

```
movw $0x1234,0x472. 

+ Q3:Where is the first instruction of the kernel?
	A3: 当然是上面说的0x10000c.
+ Q4:How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk?Where does it find this information?
	A4: elf文件里有信息.从obj/kern里打开命令行,然后输入objdump -h kernel
```
kernel：     文件格式 elf32-i386

节：
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00001871  f0100000  00100000  00001000  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .rodata       00000714  f0101880  00101880  00002880  2**5
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .stab         000038d1  f0101f94  00101f94  00002f94  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  3 .stabstr      000018bb  f0105865  00105865  00006865  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  4 .data         0000a300  f0108000  00108000  00009000  2**12
                  CONTENTS, ALLOC, LOAD, DATA
  5 .bss          00000644  f0112300  00112300  00013300  2**5
                  ALLOC
  6 .comment      00000034  00000000  00000000  00013300  2**0
                  CONTENTS, READONLY
```
对每一个program都有记载,先不要管每一个是什么意思,只需要知道在这里信息由elf的各个头给出了.

## Execrise 4--理解pointers.c
编译后运行可得:
>
1: a = 0x7ffde3777680, b = 0x250b010, c = 0x1
2: a[0] = 200, a[1] = 101, a[2] = 102, a[3] = 103
3: a[0] = 200, a[1] = 300, a[2] = 301, a[3] = 302
4: a[0] = 200, a[1] = 400, a[2] = 301, a[3] = 302
5: a[0] = 200, a[1] = 128144, a[2] = 256, a[3] = 302
6: a = 0x7ffde3777680, b = 0x7ffde3777684, c = 0x7ffde3777681

1. 第一条输出时,a,b,c都是指针,那么输出来的值也就是地址.因为1的时候还没有初始化,那么其值应该是随机的.至于为什么c为1,a和b的长度不一样.还不知道,或者只是我个人的电脑系统的一些处理.
1. 第三条要注意的是3[c]也可以表示c[3]
1. 第五条一开始我犯了一个错误,就是我把数字的存放顺序弄错了.数字的高位要放在地址的高位上.也就是说一个0000190在内存中的存放(随着地址序号增加)是90010000.具体查看[Lab 1 Exercise 4](https://www.cnblogs.com/fatsheep9146/p/5216735.html)

### Execrise 5-- 了解boot loader的link address
1. boot loader加载kernel实际上就是加载一个可执行文件然后执行.这个实验使用的可执行文件格式是ELF.
1. ELF的全程是Executble and linkable files,大致格式是一个ELF header然后跟着一列Program header.我们一个个地把program加载进内存,然后执行.因此对于每一个program都有一个linker address和load address.前者定义了该文件在何处执行,后者定义了该program加载进内存的何处.至于为什么要分成两部分,后面再说.
1. 首先是没有改变,也就是boot loader的link address写的是0x7c00.可以看到
```
b *0x7c00
Breakpoint 1 at 0x7c00
[   0:7c00] => 0x7c00:	cli
...... 
[   0:7c2d] => 0x7c2d:	ljmp   $0x8,$0x7c32
```
然后改变boot/makefrag里的-Ttext 0x7c00为0x7c04.同样在0x7c00处设置断点:
```
[f000:fff0]    0xffff0:	ljmp   $0xf000,$0xe05b
0x0000fff0 in ?? ()
[   0:7c00] => 0x7c00:	cli
[   0:7c2d] => 0x7c2d:	ljmp   $0x8,$0x7c36
```
可以看到boot loader的开始地址依然在0x7c00,然后在ljmp的跳转时,发生了改变.从0x7c32变成了0x7c36,也就是往高处移了4位.这就验证了我们把link address从0x7c00移到0x7c04.
```
\# 继续用si看看ljmp   $0x8,$0x7c36会执行什么命令.
[f000:e05b]    0xfe05b:	cmpl   $0x0,%cs:0x6c48
\# 然而,ljmp执行后应该是执行下列命令,也就是boot.S里的movw    $PROT\_MODE\_DSEG, %ax    # Our data segment selector
0x7c32:	mov    $0xd88e0010,%eax
```
这其实就发生了错误.这是因为BIOS始终把boot loader加载到0x7c00处,然而编译器会根据link address来计算各指令的偏移.

1. 一般来说,link address和load address是一样的,比如boot loader
```
\# 执行命令--objdump -h obj/boot/boot.out
\# 1. "VMA" (or link address) and the "LMA" (or load address)
obj/boot/boot.out：     文件格式 elf32-i386

节：
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00000186  00007c00  00007c00  00000074  2**2
                  CONTENTS, ALLOC, LOAD, CODE
  1 .eh_frame     000000a8  00007d88  00007d88  000001fc  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .stab         00000720  00000000  00000000  000002a4  2**2
                  CONTENTS, READONLY, DEBUGGING
  3 .stabstr      0000088f  00000000  00000000  000009c4  2**0
                  CONTENTS, READONLY, DEBUGGING
  4 .comment      00000034  00000000  00000000  00001253  2**0
                  CONTENTS, READONLY
```
但是加载kernel不一样,它link address和load address不一样.
```
\# 执行命令--objdump -h obj/kern/kernel
obj/kern/kernel：     文件格式 elf32-i386
节：
Idx Name          Size      VMA       LMA       File off  Algn
  0 .text         00001871  f0100000  00100000  00001000  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .rodata       00000714  f0101880  00101880  00002880  2**5
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .stab         000038d1  f0101f94  00101f94  00002f94  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  3 .stabstr      000018bb  f0105865  00105865  00006865  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  4 .data         0000a300  f0108000  00108000  00009000  2**12
                  CONTENTS, ALLOC, LOAD, DATA
  5 .bss          00000644  f0112300  00112300  00013300  2**5
                  ALLOC
  6 .comment      00000034  00000000  00000000  00013300  2**0
                  CONTENTS, READONLY
```
### Execrise 6
1. 首先在BIOS进入boot loader处设置断点:
```
b *0x7c00
Breakpoint 1 at 0x7c00
(gdb) c
Continuing.
[   0:7c00] => 0x7c00:	cli
Breakpoint 1, 0x00007c00 in ?? ()
(gdb) x/8x 0x100000
0x100000:	0x00000000	0x00000000	0x00000000	0x00000000
0x100010:	0x00000000	0x00000000	0x00000000	0x00000000
```
可以看到此时0x100000处什么都没有,这是因为此时boot loader才刚开始执行,还没有从real模式编程protected mode,那么其寻址能力就只能是20根地址线所限制的1M,也就是0x00000~0xfffff.此时,这里绝对是不能有任何数据的.
然而再在boot loader进入kernel处加断点(由main.c的说明以及obj/boot.asm知道开始进入kernel的位置在0x7c6b,因为bootmain函数的逻辑是,先读取elf header然后加载program section,然后从e_entry处开始执行第一个section.)
```
(gdb) b *0x7d6b
Breakpoint 1 at 0x7d6b
(gdb) c
Continuing.
The target architecture is assumed to be i386
=> 0x7d6b:	call   *0x10018

Breakpoint 1, 0x00007d6b in ?? ()
(gdb) x/8x 0x100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
```
可知此时0x100000处已经开始加载kernel了.其实也可以从理论上推出来,因为我们从上面的execrise 5处知道kernel的LMA也就是加载地址是0x100000,也就是说kernel的.text secion会加载到地址0x100000处.

### Execrise 7
1. 一般来说,kernel会在比较高的虚拟地址处运行,这样就可以把低地址给用户的软件(原因lab2再说).比如说在0xf0100000处运行,然而很多机器并没有这么大的物理内存.于是我们就需要运用处理器的内存管理硬件将0xf0100000映射到物理地址0x00100000,也就是boot loader加载kernel的地方.也就是说虽然操作系统会被运行在内存地址很高的地方,但实际上是放在电脑内存1Mb处.
1. entry_pgdir要把虚拟地址0xf0000000~0xf0400000以及0x00000000~0x00400000都映射到物理地址0x00000000~0x00400000
1. 通过上面execrise 6我们知道boot loader最后的程序是call *0x10018,而x/8x 0x10018得到0x10018处的数据为0x0010000c.于是用x/8i 0x10000c,得到
```
(gdb) x/8i 0x10000c
   0x10000c:	movw   $0x1234,0x472
   0x100015:	mov    $0x110000,%eax
   0x10001a:	mov    %eax,%cr3
   0x10001d:	mov    %cr0,%eax
   0x100020:	or     $0x80010001,%eax
   0x100025:	mov    %eax,%cr0
   0x100028:	mov    $0xf010002f,%eax
   0x10002d:	jmp    *%eax
```
于是通过si 5后,再执行一下命令
```
(gdb) x/8x 0x100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
(gdb) x/8x 0xf0100000
0xf0100000 <_start+4026531828>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100010 <entry+4>:	0x00000000	0x00000000	0x00000000	0x00000000

```
可以看到此时虽然把kernel加载到了0x100000处,但因为还没有执行各个section,因此此时还不存在0xf0100000映射到0x100000处.
然后我们第一次执行0x100025:	mov    %eax,%cr0,得到一下结论:
```
(gdb) si
=> 0x100025:	mov    %eax,%cr0
0x00100025 in ?? ()
(gdb) x/8x 0xf0100000
0xf0100000 <_start+4026531828>:	0x00000000	0x00000000	0x00000000	0x00000000
0xf0100010 <entry+4>:	0x00000000	0x00000000	0x00000000	0x00000000
(gdb) x/8x 0x100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
(gdb) si
=> 0x100028:	mov    $0xf010002f,%eax
0x00100028 in ?? ()
(gdb) x/8x 0x100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
(gdb) x/8x 0xf0100000
0xf0100000 <_start+4026531828>:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0xf0100010 <entry+4>:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
(gdb) x/16x 0x100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
0x100010:	0x34000004	0x0000b812	0x220f0011	0xc0200fd8
0x100020:	0x0100010d	0xc0220f80	0x10002fb8	0xbde0fff0
0x100030:	0x00000000	0x110000bc	0x0056e8f0	0xfeeb0000
```
可以看到当执行完mov    %eax,%cr0时,0xf0100000与0x100000并没有对应,而是等到执行了下面一个指令以后才开始了虚拟地址与物理地址的映射.这个在Appedix B里就说了,只有当一个段寄存器加载了一个新值,然后处理器通过阅读gdt才能改变它的段设置.我猜是因为设置cr0最后改变的是gdt里的属性,然后才决定了虚拟地址与物理地址的映射.




### Execrise 8-- 补充完整print octal number的代码.

##参考资料
+ 文中给的参考资料:
1. 版本控制--git,[新手版](https://www.kernel.org/pub/software/scm/git/docs/user-manual.html),如果你学过其它版本控制,可以参考[这里](http://eagain.net/articles/git-for-computer-scientists/)
1. x86汇编语言,目前汇编语言有两种"解释器":NASM(用Intel语法)和GUN(用AT&T语法,也就是本实验要用的)--[AT&T语法与Intel语法的区别](http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html)
以及一些指令集和处理器架构的网站,暂且不需要.
1. [qemu模拟器官网](https://www.qemu.org/)
1. [debug工具--GDB](http://www.gnu.org/software/gdb/)
+ 以下是本人参考的资料:
1. [操作系统篇-浅谈实模式与保护模式](https://www.cnblogs.com/chenwb89/p/operating_system_002.html)
1. [Lab 1 Exercise 4](https://www.cnblogs.com/fatsheep9146/p/5216735.html)

