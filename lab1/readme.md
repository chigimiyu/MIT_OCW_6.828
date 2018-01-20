# lab1
## lab内容说明
总共分为三部分:
1. 熟悉x86的汇编语言,qemu的x86模拟器以及电脑开机启动的过程
1. 学习kernel里的boot loader
1. 学习最简单的kernel

----------------------------------------------------------------------------------------------
## Execrise 1--熟悉x86的语法
1. Simulating the x86
	这个就是打开控制台输入相应的命令,没什么好说的.
1. The PC's Physical Address Space
	这里要注意的是32位系统的内存空间为了向16位系统兼容的一个设置,也就是0x00000000~0x00100000这1MB是留出来的.它的构造是在16位系统的20根地址总线的8086背景下的.除了BIOS还有一些16位外接设备.32位的外接设备则放在内存空间的最上端.也就是0xFFFFFFFF往下走.
1. The ROM BIOS
从```[f000:fff0] 0xffff0: ljmp $0xf000,$0xe05b```可以看到第一条指令的地址是0xf000:0xfff0;此时还是实模式,也就是说其物理地址是0x000ffff0.为什么是这么长是因为这里是32位系统,也就是32根地址总线,也就是8个十六进制数长的数字串来表示.(地址总线的根数决定了的最大内存的大小.)也就是说这时还在读取BIOS指令执行阶段.

----------------------------------------------------------------------------------------------
## Execrise 2--熟悉gdb的debug语法
用si慢慢的查看,可以看到
1. BIOS执行完后就会查找位于boot sector的boot loader加载进内存,并把控制权给它.
1. 从boot/boot.s和boot/main.c一开始的说明:
> 1. This program(boot.S and main.c) is the bootloader.
	2. (boot.s)Start the CPU: switch to 32-bit protected mode, jump into C.
	3. (main.c)This a dirt simple boot loader, whose sole job is to boot an ELF kernel image from the first IDE hard disk.
就可以知道boot loader的功能主要是两个:1. 将内存模式转化成实模式到32位的保护模式(boot.s实现)	2. 通过IDE disk device register用特殊的I/O命令,从硬盘里读取kernel的内容到内存(main.c实现).
1. 而两个文件的整合就是obj/boot/boot.asm.并且这一段代码放在了物理地址0x7x00处.也就是hard disk的第一个扇区.

