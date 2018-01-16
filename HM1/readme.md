# Executing simple commands
1. 这是最基础的一部分,后续练习都要以这个为基础
2. 找到执行文件的位置,一般在bin下面
3. 用execv系列的system call执行该执行文件
4. Q1: what if child exits before parent calls wait()?
   A1: > When a child process terminates before the parent has called wait, the kernel retains some information about the process, such as its exit status, to enable its parent to call wait later.[2] Because the child is still consuming system resources but not executing it is known as a zombie process. The wait system call is commonly invoked in the SIGCHLD handler. [https://en.wikipedia.org/wiki/Child_process]
5. Q2: what does parsecmd() do?
       A2: parsecmd里先调用parseline,而parseline里实际又是调用parsepipe,parsepipe里是调用parseexec然后再迭代自身.实际上根据平时使用shell的直觉,我们也能猜到,这里整个逻辑是先对命令进行切分,执行第一段命令,然后如果遇到|就执行A处理,遇到>就执行b处理等,然后再进行自身迭代.当然前面的处理最终就是找到/bin/下面的执行文件和相关文件进行操作.
6. Q3: int peek()函数最终是返回的是一个逻辑判断语句,为什么返回值类型不设为bool?
   A3: 因为C语言里没有bool类型
# I/O redirection
7. Q4: the fork/exec split looks wasteful,but it turns out to be useful, why?
   A4: 看起来我们可以直接在父进程里调用exec执行命令,但是这样一来,许多父进程的环境被修改了.
8. Q5: how does "ls" know which directory to look at?
   A5: ls读取父进程当前目录下的文件.这个当前目录肯定是由kernel记录下来的. 
9. Q6: how does it know what to do with its output?
   A6: 默认来讲是直接输出到屏幕,如果有\>/\<符号,则输出到该符号所指向的文件中. 并且,fork会复制file table到子线程,exec会把当前进程的内存覆盖但是会保留file table,因此就算是用fork/execv来执行重定向命令,依旧可以找到要输出的文件.
	A7: read(0,buf,bufsize)调用fgets(stdin),write(1,"hello!\n",strlen("hello\n"))调用fprintf(stdout)
12. Q8: how could our simple shell implement output redirection?
    A8: 靠redircmd函数. 主要就是通过切分把子命令和重定向的文件分开,形成一个redircmd返回.我们看到在runcmd负责执行命令的部分依旧是runcmd,也就是由case ' '负责,那么我们应该在case '<'和case'>' 里修改标准输出或输入的文件.通过查阅manual手册,可以看到open是用来打开甚至创建文件的system call.只要把当前的fd文件关掉,重新打开新的文件作为输入输出.
13. Q9: 这里的close(rcmd->fd)为什么就是关闭当前的fd? 
	A9: > A file descriptor is a small integer representing a kernel-­managed object that a process  may read from or write to.......Th
e  shell  ensures  that  it  always  has  three  file  descriptors  open,which are by default file descriptors for the  console[xv6book第7页](https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-828-operating-system-engineering-fall-2012/lecture-notes-and-readings/MIT6_828F12_xv6-book-rev7.pdf)由这段引用可知,shell默认是打开了控制台的文件描述符,也就是说输入输出都是对控制台而言.因此需要先关闭当前的fd. 还需要注意的是,用open打开文件它总会返回但前进程最小的文件描述符,这就保证了你关闭的是哪一个,再用open就会打开哪一个.
14. Q10: 为什么open打开出错了以后,还是继续执行runcmd(rcmd->cmd)?难道不应该直接报错退出? #unfixed
# implement pipes
15. good illustration of why it's nice to have separate fork and exec. 现在可以回答了,这里这个例子就说明了如果不是先fork,那么整个输入输出流都会改变,下一次的命令也会输出到之前的文件中去.
1. Q11: why not have open() return a pointer reference to a kernel file object?
	A11: 课件中回答了关于文件描述符的设计:
	1. 更方便fork后的进程之间的交互
	1. 使得不管是文件,控制台还是管道,都能用同样的方法操作.而不是分门别类的去写代码
	2. shell pipeline只能对普通格式的程序操作.
对于第一点,我们知道如果用指针的话,对应的地址空间在不同进程之间不一定能访问.所以fork后的子进程就无法访问父进程的文件;
对于第二点,也很容易理解,
1. Q12:dup为什么不需要赋值给一个fd变量? 
A12:dup之前close掉了文件描述符1,那么dup(int oldfd)新生成的指向oldfd一样文件的fd数也为1.那么文件描述符作为序列号对应一个文件操作状态.就改变了.
1. Q13:strlen(char *s),因此在获取char *s的长度时不需要strlen(*s),而是直接strlen(s)

