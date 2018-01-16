# boot.s补充说明
1. boot.s是最先开始的,将内存模式改为32位后移交给main.c文件.
1. 首先是enable 20A,也就是A20 gate.这是一个历史遗留问题,在8086/8088CPU时代,地址总线是20位,寻址能力也就是2^20个内存单位,一个内存单位是1Byte,也就是1MB.虽然我们用用CS:IP这两个16位寄存器表示的地址范围是0H~FFFFH:FFFFH,也就是10FFEFH,这比1MB要大.因为1MB的寻址能力是FFFFFH.但是因为只有20根地址总线,当CS:IP指向的内存地址在100000H~10FFEFH之间时,我们就通过wrap_around(也就是对FFFFFH求模),100000H实际上就是00000H,100001H实际上就是00001H.但是后来地址总线拓宽了,不止20根了.处理方式自然不一样了,但是为了向下兼容,也就是为了兼容20根地址总线的处理模式,就有了这个A20 gate机制.
1. 然后我们看到set20a.1的第一句是inb $0x64,%al:
	1. 首先是AT&T的语法是指令符 源操作数,目标操作数.并且寄存器需要加%,立即数需要加$;
	1. 然后这是一个端口读取命令.也就是in命令.对于端口I/O,不能用mov,只能用in和out.in代表要从端口读取数据,out代表要在端口写入数据.(*note*:这只是针对8086来说,也存在对端口统一编址的CPU,也就是将每一个端口当作普通的存储单元一样对待.8086采取的叫独立编址.当然各有优缺点和适用情况.)
	1. 需要注意一个外界设备的接口不一定就一一对应一个端口,一个接口可能有很多个端口.一个用来读写数据,一个用来读取接口状态等等.
	1. 这里用的inb是指以byte为单位读取.相应的inw就是以字为单位读取.
	1. 那么这条命令是要从端口号64h读取一个byte到al寄存器.端口号对应不同的外界设备,通过查表可以知道64号端口是读取状态寄存器的值.
1. testb的意思是执行逻辑与并设置flag寄存器,这里2和al寄存器做逻辑与运算也就是判断al寄存器中的第二位是不是0.jnz是当flag里的标记为为0,就往下走.不为0就跳到seta20.1去.
1. 所以seta20.1的逻辑是将0xd1送到命令寄存器(command register)里去.seta20.2是将0xdf送到数据端口(60h)去.
1. command register里的0xd1代表的是命令 PS/2 Controller 将下一个写入 0x60 的字节写出到 Output Port.然后就打开了a20 gate?
1. 所以这里的作用是在地址总线不止20条时,CS:IP指向100000H~10FFEFH之间时,依旧可以wrap_around到地址总线为20根的情况去.
1. 然后seta20.2的大概意思是往端口60写入0xdf?
1. 然后就要把实模式改为保护模式,并且要把正在使用的实模式下的地址映射成保护模式下的虚拟地址.也就是设置GDT和segment translation.不是很懂要使得它们的虚拟地址和物理地址相等是什么意思?

##具体流程
```
#include <inc/mmu.h>

# Start the CPU: switch to 32-bit protected mode, jump into C.
# The BIOS loads this code from the first sector of the hard disk into
# memory at physical address 0x7c00 and starts executing in real mode
# with %cs=0 %ip=7c00.

.set PROT_MODE_CSEG, 0x8         # kernel code segment selector
.set PROT_MODE_DSEG, 0x10        # kernel data segment selector
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # 这是AT&T的伪指令,说明接下来的汇编代码都以16位编译.
  cli                         # 关闭中断,也就是不响应任何中断.
  cld                         # String operations increment

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
  movw    %ax,%ds             # -> Data Segment
  movw    %ax,%es             # -> Extra Segment
  movw    %ax,%ss             # -> Stack Segment

  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.1

  movb    $0xd1,%al               # 0xd1 -> port 0x64
  outb    %al,$0x64

seta20.2:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.2

  movb    $0xdf,%al               # 0xdf -> port 0x60
  outb    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
  movl    %cr0, %eax
  orl     $CR0_PE_ON, %eax
  movl    %eax, %cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS
  movw    %ax, %ss                # -> SS: Stack Segment
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
  call bootmain

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin

# Bootstrap GDT
.p2align 2                                # force 4 byte alignment
gdt:
  SEG_NULL				# null seg
  SEG(STA_X|STA_R, 0x0, 0xffffffff)	# code seg
  SEG(STA_W, 0x0, 0xffffffff)	        # data seg

gdtdesc:
  .word   0x17                            # sizeof(gdt) - 1
  .long   gdt                             # address gdt
```

参考资料:
1. [AT&T汇编与GCC内嵌汇编语法](http://blog.163.com/zhaogan1986@126/blog/static/14044857820107205353919/) 
1. [Gate A20与保护模式](http://blog.csdn.net/lightseed/article/details/4305865)
1. [MIT 6.828 学习笔记1 阅读boot.S](http://blog.csdn.net/scnu20142005027/article/details/51147402)
1. [一段C语言和汇编的对应分析，揭示函数调用的本质](https://segmentfault.com/a/1190000002575242)