----------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------
## Execrise 4--理解pointers.c
编译后运行可得:
```
1: a = 0x7ffde3777680, b = 0x250b010, c = 0x1
2: a[0] = 200, a[1] = 101, a[2] = 102, a[3] = 103
3: a[0] = 200, a[1] = 300, a[2] = 301, a[3] = 302
4: a[0] = 200, a[1] = 400, a[2] = 301, a[3] = 302
5: a[0] = 200, a[1] = 128144, a[2] = 256, a[3] = 302
6: a = 0x7ffde3777680, b = 0x7ffde3777684, c = 0x7ffde3777681
```
1. 第一条输出时,a,b,c都是指针,那么输出来的值也就是地址.因为1的时候还没有初始化,那么其值应该是随机的.至于为什么c为1,a和b的长度不一样.还不知道,或者只是我个人的电脑系统的一些处理.
1. 第三条要注意的是3[c]也可以表示c[3]
1. 第五条一开始我犯了一个错误,就是我把数字的存放顺序弄错了.数字的高位要放在地址的高位上.也就是说一个0000190在内存中的存放(随着地址序号增加)是90010000.具体查看[Lab 1 Exercise 4](https://www.cnblogs.com/fatsheep9146/p/5216735.html)

----------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------
### Execrise 8-- 补充完整print octal number的代码.
1. Explain the interface between printf.c and console.c.Sepcificaly,what function does console.c export? how is this function used by printf.c?
首先看到kern/printf.c的主要逻辑是cprintf->vcprintf->vprintfmt+putch->cputchar,从代码前面的注释也了解到,printf.c的作用就是使用lib/printfmt里的vprintfmt()和kern/console.c里的cputchar()函数.
+ kern/console.c里的cputchar(),其调用链是:cputchar-> con\_put->cserial\_putc(c);+lpt\_putc(c);+ cga\_putc(c);也就是说,要把一个char输出到控制台,需要三步,首先是输出到串行I/O设备,然后是输出到并行设备,最后就是输出到cga设备,也就是显示屏.至于为什么需要前面两个输出,我也不知道.
+ lib/printfmt里的vprintfmt可以看到是通过一个无限循环一个char一个char的读取,如果遇到'\0'就return,遇到'%'就进行转义处理.
+ 所以,这三个文件的逻辑是,console.c和printfmt提供接口给printf.c用.
1. Explain the following from console.c
```
// What is the purpose of this?
if (crt\_pos >= CRT\_SIZE) { //当当前要写入的位置大于显示屏的最大位置
	int i;
	memmove(crt\_buf, crt\_buf + CRT\_COLS, (CRT\_SIZE - CRT\_COLS) * sizeof(uint16\_t)); // 把当前显示屏上的字符都往上提一排,第一排会被覆盖掉.
	for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
		crt_buf[i] = 0x0700 | ' ';     //把最后一排用空格填充.
	crt\_pos -= CRT\_COLS;    //当前的光标位置是之前光标位置往上走一排.
	}
```
crt_pos是显示在显示屏的当前位置,CRT_SIZE是显示屏的大小,crt_buf是一个uint16_t的数组,存放要显示的字符.CRT_COLS是显示屏的宽度,一半就是80.
void *	memmove(void *dst, const void *src, size_t len);这是在string.h里找到的,根据其参数名大概能猜到memmove的作用是把第二个参数里的字符移动第三个参数那么长到第一个参数去.crt_buf表示当前在显示屏的字符的第一个的地址,于是crt_buf+CTR_COLS的作用是指向第二排第一个字符.CRT_SIZE-CRT_COLS表示显示屏能显示的总数量减去一排的字符数,也就是去掉一排后,该显示屏还能存放的字符数.
+ 第一个笔记: cga_putc(int c)用的参数是int,为什么最后表示字符的时候要用uint16_t? 还是说因为int c里会包含有颜色等其余格式信息,我们在之前的c & 0xff的意思是获取c中表示字符的信息,舍弃表示格式的信息? 而这字符本身的信息与格式信息的存储是一半一半,各占16bit? 那么就不难解释0x0700 | ' '的意思了.可以看到前面的代码
```
if (!(c & ~0xFF))
		c |= 0x0700;
```
这里说如果没有属性设置,就设置为黑白.也就是说c|0x0700是使得c的信息里带上黑白的设定.那么同理' '|0x0700也是使得空格带上黑白的设定.
+ 第二个笔记: c&~0xFF是什么意思? 这里的逻辑是c是一个int,那么它与~0xFF的与运算会以int来计算,那么~0xFF换算成int也就是0xFF00,c&0xFF00的作用是获得c中的高地址段的数据,也就是表示格式信息的数据.

1. Trace the execution of the following code step-by-step:
```
int x=1,y=3,z=4;
cprintf("x %d,y %x,z %d\n",x,y,z);
```
+ 第一个问题当然是这个怎么执行?
注意到在monitor.c里有一个函数
```
int mon_backtrace(int argc, char **argv, struct Trapframe *tf){
	// Your code here.
	return 0;
}
```
把要执行的命令写道这里,并设置好断点:b kern/monitor.c:61
```
(gdb) b kern/monitor.c:61
Breakpoint 1 at 0xf0100774: file kern/monitor.c, line 61.
(gdb) c
Continuing.
The target architecture is assumed to be i386
=> 0xf0100774 <mon_backtrace+6>:	push   $0x4

Breakpoint 1, mon_backtrace (argc=0, argv=0x0, tf=0x0) at kern/monitor.c:62
62		cprintf("x %d,y %x,z %d\n",x,y,z);
(gdb) si
=> 0xf0100776 <mon_backtrace+8>:	push   $0x3
0xf0100776	62		cprintf("x %d,y %x,z %d\n",x,y,z);
(gdb) si
=> 0xf0100778 <mon_backtrace+10>:	push   $0x1
0xf0100778	62		cprintf("x %d,y %x,z %d\n",x,y,z);
(gdb) x/8i
   0xf010077a <mon_backtrace+12>:	push   $0xf0101b4e
   0xf010077f <mon_backtrace+17>:	call   0xf010090b <cprintf>
   0xf0100784 <mon_backtrace+22>:	mov    $0x0,%eax
   0xf0100789 <mon_backtrace+27>:	leave
   0xf010078a <mon_backtrace+28>:	ret
   0xf010078b <monitor>:	push   %ebp
(gdb) si 2
=> 0xf010077f <mon_backtrace+17>:	call   0xf010090b <cprintf>
0xf010077f	62		cprintf("x %d,y %x,z %d\n",x,y,z);
(gdb) si
=> 0xf010090b <cprintf>:	push   %ebp
cprintf (fmt=0xf0101b4e "x %d,y %x,z %d\n") at kern/printf.c:27
27	{
(gdb) x/17i
   0xf010090c <cprintf+1>:	mov    %esp,%ebp
   0xf010090e <cprintf+3>:	sub    $0x10,%esp
   0xf0100911 <cprintf+6>:	lea    0xc(%ebp),%eax
   0xf0100914 <cprintf+9>:	push   %eax
   0xf0100915 <cprintf+10>:	pushl  0x8(%ebp)
   0xf0100918 <cprintf+13>:	call   0xf01008e5 <vcprintf>
   0xf010091d <cprintf+18>:	leave
   0xf010091e <cprintf+19>:	ret 
......

(gdb) si
=> 0xf0100918 <cprintf+13>:	call   0xf01008e5 <vcprintf>
0xf0100918	32		cnt = vcprintf(fmt, ap);
(gdb) si
=> 0xf01008e5 <vcprintf>:	push   %ebp
vcprintf (fmt=0xf0101b4e "x %d,y %x,z %d\n", ap=0xf010ff04 "\001")
    at kern/printf.c:18
18	{
(gdb) si
=> 0xf01008e6 <vcprintf+1>:	mov    %esp,%ebp
0xf01008e6	18	{


```
可以看到进入cprintf后,fmt=0xf0101b4e,逻辑就是先把cprintf的参数从右到左的压入栈中,然后调用cprintf.然后是汇编语言里常规的子程序调用的步骤,先把%ebp作为父程序的最低地址压入栈,然后更新%ebp记录当前这个子程序的最低地址. 然后可以看到ap=0xf010ff04.我们知道在call   0xf01008e5 <vcprintf>之前是cprintf函数变量的申明定义步骤,也就是这几个汇编指令做的事情: 
```
0xf010090b <cprintf>:	push   %ebp
0xf010090c <cprintf+1>:	mov    %esp,%ebp
0xf010090e <cprintf+3>:	sub    $0x10,%esp
0xf0100911 <cprintf+6>:	lea    0xc(%ebp),%eax
0xf0100914 <cprintf+9>:	push   %eax
0xf0100915 <cprintf+10>:	pushl  0x8(%ebp)
```
第1,2步是正常的子程序调用的入栈和更新,第三步是修改栈顶的位置(%esp我们是指向一个栈顶,每一次入栈都伴随着%esp的减小,这一步是为cprintf预留局部变量空间也就是0x10*1byte也就是16byte(十进制)).第4,5步是把%ebp里的数据+0xc所表示的结果压入栈中(不是内存指向的数据, 而是内存地址)也就是把第二个参数ag入栈(至于为什么是0xc(%ebp),很简单,因为vcprintf的参数是来源于cprintf函数里的传递,因此要通过内存地址偏移来获取,而不是像调用cprintf一样直接push立即数.那么慢慢往前推,之前要压入了%ebp是4bytes,然后push了fmt又移动了4bytes,然后虽然再push的是0x1这些4bit长度的数据,但是因为栈的数据单位是1byte,所以push了三个立即数,应当是偏移3bytes.因此4+4+3=0xb,因此是读取0xc(%ebp).
),最后一步是push一个longword,其实也就是push了上面的参数fmt,也就是vprintf的第一个参数.逻辑是和调用cprintf一样的.
那么可以回答问题了,fmt指向的是"x %d,y %x,z %d\n"这句话的地址.而ap指向的是x,y,z这个变参.
+ list call to cons\_putc,va\_arg and vcprintf
老办法,设置断点慢慢看,这次的断点设在,一开始我设置在kern/console.c:458,但是qemu有一些系统要输出的字
```
6828 decimal is 15254 octal!
entering test_backtrace 5
entering test_backtrace 4
entering test_backtrace 3
entering test_backtrace 2
entering test_backtrace 1
entering test_backtrace 0
```
用大概用c 150的样子慢慢逼近我们要输出的,可以得到其c的值依次是
|序号|值|代表的字符ASCII码|
|1  |120|'x'|
|2	|32	|' '|
|3	|49	|'1'|
|4	|44	|','|
|5	|32	|' '|
|6	|121|'y'|
|7	|32	|' '|
|8	|51	|'3'|
|9	|44	|','|
|10	|32	|' '|
|11	|122|'z'|
|12	|32	|' '|
|13	|52	|'4'|
|14	|10	|'\n'|
也就是输出来了.
+ 至于va_arg在inc/stdarg.h里,也就是\__builtin\_va\_arg(ap, type),这个函数是C的一个内建函数.其原理是ap指向一个变长参数,然后根据type返回符合条件的最前面的参数,然后把ap指向后一个参数.
这里主要让我们知道的是x86是little-endian.也就是数字的低位放在低地址处,高位放在高地址处.

+ Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?
把vcprintf,vprintfmt以及后面要调用的多参数函数的参数顺序都逆序一下.

### Execrise 9
做这个练习之前,先来整理一下思路.我们打开虚拟机,BIOS会开始检查各个外设是否正常,然后找到可执行扇区,并把可执行扇区加载到内存0x7c00处,然后把控制权给boot loader. boot loader由boot.S和main.c两个文件组成,其逻辑是:boot.S从实模式转换到保护模式,然后调用main.c里的bootmain函数.这个函数用来读取kernel文件.这个实验里的kernel文件采取的是ELF格式,也就是由一个ELF header和programe Header Table,然后就是一系列的program sections,来描述kernel的功能.boot loader把kernel从内存0x00100000开始加载,也就是BIOS的上面.然后通过memory management hardware把虚拟地址0xf0100000映射到物理地址0x00100000处.
然后把kernel的每一个section都加载完了以后,通过((void (*)(void)) (ELFHDR->e\_entry))();这个命令,调用entry.S这个汇编命令(至于为什么ELFHDR->e\_entry就是执行entry.s里的命令以后再说).执行entry.s从\_start开始,而\_start其实是entry,只不过entry里的地址是link address,而真正要执行的时候是要指向其load address执行的(这里用到RELOC(x)).这里就有.text和.data两个部分,.text里的代码暂时把0xf0100000~0xf0400000映射到0x00100000~0x00400000中.然后call	i386\_init,也就是调用kern/init.c里的i386_init函数,这里也就是开始初始化控制台,输出cprintf("6828 decimal is %o octal!\n", 6828);然后一个粗陋的操作系统就启动好了.

我们上面说道执行entry.s里的命令时,只说到执行.text的命令,那么.data处可以看到注释写的是 boot stack,也就是开机初始化的栈的设定.然后在上面的
```
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer

	# Set the stack pointer
	movl	$(bootstacktop),%esp

```
于是这里的设定了栈顶. 老办法,设定断点,查看.
```
(gdb) b kern/entry.S:74
Breakpoint 1 at 0xf010002f: file kern/entry.S, line 74.
(gdb) c
Continuing.
The target architecture is assumed to be i386
=> 0xf010002f <relocated>:	mov    $0x0,%ebp

Breakpoint 1, relocated () at kern/entry.S:74
74		movl	$0x0,%ebp			# nuke frame pointer
(gdb) x/8i
   0xf0100034 <relocated+5>:	mov    $0xf0110000,%esp
   0xf0100039 <relocated+10>:	call   0xf0100094 <i386_init>
   0xf010003e <spin>:	jmp    0xf010003e <spin>
   0xf0100040 <test_backtrace>:	push   %ebp
   0xf0100041 <test_backtrace+1>:	mov    %esp,%ebp
   0xf0100043 <test_backtrace+3>:	push   %ebx
```
可以看到esp的值,也就是栈顶的位置是0xf0110000.(注意把符号常数的值赋给reg是mov value reg,mov $value reg是把符号常数的地址赋值给reg.)
然后看到
```
bootstack:
	.space		KSTKSIZE
	.globl		bootstacktop   
bootstacktop:
```
根据名字可以知道,KSTKSIZE也许就是stack的大小.通过查看entry.s引入的头文件可以看到在inc/memlayout.h里有
```
#define KSTKSIZE	(8*PGSIZE)   		// size of a kernel stack
```
在inc/mmu.h里有
```
#define PGSIZE		4096		// bytes mapped by a page
```
也就是KSTKSIZE的大小是8*4096=2^15.也就是32kb.那么stack的"结束端"就是0xf0110000-2^15=0xf0110000-0x00008000=0xf0108000.

###Execrise 10 &11
首先我们看一个kernek.asm的代码,下面这一段是prologue code,也就是调用test_backtrace的前置操作.
```
f0100040:	55                   	push   %ebp   #把程序的base pointer入栈,也就是上一个程序的栈底
f0100041:	89 e5                	mov    %esp,%ebp  #更新当前程序的栈底
f0100043:	53                   	push   %ebx      #保存寄存器的状态
f0100044:	83 ec 0c             	sub    $0xc,%esp  #设置一个空间存储局部变量
```
```
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx #当执行mov %esp,%ebp时,%esp指向的是后面push   %ebx 中%ebx所存放的位置.所以此时的%ebx存放的是%ebp更前面的一点的值,然后由下面的第一步可以推测出,这个ebx就是保存的参数值. 很容易推算,push %ebp要往前移4bytes,然后call   f0100040 <test_backtrace>暗含push %eip又要往前移4bytes.于是就是在ebp的基础上往前移8bytes.
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx  #参数x入栈
f010004b:	68 20 18 10 f0       	push   $0xf0101820   #参数的地址"entering test_backtrace %d\n"入栈
f0100050:	e8 b6 08 00 00       	call   f010090b <cprintf>
```
从f0100094 <i386_init>:中看到
```
	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
```
这里的movl   $0x5,(%esp)是把立即数0x5放入esp指向的内存地址中,相当于push $0x5.但是没有自动把esp更新.这么做的原因是_我猜_可能是前面执行的父程序留出了局部变量的栈,而esp指向的是一个空 或者是因为push不支持立即数?但是后面的汇编又出现了
```
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
```
也许只能push 0?暂时不管
+ 那么调用一次函数的过程是这样的:
1. 首先把要掉用的参数入栈,
1. 然后call function,暗含这把返回函数eip入栈,其实就是call的下一条指令的地址.
1. 把上一个函数的ebp入栈
1. 因为这个例子中需要用到ebx,所以把ebx的状态入栈,后面可以恢复以供调用这个函数的父函数使用.
1. 然后就是开辟一个空间让局部变量使用.
1. 做完上面的prologue code后才正式开始函数体的执行.
那么每个函数的ebp可以通过x86.h/read_ebp函数,因为执行这个函数时,已经执行完了mov    %esp,%ebp这个指令.然后接着可以通过esp往上移(0xc+0x4+0x4)读到eip.(因为esp+0xc可以读到ebx,ebx的地址+4可以读到ebp,ebp+4可以读到eip).参数的话,一般是在eip的前面,也就是call前面的栈里.那么通过eip往前读20个btyes,每四个一记.但是这样有一个问题,esp容易变动,而ebp对于一个函数来讲,是固定的.用它来追溯会比较靠谱.于是,追溯变成了eip= ebp+4,args=ebp依次往上加.

+然后我们在kernel里看到这样一句话:
```
relocated:
	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
	f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp
```
也就是说,调用i386_init时最早push的ebp的值是0.于是我们可以以这个为标志判断是否还要继续trace stack.
+ 至于怎么获取上一个函数的ebp:执行函数体的时候,已经先执行了push %ebp  此时%esp指向%ebp的值,然后mov %esp, %ebp,也就是%ebp(姑且叫它cur %ebp)指向了上一个%ebp的值(姑且叫它pre %ebp).后面的代码都不会改变这个cur %ebp的值.因此,cur %ebp的值指向的值就是pre %ebp的值.*(cur %ebp)=pre %ebp

## Execrise 12
这里参考的是别人的代码加自己半猜半推理,不了解编译过程和原理,等完成这个课程的lab再好好研究.

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
1. [详解C中volatile关键字](https://www.cnblogs.com/yc_sunniwell/archive/2010/06/24/1764231.html)
1. [ byte为什么要与上0xff？](https://www.cnblogs.com/think-in-java/p/5527389.html)
1. [函数可变参数、va_list、va_start、va_arg、va_end](https://www.jianshu.com/p/a22f0615b92e)
1. [【Linux学习笔记】Linux C中内联汇编的语法格式及使用方法（Inline Assembly in Linux C）](http://blog.csdn.net/slvher/article/details/8864996)
1. [C语言函数调用栈(一)](http://www.cnblogs.com/clover-toeic/p/3755401.html)
