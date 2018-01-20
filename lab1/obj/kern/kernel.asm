
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 33 00 00 00       	call   f0100071 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 08             	sub    $0x8,%esp
f0100046:	8b 45 08             	mov    0x8(%ebp),%eax
	
	if (x > 0)
f0100049:	85 c0                	test   %eax,%eax
f010004b:	7e 11                	jle    f010005e <test_backtrace+0x1e>
		test_backtrace(x-1);
f010004d:	83 ec 0c             	sub    $0xc,%esp
f0100050:	83 e8 01             	sub    $0x1,%eax
f0100053:	50                   	push   %eax
f0100054:	e8 e7 ff ff ff       	call   f0100040 <test_backtrace>
f0100059:	83 c4 10             	add    $0x10,%esp
f010005c:	eb 11                	jmp    f010006f <test_backtrace+0x2f>
	else
		mon_backtrace(0, 0, 0);
f010005e:	83 ec 04             	sub    $0x4,%esp
f0100061:	6a 00                	push   $0x0
f0100063:	6a 00                	push   $0x0
f0100065:	6a 00                	push   $0x0
f0100067:	e8 df 06 00 00       	call   f010074b <mon_backtrace>
f010006c:	83 c4 10             	add    $0x10,%esp
	//cprintf("leaving test_backtrace %d\n", x);
}
f010006f:	c9                   	leave  
f0100070:	c3                   	ret    

f0100071 <i386_init>:

void
i386_init(void)
{
f0100071:	55                   	push   %ebp
f0100072:	89 e5                	mov    %esp,%ebp
f0100074:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100077:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010007c:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f0100081:	50                   	push   %eax
f0100082:	6a 00                	push   $0x0
f0100084:	68 00 23 11 f0       	push   $0xf0112300
f0100089:	e8 79 13 00 00       	call   f0101407 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010008e:	e8 9d 04 00 00       	call   f0100530 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100093:	83 c4 08             	add    $0x8,%esp
f0100096:	68 ac 1a 00 00       	push   $0x1aac
f010009b:	68 a0 18 10 f0       	push   $0xf01018a0
f01000a0:	e8 ab 08 00 00       	call   f0100950 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000a5:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ac:	e8 8f ff ff ff       	call   f0100040 <test_backtrace>
f01000b1:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000b4:	83 ec 0c             	sub    $0xc,%esp
f01000b7:	6a 00                	push   $0x0
f01000b9:	e8 12 07 00 00       	call   f01007d0 <monitor>
f01000be:	83 c4 10             	add    $0x10,%esp
f01000c1:	eb f1                	jmp    f01000b4 <i386_init+0x43>

f01000c3 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000c3:	55                   	push   %ebp
f01000c4:	89 e5                	mov    %esp,%ebp
f01000c6:	56                   	push   %esi
f01000c7:	53                   	push   %ebx
f01000c8:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000cb:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000d2:	75 37                	jne    f010010b <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000d4:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000da:	fa                   	cli    
f01000db:	fc                   	cld    

	va_start(ap, fmt);
f01000dc:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000df:	83 ec 04             	sub    $0x4,%esp
f01000e2:	ff 75 0c             	pushl  0xc(%ebp)
f01000e5:	ff 75 08             	pushl  0x8(%ebp)
f01000e8:	68 bb 18 10 f0       	push   $0xf01018bb
f01000ed:	e8 5e 08 00 00       	call   f0100950 <cprintf>
	vcprintf(fmt, ap);
f01000f2:	83 c4 08             	add    $0x8,%esp
f01000f5:	53                   	push   %ebx
f01000f6:	56                   	push   %esi
f01000f7:	e8 2e 08 00 00       	call   f010092a <vcprintf>
	cprintf("\n");
f01000fc:	c7 04 24 f7 18 10 f0 	movl   $0xf01018f7,(%esp)
f0100103:	e8 48 08 00 00       	call   f0100950 <cprintf>
	va_end(ap);
f0100108:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010010b:	83 ec 0c             	sub    $0xc,%esp
f010010e:	6a 00                	push   $0x0
f0100110:	e8 bb 06 00 00       	call   f01007d0 <monitor>
f0100115:	83 c4 10             	add    $0x10,%esp
f0100118:	eb f1                	jmp    f010010b <_panic+0x48>

f010011a <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011a:	55                   	push   %ebp
f010011b:	89 e5                	mov    %esp,%ebp
f010011d:	53                   	push   %ebx
f010011e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100121:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100124:	ff 75 0c             	pushl  0xc(%ebp)
f0100127:	ff 75 08             	pushl  0x8(%ebp)
f010012a:	68 d3 18 10 f0       	push   $0xf01018d3
f010012f:	e8 1c 08 00 00       	call   f0100950 <cprintf>
	vcprintf(fmt, ap);
f0100134:	83 c4 08             	add    $0x8,%esp
f0100137:	53                   	push   %ebx
f0100138:	ff 75 10             	pushl  0x10(%ebp)
f010013b:	e8 ea 07 00 00       	call   f010092a <vcprintf>
	cprintf("\n");
f0100140:	c7 04 24 f7 18 10 f0 	movl   $0xf01018f7,(%esp)
f0100147:	e8 04 08 00 00       	call   f0100950 <cprintf>
	va_end(ap);
}
f010014c:	83 c4 10             	add    $0x10,%esp
f010014f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100152:	c9                   	leave  
f0100153:	c3                   	ret    

f0100154 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100154:	55                   	push   %ebp
f0100155:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100157:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015c:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015d:	a8 01                	test   $0x1,%al
f010015f:	74 0b                	je     f010016c <serial_proc_data+0x18>
f0100161:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100166:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100167:	0f b6 c0             	movzbl %al,%eax
f010016a:	eb 05                	jmp    f0100171 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010016c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100171:	5d                   	pop    %ebp
f0100172:	c3                   	ret    

f0100173 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100173:	55                   	push   %ebp
f0100174:	89 e5                	mov    %esp,%ebp
f0100176:	53                   	push   %ebx
f0100177:	83 ec 04             	sub    $0x4,%esp
f010017a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010017c:	eb 2b                	jmp    f01001a9 <cons_intr+0x36>
		if (c == 0)
f010017e:	85 c0                	test   %eax,%eax
f0100180:	74 27                	je     f01001a9 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100182:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f0100188:	8d 51 01             	lea    0x1(%ecx),%edx
f010018b:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f0100191:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100197:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010019d:	75 0a                	jne    f01001a9 <cons_intr+0x36>
			cons.wpos = 0;
f010019f:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001a6:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001a9:	ff d3                	call   *%ebx
f01001ab:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ae:	75 ce                	jne    f010017e <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001b0:	83 c4 04             	add    $0x4,%esp
f01001b3:	5b                   	pop    %ebx
f01001b4:	5d                   	pop    %ebp
f01001b5:	c3                   	ret    

f01001b6 <kbd_proc_data>:
f01001b6:	ba 64 00 00 00       	mov    $0x64,%edx
f01001bb:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	0f 84 f8 00 00 00    	je     f01002bc <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001c4:	a8 20                	test   $0x20,%al
f01001c6:	0f 85 f6 00 00 00    	jne    f01002c2 <kbd_proc_data+0x10c>
f01001cc:	ba 60 00 00 00       	mov    $0x60,%edx
f01001d1:	ec                   	in     (%dx),%al
f01001d2:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001d4:	3c e0                	cmp    $0xe0,%al
f01001d6:	75 0d                	jne    f01001e5 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001d8:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001df:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e4:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001e5:	55                   	push   %ebp
f01001e6:	89 e5                	mov    %esp,%ebp
f01001e8:	53                   	push   %ebx
f01001e9:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ec:	84 c0                	test   %al,%al
f01001ee:	79 36                	jns    f0100226 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001f0:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f01001f6:	89 cb                	mov    %ecx,%ebx
f01001f8:	83 e3 40             	and    $0x40,%ebx
f01001fb:	83 e0 7f             	and    $0x7f,%eax
f01001fe:	85 db                	test   %ebx,%ebx
f0100200:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100203:	0f b6 d2             	movzbl %dl,%edx
f0100206:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f010020d:	83 c8 40             	or     $0x40,%eax
f0100210:	0f b6 c0             	movzbl %al,%eax
f0100213:	f7 d0                	not    %eax
f0100215:	21 c8                	and    %ecx,%eax
f0100217:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010021c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100221:	e9 a4 00 00 00       	jmp    f01002ca <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100226:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010022c:	f6 c1 40             	test   $0x40,%cl
f010022f:	74 0e                	je     f010023f <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100231:	83 c8 80             	or     $0xffffff80,%eax
f0100234:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100236:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100239:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010023f:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100242:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f0100249:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010024f:	0f b6 8a 40 19 10 f0 	movzbl -0xfefe6c0(%edx),%ecx
f0100256:	31 c8                	xor    %ecx,%eax
f0100258:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010025d:	89 c1                	mov    %eax,%ecx
f010025f:	83 e1 03             	and    $0x3,%ecx
f0100262:	8b 0c 8d 20 19 10 f0 	mov    -0xfefe6e0(,%ecx,4),%ecx
f0100269:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010026d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100270:	a8 08                	test   $0x8,%al
f0100272:	74 1b                	je     f010028f <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100274:	89 da                	mov    %ebx,%edx
f0100276:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100279:	83 f9 19             	cmp    $0x19,%ecx
f010027c:	77 05                	ja     f0100283 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f010027e:	83 eb 20             	sub    $0x20,%ebx
f0100281:	eb 0c                	jmp    f010028f <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f0100283:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100286:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100289:	83 fa 19             	cmp    $0x19,%edx
f010028c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028f:	f7 d0                	not    %eax
f0100291:	a8 06                	test   $0x6,%al
f0100293:	75 33                	jne    f01002c8 <kbd_proc_data+0x112>
f0100295:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010029b:	75 2b                	jne    f01002c8 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f010029d:	83 ec 0c             	sub    $0xc,%esp
f01002a0:	68 ed 18 10 f0       	push   $0xf01018ed
f01002a5:	e8 a6 06 00 00       	call   f0100950 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002aa:	ba 92 00 00 00       	mov    $0x92,%edx
f01002af:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b4:	ee                   	out    %al,(%dx)
f01002b5:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002b8:	89 d8                	mov    %ebx,%eax
f01002ba:	eb 0e                	jmp    f01002ca <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002c1:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002c7:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002c8:	89 d8                	mov    %ebx,%eax
}
f01002ca:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002cd:	c9                   	leave  
f01002ce:	c3                   	ret    

f01002cf <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002cf:	55                   	push   %ebp
f01002d0:	89 e5                	mov    %esp,%ebp
f01002d2:	57                   	push   %edi
f01002d3:	56                   	push   %esi
f01002d4:	53                   	push   %ebx
f01002d5:	83 ec 1c             	sub    $0x1c,%esp
f01002d8:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002da:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002df:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002e4:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e9:	eb 09                	jmp    f01002f4 <cons_putc+0x25>
f01002eb:	89 ca                	mov    %ecx,%edx
f01002ed:	ec                   	in     (%dx),%al
f01002ee:	ec                   	in     (%dx),%al
f01002ef:	ec                   	in     (%dx),%al
f01002f0:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002f1:	83 c3 01             	add    $0x1,%ebx
f01002f4:	89 f2                	mov    %esi,%edx
f01002f6:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002f7:	a8 20                	test   $0x20,%al
f01002f9:	75 08                	jne    f0100303 <cons_putc+0x34>
f01002fb:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100301:	7e e8                	jle    f01002eb <cons_putc+0x1c>
f0100303:	89 f8                	mov    %edi,%eax
f0100305:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100308:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010030d:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030e:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100313:	be 79 03 00 00       	mov    $0x379,%esi
f0100318:	b9 84 00 00 00       	mov    $0x84,%ecx
f010031d:	eb 09                	jmp    f0100328 <cons_putc+0x59>
f010031f:	89 ca                	mov    %ecx,%edx
f0100321:	ec                   	in     (%dx),%al
f0100322:	ec                   	in     (%dx),%al
f0100323:	ec                   	in     (%dx),%al
f0100324:	ec                   	in     (%dx),%al
f0100325:	83 c3 01             	add    $0x1,%ebx
f0100328:	89 f2                	mov    %esi,%edx
f010032a:	ec                   	in     (%dx),%al
f010032b:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100331:	7f 04                	jg     f0100337 <cons_putc+0x68>
f0100333:	84 c0                	test   %al,%al
f0100335:	79 e8                	jns    f010031f <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba 78 03 00 00       	mov    $0x378,%edx
f010033c:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100340:	ee                   	out    %al,(%dx)
f0100341:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100346:	b8 0d 00 00 00       	mov    $0xd,%eax
f010034b:	ee                   	out    %al,(%dx)
f010034c:	b8 08 00 00 00       	mov    $0x8,%eax
f0100351:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100352:	89 fa                	mov    %edi,%edx
f0100354:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010035a:	89 f8                	mov    %edi,%eax
f010035c:	80 cc 07             	or     $0x7,%ah
f010035f:	85 d2                	test   %edx,%edx
f0100361:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100364:	89 f8                	mov    %edi,%eax
f0100366:	0f b6 c0             	movzbl %al,%eax
f0100369:	83 f8 09             	cmp    $0x9,%eax
f010036c:	74 74                	je     f01003e2 <cons_putc+0x113>
f010036e:	83 f8 09             	cmp    $0x9,%eax
f0100371:	7f 0a                	jg     f010037d <cons_putc+0xae>
f0100373:	83 f8 08             	cmp    $0x8,%eax
f0100376:	74 14                	je     f010038c <cons_putc+0xbd>
f0100378:	e9 99 00 00 00       	jmp    f0100416 <cons_putc+0x147>
f010037d:	83 f8 0a             	cmp    $0xa,%eax
f0100380:	74 3a                	je     f01003bc <cons_putc+0xed>
f0100382:	83 f8 0d             	cmp    $0xd,%eax
f0100385:	74 3d                	je     f01003c4 <cons_putc+0xf5>
f0100387:	e9 8a 00 00 00       	jmp    f0100416 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f010038c:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100393:	66 85 c0             	test   %ax,%ax
f0100396:	0f 84 e6 00 00 00    	je     f0100482 <cons_putc+0x1b3>
			crt_pos--;
f010039c:	83 e8 01             	sub    $0x1,%eax
f010039f:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a5:	0f b7 c0             	movzwl %ax,%eax
f01003a8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ad:	83 cf 20             	or     $0x20,%edi
f01003b0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003b6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ba:	eb 78                	jmp    f0100434 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003bc:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003c3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003c4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003cb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003d1:	c1 e8 16             	shr    $0x16,%eax
f01003d4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003d7:	c1 e0 04             	shl    $0x4,%eax
f01003da:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003e0:	eb 52                	jmp    f0100434 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e7:	e8 e3 fe ff ff       	call   f01002cf <cons_putc>
		cons_putc(' ');
f01003ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f1:	e8 d9 fe ff ff       	call   f01002cf <cons_putc>
		cons_putc(' ');
f01003f6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fb:	e8 cf fe ff ff       	call   f01002cf <cons_putc>
		cons_putc(' ');
f0100400:	b8 20 00 00 00       	mov    $0x20,%eax
f0100405:	e8 c5 fe ff ff       	call   f01002cf <cons_putc>
		cons_putc(' ');
f010040a:	b8 20 00 00 00       	mov    $0x20,%eax
f010040f:	e8 bb fe ff ff       	call   f01002cf <cons_putc>
f0100414:	eb 1e                	jmp    f0100434 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100416:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010041d:	8d 50 01             	lea    0x1(%eax),%edx
f0100420:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100427:	0f b7 c0             	movzwl %ax,%eax
f010042a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100430:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100434:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010043b:	cf 07 
f010043d:	76 43                	jbe    f0100482 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010043f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100444:	83 ec 04             	sub    $0x4,%esp
f0100447:	68 00 0f 00 00       	push   $0xf00
f010044c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100452:	52                   	push   %edx
f0100453:	50                   	push   %eax
f0100454:	e8 fb 0f 00 00       	call   f0101454 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100459:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f010045f:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100465:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010046b:	83 c4 10             	add    $0x10,%esp
f010046e:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100473:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100476:	39 d0                	cmp    %edx,%eax
f0100478:	75 f4                	jne    f010046e <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010047a:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100481:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100482:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f0100488:	b8 0e 00 00 00       	mov    $0xe,%eax
f010048d:	89 ca                	mov    %ecx,%edx
f010048f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100490:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f0100497:	8d 71 01             	lea    0x1(%ecx),%esi
f010049a:	89 d8                	mov    %ebx,%eax
f010049c:	66 c1 e8 08          	shr    $0x8,%ax
f01004a0:	89 f2                	mov    %esi,%edx
f01004a2:	ee                   	out    %al,(%dx)
f01004a3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a8:	89 ca                	mov    %ecx,%edx
f01004aa:	ee                   	out    %al,(%dx)
f01004ab:	89 d8                	mov    %ebx,%eax
f01004ad:	89 f2                	mov    %esi,%edx
f01004af:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004b3:	5b                   	pop    %ebx
f01004b4:	5e                   	pop    %esi
f01004b5:	5f                   	pop    %edi
f01004b6:	5d                   	pop    %ebp
f01004b7:	c3                   	ret    

f01004b8 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004b8:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004bf:	74 11                	je     f01004d2 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004c1:	55                   	push   %ebp
f01004c2:	89 e5                	mov    %esp,%ebp
f01004c4:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c7:	b8 54 01 10 f0       	mov    $0xf0100154,%eax
f01004cc:	e8 a2 fc ff ff       	call   f0100173 <cons_intr>
}
f01004d1:	c9                   	leave  
f01004d2:	f3 c3                	repz ret 

f01004d4 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d4:	55                   	push   %ebp
f01004d5:	89 e5                	mov    %esp,%ebp
f01004d7:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004da:	b8 b6 01 10 f0       	mov    $0xf01001b6,%eax
f01004df:	e8 8f fc ff ff       	call   f0100173 <cons_intr>
}
f01004e4:	c9                   	leave  
f01004e5:	c3                   	ret    

f01004e6 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e6:	55                   	push   %ebp
f01004e7:	89 e5                	mov    %esp,%ebp
f01004e9:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004ec:	e8 c7 ff ff ff       	call   f01004b8 <serial_intr>
	kbd_intr();
f01004f1:	e8 de ff ff ff       	call   f01004d4 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f6:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f01004fb:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100501:	74 26                	je     f0100529 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100503:	8d 50 01             	lea    0x1(%eax),%edx
f0100506:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010050c:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100513:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100515:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010051b:	75 11                	jne    f010052e <cons_getc+0x48>
			cons.rpos = 0;
f010051d:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100524:	00 00 00 
f0100527:	eb 05                	jmp    f010052e <cons_getc+0x48>
		return c;
	}
	return 0;
f0100529:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010052e:	c9                   	leave  
f010052f:	c3                   	ret    

f0100530 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100530:	55                   	push   %ebp
f0100531:	89 e5                	mov    %esp,%ebp
f0100533:	57                   	push   %edi
f0100534:	56                   	push   %esi
f0100535:	53                   	push   %ebx
f0100536:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100539:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100540:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100547:	5a a5 
	if (*cp != 0xA55A) {
f0100549:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100550:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100554:	74 11                	je     f0100567 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100556:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010055d:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100560:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100565:	eb 16                	jmp    f010057d <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100567:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010056e:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100575:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100578:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010057d:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100583:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100588:	89 fa                	mov    %edi,%edx
f010058a:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010058b:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058e:	89 da                	mov    %ebx,%edx
f0100590:	ec                   	in     (%dx),%al
f0100591:	0f b6 c8             	movzbl %al,%ecx
f0100594:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100597:	b8 0f 00 00 00       	mov    $0xf,%eax
f010059c:	89 fa                	mov    %edi,%edx
f010059e:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059f:	89 da                	mov    %ebx,%edx
f01005a1:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005a2:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005a8:	0f b6 c0             	movzbl %al,%eax
f01005ab:	09 c8                	or     %ecx,%eax
f01005ad:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bd:	89 f2                	mov    %esi,%edx
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005c5:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ca:	ee                   	out    %al,(%dx)
f01005cb:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005d0:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005d5:	89 da                	mov    %ebx,%edx
f01005d7:	ee                   	out    %al,(%dx)
f01005d8:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 03 00 00 00       	mov    $0x3,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f8:	ee                   	out    %al,(%dx)
f01005f9:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005fe:	b8 01 00 00 00       	mov    $0x1,%eax
f0100603:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100604:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100609:	ec                   	in     (%dx),%al
f010060a:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060c:	3c ff                	cmp    $0xff,%al
f010060e:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100615:	89 f2                	mov    %esi,%edx
f0100617:	ec                   	in     (%dx),%al
f0100618:	89 da                	mov    %ebx,%edx
f010061a:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061b:	80 f9 ff             	cmp    $0xff,%cl
f010061e:	75 10                	jne    f0100630 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100620:	83 ec 0c             	sub    $0xc,%esp
f0100623:	68 f9 18 10 f0       	push   $0xf01018f9
f0100628:	e8 23 03 00 00       	call   f0100950 <cprintf>
f010062d:	83 c4 10             	add    $0x10,%esp
}
f0100630:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100633:	5b                   	pop    %ebx
f0100634:	5e                   	pop    %esi
f0100635:	5f                   	pop    %edi
f0100636:	5d                   	pop    %ebp
f0100637:	c3                   	ret    

f0100638 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100638:	55                   	push   %ebp
f0100639:	89 e5                	mov    %esp,%ebp
f010063b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010063e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100641:	e8 89 fc ff ff       	call   f01002cf <cons_putc>
}
f0100646:	c9                   	leave  
f0100647:	c3                   	ret    

f0100648 <getchar>:

int
getchar(void)
{
f0100648:	55                   	push   %ebp
f0100649:	89 e5                	mov    %esp,%ebp
f010064b:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010064e:	e8 93 fe ff ff       	call   f01004e6 <cons_getc>
f0100653:	85 c0                	test   %eax,%eax
f0100655:	74 f7                	je     f010064e <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100657:	c9                   	leave  
f0100658:	c3                   	ret    

f0100659 <iscons>:

int
iscons(int fdnum)
{
f0100659:	55                   	push   %ebp
f010065a:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100661:	5d                   	pop    %ebp
f0100662:	c3                   	ret    

f0100663 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100663:	55                   	push   %ebp
f0100664:	89 e5                	mov    %esp,%ebp
f0100666:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100669:	68 40 1b 10 f0       	push   $0xf0101b40
f010066e:	68 5e 1b 10 f0       	push   $0xf0101b5e
f0100673:	68 63 1b 10 f0       	push   $0xf0101b63
f0100678:	e8 d3 02 00 00       	call   f0100950 <cprintf>
f010067d:	83 c4 0c             	add    $0xc,%esp
f0100680:	68 f0 1b 10 f0       	push   $0xf0101bf0
f0100685:	68 6c 1b 10 f0       	push   $0xf0101b6c
f010068a:	68 63 1b 10 f0       	push   $0xf0101b63
f010068f:	e8 bc 02 00 00       	call   f0100950 <cprintf>
	return 0;
}
f0100694:	b8 00 00 00 00       	mov    $0x0,%eax
f0100699:	c9                   	leave  
f010069a:	c3                   	ret    

f010069b <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010069b:	55                   	push   %ebp
f010069c:	89 e5                	mov    %esp,%ebp
f010069e:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a1:	68 75 1b 10 f0       	push   $0xf0101b75
f01006a6:	e8 a5 02 00 00       	call   f0100950 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006ab:	83 c4 08             	add    $0x8,%esp
f01006ae:	68 0c 00 10 00       	push   $0x10000c
f01006b3:	68 18 1c 10 f0       	push   $0xf0101c18
f01006b8:	e8 93 02 00 00       	call   f0100950 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006bd:	83 c4 0c             	add    $0xc,%esp
f01006c0:	68 0c 00 10 00       	push   $0x10000c
f01006c5:	68 0c 00 10 f0       	push   $0xf010000c
f01006ca:	68 40 1c 10 f0       	push   $0xf0101c40
f01006cf:	e8 7c 02 00 00       	call   f0100950 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d4:	83 c4 0c             	add    $0xc,%esp
f01006d7:	68 91 18 10 00       	push   $0x101891
f01006dc:	68 91 18 10 f0       	push   $0xf0101891
f01006e1:	68 64 1c 10 f0       	push   $0xf0101c64
f01006e6:	e8 65 02 00 00       	call   f0100950 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006eb:	83 c4 0c             	add    $0xc,%esp
f01006ee:	68 00 23 11 00       	push   $0x112300
f01006f3:	68 00 23 11 f0       	push   $0xf0112300
f01006f8:	68 88 1c 10 f0       	push   $0xf0101c88
f01006fd:	e8 4e 02 00 00       	call   f0100950 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100702:	83 c4 0c             	add    $0xc,%esp
f0100705:	68 44 29 11 00       	push   $0x112944
f010070a:	68 44 29 11 f0       	push   $0xf0112944
f010070f:	68 ac 1c 10 f0       	push   $0xf0101cac
f0100714:	e8 37 02 00 00       	call   f0100950 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100719:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010071e:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100723:	83 c4 08             	add    $0x8,%esp
f0100726:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010072b:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100731:	85 c0                	test   %eax,%eax
f0100733:	0f 48 c2             	cmovs  %edx,%eax
f0100736:	c1 f8 0a             	sar    $0xa,%eax
f0100739:	50                   	push   %eax
f010073a:	68 d0 1c 10 f0       	push   $0xf0101cd0
f010073f:	e8 0c 02 00 00       	call   f0100950 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100744:	b8 00 00 00 00       	mov    $0x0,%eax
f0100749:	c9                   	leave  
f010074a:	c3                   	ret    

f010074b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010074b:	55                   	push   %ebp
f010074c:	89 e5                	mov    %esp,%ebp
f010074e:	57                   	push   %edi
f010074f:	56                   	push   %esi
f0100750:	53                   	push   %ebx
f0100751:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100754:	89 eb                	mov    %ebp,%ebx
	// Your code here.
	uint32_t ebp, *ptr_ebp;
	struct Eipdebuginfo info;
	ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f0100756:	68 8e 1b 10 f0       	push   $0xf0101b8e
f010075b:	e8 f0 01 00 00       	call   f0100950 <cprintf>
	while (ebp != 0) {
f0100760:	83 c4 10             	add    $0x10,%esp
		ptr_ebp = (uint32_t *)ebp;
		cprintf("  ebp %x  eip %x  args %08x %08x %08x %08x %08x\n", ebp, ptr_ebp[1], ptr_ebp[2], ptr_ebp[3], ptr_ebp[4], ptr_ebp[5], ptr_ebp[6]);
		if (debuginfo_eip(ptr_ebp[1], &info) == 0) {
f0100763:	8d 7d d0             	lea    -0x30(%ebp),%edi
	// Your code here.
	uint32_t ebp, *ptr_ebp;
	struct Eipdebuginfo info;
	ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f0100766:	eb 57                	jmp    f01007bf <mon_backtrace+0x74>
		ptr_ebp = (uint32_t *)ebp;
f0100768:	89 de                	mov    %ebx,%esi
		cprintf("  ebp %x  eip %x  args %08x %08x %08x %08x %08x\n", ebp, ptr_ebp[1], ptr_ebp[2], ptr_ebp[3], ptr_ebp[4], ptr_ebp[5], ptr_ebp[6]);
f010076a:	ff 73 18             	pushl  0x18(%ebx)
f010076d:	ff 73 14             	pushl  0x14(%ebx)
f0100770:	ff 73 10             	pushl  0x10(%ebx)
f0100773:	ff 73 0c             	pushl  0xc(%ebx)
f0100776:	ff 73 08             	pushl  0x8(%ebx)
f0100779:	ff 73 04             	pushl  0x4(%ebx)
f010077c:	53                   	push   %ebx
f010077d:	68 fc 1c 10 f0       	push   $0xf0101cfc
f0100782:	e8 c9 01 00 00       	call   f0100950 <cprintf>
		if (debuginfo_eip(ptr_ebp[1], &info) == 0) {
f0100787:	83 c4 18             	add    $0x18,%esp
f010078a:	57                   	push   %edi
f010078b:	ff 73 04             	pushl  0x4(%ebx)
f010078e:	e8 c7 02 00 00       	call   f0100a5a <debuginfo_eip>
f0100793:	83 c4 10             	add    $0x10,%esp
f0100796:	85 c0                	test   %eax,%eax
f0100798:	75 23                	jne    f01007bd <mon_backtrace+0x72>
			uint32_t fn_offset = ptr_ebp[1] - info.eip_fn_addr;
			cprintf("\t%s:%d: %.*s+%d\n", info.eip_file,info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
f010079a:	83 ec 08             	sub    $0x8,%esp
f010079d:	8b 43 04             	mov    0x4(%ebx),%eax
f01007a0:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007a3:	50                   	push   %eax
f01007a4:	ff 75 d8             	pushl  -0x28(%ebp)
f01007a7:	ff 75 dc             	pushl  -0x24(%ebp)
f01007aa:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007ad:	ff 75 d0             	pushl  -0x30(%ebp)
f01007b0:	68 a0 1b 10 f0       	push   $0xf0101ba0
f01007b5:	e8 96 01 00 00       	call   f0100950 <cprintf>
f01007ba:	83 c4 20             	add    $0x20,%esp
		}
		ebp = *ptr_ebp;
f01007bd:	8b 1e                	mov    (%esi),%ebx
	// Your code here.
	uint32_t ebp, *ptr_ebp;
	struct Eipdebuginfo info;
	ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	while (ebp != 0) {
f01007bf:	85 db                	test   %ebx,%ebx
f01007c1:	75 a5                	jne    f0100768 <mon_backtrace+0x1d>
		}
		ebp = *ptr_ebp;
	}
	return 0;
	return 0;
}
f01007c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007cb:	5b                   	pop    %ebx
f01007cc:	5e                   	pop    %esi
f01007cd:	5f                   	pop    %edi
f01007ce:	5d                   	pop    %ebp
f01007cf:	c3                   	ret    

f01007d0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d0:	55                   	push   %ebp
f01007d1:	89 e5                	mov    %esp,%ebp
f01007d3:	57                   	push   %edi
f01007d4:	56                   	push   %esi
f01007d5:	53                   	push   %ebx
f01007d6:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007d9:	68 30 1d 10 f0       	push   $0xf0101d30
f01007de:	e8 6d 01 00 00       	call   f0100950 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007e3:	c7 04 24 54 1d 10 f0 	movl   $0xf0101d54,(%esp)
f01007ea:	e8 61 01 00 00       	call   f0100950 <cprintf>
f01007ef:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007f2:	83 ec 0c             	sub    $0xc,%esp
f01007f5:	68 b1 1b 10 f0       	push   $0xf0101bb1
f01007fa:	e8 b1 09 00 00       	call   f01011b0 <readline>
f01007ff:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100801:	83 c4 10             	add    $0x10,%esp
f0100804:	85 c0                	test   %eax,%eax
f0100806:	74 ea                	je     f01007f2 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100808:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010080f:	be 00 00 00 00       	mov    $0x0,%esi
f0100814:	eb 0a                	jmp    f0100820 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100816:	c6 03 00             	movb   $0x0,(%ebx)
f0100819:	89 f7                	mov    %esi,%edi
f010081b:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010081e:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100820:	0f b6 03             	movzbl (%ebx),%eax
f0100823:	84 c0                	test   %al,%al
f0100825:	74 63                	je     f010088a <monitor+0xba>
f0100827:	83 ec 08             	sub    $0x8,%esp
f010082a:	0f be c0             	movsbl %al,%eax
f010082d:	50                   	push   %eax
f010082e:	68 b5 1b 10 f0       	push   $0xf0101bb5
f0100833:	e8 92 0b 00 00       	call   f01013ca <strchr>
f0100838:	83 c4 10             	add    $0x10,%esp
f010083b:	85 c0                	test   %eax,%eax
f010083d:	75 d7                	jne    f0100816 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010083f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100842:	74 46                	je     f010088a <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100844:	83 fe 0f             	cmp    $0xf,%esi
f0100847:	75 14                	jne    f010085d <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100849:	83 ec 08             	sub    $0x8,%esp
f010084c:	6a 10                	push   $0x10
f010084e:	68 ba 1b 10 f0       	push   $0xf0101bba
f0100853:	e8 f8 00 00 00       	call   f0100950 <cprintf>
f0100858:	83 c4 10             	add    $0x10,%esp
f010085b:	eb 95                	jmp    f01007f2 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010085d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100860:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100864:	eb 03                	jmp    f0100869 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100866:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100869:	0f b6 03             	movzbl (%ebx),%eax
f010086c:	84 c0                	test   %al,%al
f010086e:	74 ae                	je     f010081e <monitor+0x4e>
f0100870:	83 ec 08             	sub    $0x8,%esp
f0100873:	0f be c0             	movsbl %al,%eax
f0100876:	50                   	push   %eax
f0100877:	68 b5 1b 10 f0       	push   $0xf0101bb5
f010087c:	e8 49 0b 00 00       	call   f01013ca <strchr>
f0100881:	83 c4 10             	add    $0x10,%esp
f0100884:	85 c0                	test   %eax,%eax
f0100886:	74 de                	je     f0100866 <monitor+0x96>
f0100888:	eb 94                	jmp    f010081e <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010088a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100891:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100892:	85 f6                	test   %esi,%esi
f0100894:	0f 84 58 ff ff ff    	je     f01007f2 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010089a:	83 ec 08             	sub    $0x8,%esp
f010089d:	68 5e 1b 10 f0       	push   $0xf0101b5e
f01008a2:	ff 75 a8             	pushl  -0x58(%ebp)
f01008a5:	e8 c2 0a 00 00       	call   f010136c <strcmp>
f01008aa:	83 c4 10             	add    $0x10,%esp
f01008ad:	85 c0                	test   %eax,%eax
f01008af:	74 1e                	je     f01008cf <monitor+0xff>
f01008b1:	83 ec 08             	sub    $0x8,%esp
f01008b4:	68 6c 1b 10 f0       	push   $0xf0101b6c
f01008b9:	ff 75 a8             	pushl  -0x58(%ebp)
f01008bc:	e8 ab 0a 00 00       	call   f010136c <strcmp>
f01008c1:	83 c4 10             	add    $0x10,%esp
f01008c4:	85 c0                	test   %eax,%eax
f01008c6:	75 2f                	jne    f01008f7 <monitor+0x127>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008c8:	b8 01 00 00 00       	mov    $0x1,%eax
f01008cd:	eb 05                	jmp    f01008d4 <monitor+0x104>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008cf:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008d4:	83 ec 04             	sub    $0x4,%esp
f01008d7:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008da:	01 d0                	add    %edx,%eax
f01008dc:	ff 75 08             	pushl  0x8(%ebp)
f01008df:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008e2:	51                   	push   %ecx
f01008e3:	56                   	push   %esi
f01008e4:	ff 14 85 84 1d 10 f0 	call   *-0xfefe27c(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008eb:	83 c4 10             	add    $0x10,%esp
f01008ee:	85 c0                	test   %eax,%eax
f01008f0:	78 1d                	js     f010090f <monitor+0x13f>
f01008f2:	e9 fb fe ff ff       	jmp    f01007f2 <monitor+0x22>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008f7:	83 ec 08             	sub    $0x8,%esp
f01008fa:	ff 75 a8             	pushl  -0x58(%ebp)
f01008fd:	68 d7 1b 10 f0       	push   $0xf0101bd7
f0100902:	e8 49 00 00 00       	call   f0100950 <cprintf>
f0100907:	83 c4 10             	add    $0x10,%esp
f010090a:	e9 e3 fe ff ff       	jmp    f01007f2 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010090f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100912:	5b                   	pop    %ebx
f0100913:	5e                   	pop    %esi
f0100914:	5f                   	pop    %edi
f0100915:	5d                   	pop    %ebp
f0100916:	c3                   	ret    

f0100917 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100917:	55                   	push   %ebp
f0100918:	89 e5                	mov    %esp,%ebp
f010091a:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010091d:	ff 75 08             	pushl  0x8(%ebp)
f0100920:	e8 13 fd ff ff       	call   f0100638 <cputchar>
	*cnt++;
}
f0100925:	83 c4 10             	add    $0x10,%esp
f0100928:	c9                   	leave  
f0100929:	c3                   	ret    

f010092a <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010092a:	55                   	push   %ebp
f010092b:	89 e5                	mov    %esp,%ebp
f010092d:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100930:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100937:	ff 75 0c             	pushl  0xc(%ebp)
f010093a:	ff 75 08             	pushl  0x8(%ebp)
f010093d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100940:	50                   	push   %eax
f0100941:	68 17 09 10 f0       	push   $0xf0100917
f0100946:	e8 50 04 00 00       	call   f0100d9b <vprintfmt>
	return cnt;
}
f010094b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010094e:	c9                   	leave  
f010094f:	c3                   	ret    

f0100950 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100956:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100959:	50                   	push   %eax
f010095a:	ff 75 08             	pushl  0x8(%ebp)
f010095d:	e8 c8 ff ff ff       	call   f010092a <vcprintf>
	va_end(ap);

	return cnt;
}
f0100962:	c9                   	leave  
f0100963:	c3                   	ret    

f0100964 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100964:	55                   	push   %ebp
f0100965:	89 e5                	mov    %esp,%ebp
f0100967:	57                   	push   %edi
f0100968:	56                   	push   %esi
f0100969:	53                   	push   %ebx
f010096a:	83 ec 14             	sub    $0x14,%esp
f010096d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100970:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100973:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100976:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100979:	8b 1a                	mov    (%edx),%ebx
f010097b:	8b 01                	mov    (%ecx),%eax
f010097d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100980:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100987:	eb 7f                	jmp    f0100a08 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100989:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010098c:	01 d8                	add    %ebx,%eax
f010098e:	89 c6                	mov    %eax,%esi
f0100990:	c1 ee 1f             	shr    $0x1f,%esi
f0100993:	01 c6                	add    %eax,%esi
f0100995:	d1 fe                	sar    %esi
f0100997:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010099a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010099d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009a0:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009a2:	eb 03                	jmp    f01009a7 <stab_binsearch+0x43>
			m--;
f01009a4:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009a7:	39 c3                	cmp    %eax,%ebx
f01009a9:	7f 0d                	jg     f01009b8 <stab_binsearch+0x54>
f01009ab:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009af:	83 ea 0c             	sub    $0xc,%edx
f01009b2:	39 f9                	cmp    %edi,%ecx
f01009b4:	75 ee                	jne    f01009a4 <stab_binsearch+0x40>
f01009b6:	eb 05                	jmp    f01009bd <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009b8:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009bb:	eb 4b                	jmp    f0100a08 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009bd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009c0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009c3:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009c7:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ca:	76 11                	jbe    f01009dd <stab_binsearch+0x79>
			*region_left = m;
f01009cc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009cf:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009d1:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009d4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009db:	eb 2b                	jmp    f0100a08 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009dd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009e0:	73 14                	jae    f01009f6 <stab_binsearch+0x92>
			*region_right = m - 1;
f01009e2:	83 e8 01             	sub    $0x1,%eax
f01009e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009e8:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009eb:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009ed:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009f4:	eb 12                	jmp    f0100a08 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009f6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009f9:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01009fb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01009ff:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a01:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a08:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a0b:	0f 8e 78 ff ff ff    	jle    f0100989 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a11:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a15:	75 0f                	jne    f0100a26 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a17:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a1a:	8b 00                	mov    (%eax),%eax
f0100a1c:	83 e8 01             	sub    $0x1,%eax
f0100a1f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a22:	89 06                	mov    %eax,(%esi)
f0100a24:	eb 2c                	jmp    f0100a52 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a26:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a29:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a2b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a2e:	8b 0e                	mov    (%esi),%ecx
f0100a30:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a33:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a36:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a39:	eb 03                	jmp    f0100a3e <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a3b:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a3e:	39 c8                	cmp    %ecx,%eax
f0100a40:	7e 0b                	jle    f0100a4d <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a42:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a46:	83 ea 0c             	sub    $0xc,%edx
f0100a49:	39 df                	cmp    %ebx,%edi
f0100a4b:	75 ee                	jne    f0100a3b <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a4d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a50:	89 06                	mov    %eax,(%esi)
	}
}
f0100a52:	83 c4 14             	add    $0x14,%esp
f0100a55:	5b                   	pop    %ebx
f0100a56:	5e                   	pop    %esi
f0100a57:	5f                   	pop    %edi
f0100a58:	5d                   	pop    %ebp
f0100a59:	c3                   	ret    

f0100a5a <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a5a:	55                   	push   %ebp
f0100a5b:	89 e5                	mov    %esp,%ebp
f0100a5d:	57                   	push   %edi
f0100a5e:	56                   	push   %esi
f0100a5f:	53                   	push   %ebx
f0100a60:	83 ec 3c             	sub    $0x3c,%esp
f0100a63:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a66:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a69:	c7 03 94 1d 10 f0    	movl   $0xf0101d94,(%ebx)
	info->eip_line = 0;
f0100a6f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a76:	c7 43 08 94 1d 10 f0 	movl   $0xf0101d94,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a7d:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a84:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a87:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a8e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a94:	76 11                	jbe    f0100aa7 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a96:	b8 72 72 10 f0       	mov    $0xf0107272,%eax
f0100a9b:	3d 45 59 10 f0       	cmp    $0xf0105945,%eax
f0100aa0:	77 19                	ja     f0100abb <debuginfo_eip+0x61>
f0100aa2:	e9 af 01 00 00       	jmp    f0100c56 <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100aa7:	83 ec 04             	sub    $0x4,%esp
f0100aaa:	68 9e 1d 10 f0       	push   $0xf0101d9e
f0100aaf:	6a 7f                	push   $0x7f
f0100ab1:	68 ab 1d 10 f0       	push   $0xf0101dab
f0100ab6:	e8 08 f6 ff ff       	call   f01000c3 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100abb:	80 3d 71 72 10 f0 00 	cmpb   $0x0,0xf0107271
f0100ac2:	0f 85 95 01 00 00    	jne    f0100c5d <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ac8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100acf:	b8 44 59 10 f0       	mov    $0xf0105944,%eax
f0100ad4:	2d cc 1f 10 f0       	sub    $0xf0101fcc,%eax
f0100ad9:	c1 f8 02             	sar    $0x2,%eax
f0100adc:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ae2:	83 e8 01             	sub    $0x1,%eax
f0100ae5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ae8:	83 ec 08             	sub    $0x8,%esp
f0100aeb:	56                   	push   %esi
f0100aec:	6a 64                	push   $0x64
f0100aee:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100af1:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100af4:	b8 cc 1f 10 f0       	mov    $0xf0101fcc,%eax
f0100af9:	e8 66 fe ff ff       	call   f0100964 <stab_binsearch>
	if (lfile == 0)
f0100afe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b01:	83 c4 10             	add    $0x10,%esp
f0100b04:	85 c0                	test   %eax,%eax
f0100b06:	0f 84 58 01 00 00    	je     f0100c64 <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b0c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b12:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b15:	83 ec 08             	sub    $0x8,%esp
f0100b18:	56                   	push   %esi
f0100b19:	6a 24                	push   $0x24
f0100b1b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b1e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b21:	b8 cc 1f 10 f0       	mov    $0xf0101fcc,%eax
f0100b26:	e8 39 fe ff ff       	call   f0100964 <stab_binsearch>

	if (lfun <= rfun) {
f0100b2b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b2e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b31:	83 c4 10             	add    $0x10,%esp
f0100b34:	39 d0                	cmp    %edx,%eax
f0100b36:	7f 40                	jg     f0100b78 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b38:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b3b:	c1 e1 02             	shl    $0x2,%ecx
f0100b3e:	8d b9 cc 1f 10 f0    	lea    -0xfefe034(%ecx),%edi
f0100b44:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b47:	8b b9 cc 1f 10 f0    	mov    -0xfefe034(%ecx),%edi
f0100b4d:	b9 72 72 10 f0       	mov    $0xf0107272,%ecx
f0100b52:	81 e9 45 59 10 f0    	sub    $0xf0105945,%ecx
f0100b58:	39 cf                	cmp    %ecx,%edi
f0100b5a:	73 09                	jae    f0100b65 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b5c:	81 c7 45 59 10 f0    	add    $0xf0105945,%edi
f0100b62:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b65:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b68:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100b6b:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100b6e:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100b70:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100b73:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100b76:	eb 0f                	jmp    f0100b87 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b78:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b7e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100b81:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b84:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b87:	83 ec 08             	sub    $0x8,%esp
f0100b8a:	6a 3a                	push   $0x3a
f0100b8c:	ff 73 08             	pushl  0x8(%ebx)
f0100b8f:	e8 57 08 00 00       	call   f01013eb <strfind>
f0100b94:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b97:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100b9a:	83 c4 08             	add    $0x8,%esp
f0100b9d:	56                   	push   %esi
f0100b9e:	6a 44                	push   $0x44
f0100ba0:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100ba3:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100ba6:	b8 cc 1f 10 f0       	mov    $0xf0101fcc,%eax
f0100bab:	e8 b4 fd ff ff       	call   f0100964 <stab_binsearch>
	if (lline<=rline){
f0100bb0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100bb3:	83 c4 10             	add    $0x10,%esp
f0100bb6:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100bb9:	7f 0e                	jg     f0100bc9 <debuginfo_eip+0x16f>
//		info->eip_line =lfile-lline;			
		info->eip_line =stabs[lline].n_desc;
f0100bbb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bbe:	0f b7 14 95 d2 1f 10 	movzwl -0xfefe02e(,%edx,4),%edx
f0100bc5:	f0 
f0100bc6:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bc9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100bcc:	89 c2                	mov    %eax,%edx
f0100bce:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100bd1:	8d 04 85 cc 1f 10 f0 	lea    -0xfefe034(,%eax,4),%eax
f0100bd8:	eb 06                	jmp    f0100be0 <debuginfo_eip+0x186>
f0100bda:	83 ea 01             	sub    $0x1,%edx
f0100bdd:	83 e8 0c             	sub    $0xc,%eax
f0100be0:	39 d7                	cmp    %edx,%edi
f0100be2:	7f 34                	jg     f0100c18 <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0100be4:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100be8:	80 f9 84             	cmp    $0x84,%cl
f0100beb:	74 0b                	je     f0100bf8 <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bed:	80 f9 64             	cmp    $0x64,%cl
f0100bf0:	75 e8                	jne    f0100bda <debuginfo_eip+0x180>
f0100bf2:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bf6:	74 e2                	je     f0100bda <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bf8:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100bfb:	8b 14 85 cc 1f 10 f0 	mov    -0xfefe034(,%eax,4),%edx
f0100c02:	b8 72 72 10 f0       	mov    $0xf0107272,%eax
f0100c07:	2d 45 59 10 f0       	sub    $0xf0105945,%eax
f0100c0c:	39 c2                	cmp    %eax,%edx
f0100c0e:	73 08                	jae    f0100c18 <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c10:	81 c2 45 59 10 f0    	add    $0xf0105945,%edx
f0100c16:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c18:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c1b:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c1e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c23:	39 f2                	cmp    %esi,%edx
f0100c25:	7d 49                	jge    f0100c70 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f0100c27:	83 c2 01             	add    $0x1,%edx
f0100c2a:	89 d0                	mov    %edx,%eax
f0100c2c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c2f:	8d 14 95 cc 1f 10 f0 	lea    -0xfefe034(,%edx,4),%edx
f0100c36:	eb 04                	jmp    f0100c3c <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c38:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c3c:	39 c6                	cmp    %eax,%esi
f0100c3e:	7e 2b                	jle    f0100c6b <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c40:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c44:	83 c0 01             	add    $0x1,%eax
f0100c47:	83 c2 0c             	add    $0xc,%edx
f0100c4a:	80 f9 a0             	cmp    $0xa0,%cl
f0100c4d:	74 e9                	je     f0100c38 <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c4f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c54:	eb 1a                	jmp    f0100c70 <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c5b:	eb 13                	jmp    f0100c70 <debuginfo_eip+0x216>
f0100c5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c62:	eb 0c                	jmp    f0100c70 <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c69:	eb 05                	jmp    f0100c70 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c70:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c73:	5b                   	pop    %ebx
f0100c74:	5e                   	pop    %esi
f0100c75:	5f                   	pop    %edi
f0100c76:	5d                   	pop    %ebp
f0100c77:	c3                   	ret    

f0100c78 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c78:	55                   	push   %ebp
f0100c79:	89 e5                	mov    %esp,%ebp
f0100c7b:	57                   	push   %edi
f0100c7c:	56                   	push   %esi
f0100c7d:	53                   	push   %ebx
f0100c7e:	83 ec 1c             	sub    $0x1c,%esp
f0100c81:	89 c7                	mov    %eax,%edi
f0100c83:	89 d6                	mov    %edx,%esi
f0100c85:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c88:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c8b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c8e:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c91:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c94:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c99:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100c9c:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100c9f:	39 d3                	cmp    %edx,%ebx
f0100ca1:	72 05                	jb     f0100ca8 <printnum+0x30>
f0100ca3:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ca6:	77 45                	ja     f0100ced <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ca8:	83 ec 0c             	sub    $0xc,%esp
f0100cab:	ff 75 18             	pushl  0x18(%ebp)
f0100cae:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cb1:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cb4:	53                   	push   %ebx
f0100cb5:	ff 75 10             	pushl  0x10(%ebp)
f0100cb8:	83 ec 08             	sub    $0x8,%esp
f0100cbb:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cbe:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cc1:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cc4:	ff 75 d8             	pushl  -0x28(%ebp)
f0100cc7:	e8 44 09 00 00       	call   f0101610 <__udivdi3>
f0100ccc:	83 c4 18             	add    $0x18,%esp
f0100ccf:	52                   	push   %edx
f0100cd0:	50                   	push   %eax
f0100cd1:	89 f2                	mov    %esi,%edx
f0100cd3:	89 f8                	mov    %edi,%eax
f0100cd5:	e8 9e ff ff ff       	call   f0100c78 <printnum>
f0100cda:	83 c4 20             	add    $0x20,%esp
f0100cdd:	eb 18                	jmp    f0100cf7 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100cdf:	83 ec 08             	sub    $0x8,%esp
f0100ce2:	56                   	push   %esi
f0100ce3:	ff 75 18             	pushl  0x18(%ebp)
f0100ce6:	ff d7                	call   *%edi
f0100ce8:	83 c4 10             	add    $0x10,%esp
f0100ceb:	eb 03                	jmp    f0100cf0 <printnum+0x78>
f0100ced:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cf0:	83 eb 01             	sub    $0x1,%ebx
f0100cf3:	85 db                	test   %ebx,%ebx
f0100cf5:	7f e8                	jg     f0100cdf <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cf7:	83 ec 08             	sub    $0x8,%esp
f0100cfa:	56                   	push   %esi
f0100cfb:	83 ec 04             	sub    $0x4,%esp
f0100cfe:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d01:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d04:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d07:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d0a:	e8 31 0a 00 00       	call   f0101740 <__umoddi3>
f0100d0f:	83 c4 14             	add    $0x14,%esp
f0100d12:	0f be 80 b9 1d 10 f0 	movsbl -0xfefe247(%eax),%eax
f0100d19:	50                   	push   %eax
f0100d1a:	ff d7                	call   *%edi
}
f0100d1c:	83 c4 10             	add    $0x10,%esp
f0100d1f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d22:	5b                   	pop    %ebx
f0100d23:	5e                   	pop    %esi
f0100d24:	5f                   	pop    %edi
f0100d25:	5d                   	pop    %ebp
f0100d26:	c3                   	ret    

f0100d27 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d27:	55                   	push   %ebp
f0100d28:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d2a:	83 fa 01             	cmp    $0x1,%edx
f0100d2d:	7e 0e                	jle    f0100d3d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d2f:	8b 10                	mov    (%eax),%edx
f0100d31:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d34:	89 08                	mov    %ecx,(%eax)
f0100d36:	8b 02                	mov    (%edx),%eax
f0100d38:	8b 52 04             	mov    0x4(%edx),%edx
f0100d3b:	eb 22                	jmp    f0100d5f <getuint+0x38>
	else if (lflag)
f0100d3d:	85 d2                	test   %edx,%edx
f0100d3f:	74 10                	je     f0100d51 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d41:	8b 10                	mov    (%eax),%edx
f0100d43:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d46:	89 08                	mov    %ecx,(%eax)
f0100d48:	8b 02                	mov    (%edx),%eax
f0100d4a:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d4f:	eb 0e                	jmp    f0100d5f <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d51:	8b 10                	mov    (%eax),%edx
f0100d53:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d56:	89 08                	mov    %ecx,(%eax)
f0100d58:	8b 02                	mov    (%edx),%eax
f0100d5a:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d5f:	5d                   	pop    %ebp
f0100d60:	c3                   	ret    

f0100d61 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d61:	55                   	push   %ebp
f0100d62:	89 e5                	mov    %esp,%ebp
f0100d64:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d67:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d6b:	8b 10                	mov    (%eax),%edx
f0100d6d:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d70:	73 0a                	jae    f0100d7c <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d72:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d75:	89 08                	mov    %ecx,(%eax)
f0100d77:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d7a:	88 02                	mov    %al,(%edx)
}
f0100d7c:	5d                   	pop    %ebp
f0100d7d:	c3                   	ret    

f0100d7e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d7e:	55                   	push   %ebp
f0100d7f:	89 e5                	mov    %esp,%ebp
f0100d81:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d84:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d87:	50                   	push   %eax
f0100d88:	ff 75 10             	pushl  0x10(%ebp)
f0100d8b:	ff 75 0c             	pushl  0xc(%ebp)
f0100d8e:	ff 75 08             	pushl  0x8(%ebp)
f0100d91:	e8 05 00 00 00       	call   f0100d9b <vprintfmt>
	va_end(ap);
}
f0100d96:	83 c4 10             	add    $0x10,%esp
f0100d99:	c9                   	leave  
f0100d9a:	c3                   	ret    

f0100d9b <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d9b:	55                   	push   %ebp
f0100d9c:	89 e5                	mov    %esp,%ebp
f0100d9e:	57                   	push   %edi
f0100d9f:	56                   	push   %esi
f0100da0:	53                   	push   %ebx
f0100da1:	83 ec 2c             	sub    $0x2c,%esp
f0100da4:	8b 75 08             	mov    0x8(%ebp),%esi
f0100da7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100daa:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100dad:	eb 12                	jmp    f0100dc1 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100daf:	85 c0                	test   %eax,%eax
f0100db1:	0f 84 89 03 00 00    	je     f0101140 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0100db7:	83 ec 08             	sub    $0x8,%esp
f0100dba:	53                   	push   %ebx
f0100dbb:	50                   	push   %eax
f0100dbc:	ff d6                	call   *%esi
f0100dbe:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100dc1:	83 c7 01             	add    $0x1,%edi
f0100dc4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100dc8:	83 f8 25             	cmp    $0x25,%eax
f0100dcb:	75 e2                	jne    f0100daf <vprintfmt+0x14>
f0100dcd:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100dd1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dd8:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ddf:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100de6:	ba 00 00 00 00       	mov    $0x0,%edx
f0100deb:	eb 07                	jmp    f0100df4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ded:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100df0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100df4:	8d 47 01             	lea    0x1(%edi),%eax
f0100df7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dfa:	0f b6 07             	movzbl (%edi),%eax
f0100dfd:	0f b6 c8             	movzbl %al,%ecx
f0100e00:	83 e8 23             	sub    $0x23,%eax
f0100e03:	3c 55                	cmp    $0x55,%al
f0100e05:	0f 87 1a 03 00 00    	ja     f0101125 <vprintfmt+0x38a>
f0100e0b:	0f b6 c0             	movzbl %al,%eax
f0100e0e:	ff 24 85 48 1e 10 f0 	jmp    *-0xfefe1b8(,%eax,4)
f0100e15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e18:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e1c:	eb d6                	jmp    f0100df4 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e21:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e26:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e29:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e2c:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100e30:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100e33:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100e36:	83 fa 09             	cmp    $0x9,%edx
f0100e39:	77 39                	ja     f0100e74 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e3b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e3e:	eb e9                	jmp    f0100e29 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e40:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e43:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e46:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e49:	8b 00                	mov    (%eax),%eax
f0100e4b:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e4e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e51:	eb 27                	jmp    f0100e7a <vprintfmt+0xdf>
f0100e53:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e56:	85 c0                	test   %eax,%eax
f0100e58:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e5d:	0f 49 c8             	cmovns %eax,%ecx
f0100e60:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e63:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e66:	eb 8c                	jmp    f0100df4 <vprintfmt+0x59>
f0100e68:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e6b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e72:	eb 80                	jmp    f0100df4 <vprintfmt+0x59>
f0100e74:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e77:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e7a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e7e:	0f 89 70 ff ff ff    	jns    f0100df4 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e84:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e87:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e8a:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e91:	e9 5e ff ff ff       	jmp    f0100df4 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e96:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e9c:	e9 53 ff ff ff       	jmp    f0100df4 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ea1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ea4:	8d 50 04             	lea    0x4(%eax),%edx
f0100ea7:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eaa:	83 ec 08             	sub    $0x8,%esp
f0100ead:	53                   	push   %ebx
f0100eae:	ff 30                	pushl  (%eax)
f0100eb0:	ff d6                	call   *%esi
			break;
f0100eb2:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eb5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100eb8:	e9 04 ff ff ff       	jmp    f0100dc1 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ebd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ec0:	8d 50 04             	lea    0x4(%eax),%edx
f0100ec3:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ec6:	8b 00                	mov    (%eax),%eax
f0100ec8:	99                   	cltd   
f0100ec9:	31 d0                	xor    %edx,%eax
f0100ecb:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ecd:	83 f8 06             	cmp    $0x6,%eax
f0100ed0:	7f 0b                	jg     f0100edd <vprintfmt+0x142>
f0100ed2:	8b 14 85 a0 1f 10 f0 	mov    -0xfefe060(,%eax,4),%edx
f0100ed9:	85 d2                	test   %edx,%edx
f0100edb:	75 18                	jne    f0100ef5 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0100edd:	50                   	push   %eax
f0100ede:	68 d1 1d 10 f0       	push   $0xf0101dd1
f0100ee3:	53                   	push   %ebx
f0100ee4:	56                   	push   %esi
f0100ee5:	e8 94 fe ff ff       	call   f0100d7e <printfmt>
f0100eea:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ef0:	e9 cc fe ff ff       	jmp    f0100dc1 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100ef5:	52                   	push   %edx
f0100ef6:	68 da 1d 10 f0       	push   $0xf0101dda
f0100efb:	53                   	push   %ebx
f0100efc:	56                   	push   %esi
f0100efd:	e8 7c fe ff ff       	call   f0100d7e <printfmt>
f0100f02:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f05:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f08:	e9 b4 fe ff ff       	jmp    f0100dc1 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f10:	8d 50 04             	lea    0x4(%eax),%edx
f0100f13:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f16:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f18:	85 ff                	test   %edi,%edi
f0100f1a:	b8 ca 1d 10 f0       	mov    $0xf0101dca,%eax
f0100f1f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f22:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f26:	0f 8e 94 00 00 00    	jle    f0100fc0 <vprintfmt+0x225>
f0100f2c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f30:	0f 84 98 00 00 00    	je     f0100fce <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f36:	83 ec 08             	sub    $0x8,%esp
f0100f39:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f3c:	57                   	push   %edi
f0100f3d:	e8 5f 03 00 00       	call   f01012a1 <strnlen>
f0100f42:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f45:	29 c1                	sub    %eax,%ecx
f0100f47:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0100f4a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f4d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f51:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f54:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f57:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f59:	eb 0f                	jmp    f0100f6a <vprintfmt+0x1cf>
					putch(padc, putdat);
f0100f5b:	83 ec 08             	sub    $0x8,%esp
f0100f5e:	53                   	push   %ebx
f0100f5f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f62:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f64:	83 ef 01             	sub    $0x1,%edi
f0100f67:	83 c4 10             	add    $0x10,%esp
f0100f6a:	85 ff                	test   %edi,%edi
f0100f6c:	7f ed                	jg     f0100f5b <vprintfmt+0x1c0>
f0100f6e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f71:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100f74:	85 c9                	test   %ecx,%ecx
f0100f76:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f7b:	0f 49 c1             	cmovns %ecx,%eax
f0100f7e:	29 c1                	sub    %eax,%ecx
f0100f80:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f83:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f86:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f89:	89 cb                	mov    %ecx,%ebx
f0100f8b:	eb 4d                	jmp    f0100fda <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f8d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f91:	74 1b                	je     f0100fae <vprintfmt+0x213>
f0100f93:	0f be c0             	movsbl %al,%eax
f0100f96:	83 e8 20             	sub    $0x20,%eax
f0100f99:	83 f8 5e             	cmp    $0x5e,%eax
f0100f9c:	76 10                	jbe    f0100fae <vprintfmt+0x213>
					putch('?', putdat);
f0100f9e:	83 ec 08             	sub    $0x8,%esp
f0100fa1:	ff 75 0c             	pushl  0xc(%ebp)
f0100fa4:	6a 3f                	push   $0x3f
f0100fa6:	ff 55 08             	call   *0x8(%ebp)
f0100fa9:	83 c4 10             	add    $0x10,%esp
f0100fac:	eb 0d                	jmp    f0100fbb <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0100fae:	83 ec 08             	sub    $0x8,%esp
f0100fb1:	ff 75 0c             	pushl  0xc(%ebp)
f0100fb4:	52                   	push   %edx
f0100fb5:	ff 55 08             	call   *0x8(%ebp)
f0100fb8:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fbb:	83 eb 01             	sub    $0x1,%ebx
f0100fbe:	eb 1a                	jmp    f0100fda <vprintfmt+0x23f>
f0100fc0:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fc3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fc6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fc9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fcc:	eb 0c                	jmp    f0100fda <vprintfmt+0x23f>
f0100fce:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fd1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fd4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fd7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fda:	83 c7 01             	add    $0x1,%edi
f0100fdd:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100fe1:	0f be d0             	movsbl %al,%edx
f0100fe4:	85 d2                	test   %edx,%edx
f0100fe6:	74 23                	je     f010100b <vprintfmt+0x270>
f0100fe8:	85 f6                	test   %esi,%esi
f0100fea:	78 a1                	js     f0100f8d <vprintfmt+0x1f2>
f0100fec:	83 ee 01             	sub    $0x1,%esi
f0100fef:	79 9c                	jns    f0100f8d <vprintfmt+0x1f2>
f0100ff1:	89 df                	mov    %ebx,%edi
f0100ff3:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ff6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ff9:	eb 18                	jmp    f0101013 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100ffb:	83 ec 08             	sub    $0x8,%esp
f0100ffe:	53                   	push   %ebx
f0100fff:	6a 20                	push   $0x20
f0101001:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101003:	83 ef 01             	sub    $0x1,%edi
f0101006:	83 c4 10             	add    $0x10,%esp
f0101009:	eb 08                	jmp    f0101013 <vprintfmt+0x278>
f010100b:	89 df                	mov    %ebx,%edi
f010100d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101010:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101013:	85 ff                	test   %edi,%edi
f0101015:	7f e4                	jg     f0100ffb <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101017:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010101a:	e9 a2 fd ff ff       	jmp    f0100dc1 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010101f:	83 fa 01             	cmp    $0x1,%edx
f0101022:	7e 16                	jle    f010103a <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101024:	8b 45 14             	mov    0x14(%ebp),%eax
f0101027:	8d 50 08             	lea    0x8(%eax),%edx
f010102a:	89 55 14             	mov    %edx,0x14(%ebp)
f010102d:	8b 50 04             	mov    0x4(%eax),%edx
f0101030:	8b 00                	mov    (%eax),%eax
f0101032:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101035:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101038:	eb 32                	jmp    f010106c <vprintfmt+0x2d1>
	else if (lflag)
f010103a:	85 d2                	test   %edx,%edx
f010103c:	74 18                	je     f0101056 <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f010103e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101041:	8d 50 04             	lea    0x4(%eax),%edx
f0101044:	89 55 14             	mov    %edx,0x14(%ebp)
f0101047:	8b 00                	mov    (%eax),%eax
f0101049:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010104c:	89 c1                	mov    %eax,%ecx
f010104e:	c1 f9 1f             	sar    $0x1f,%ecx
f0101051:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101054:	eb 16                	jmp    f010106c <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101056:	8b 45 14             	mov    0x14(%ebp),%eax
f0101059:	8d 50 04             	lea    0x4(%eax),%edx
f010105c:	89 55 14             	mov    %edx,0x14(%ebp)
f010105f:	8b 00                	mov    (%eax),%eax
f0101061:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101064:	89 c1                	mov    %eax,%ecx
f0101066:	c1 f9 1f             	sar    $0x1f,%ecx
f0101069:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010106c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010106f:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101072:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101077:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010107b:	79 74                	jns    f01010f1 <vprintfmt+0x356>
				putch('-', putdat);
f010107d:	83 ec 08             	sub    $0x8,%esp
f0101080:	53                   	push   %ebx
f0101081:	6a 2d                	push   $0x2d
f0101083:	ff d6                	call   *%esi
				num = -(long long) num;
f0101085:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101088:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010108b:	f7 d8                	neg    %eax
f010108d:	83 d2 00             	adc    $0x0,%edx
f0101090:	f7 da                	neg    %edx
f0101092:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101095:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010109a:	eb 55                	jmp    f01010f1 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010109c:	8d 45 14             	lea    0x14(%ebp),%eax
f010109f:	e8 83 fc ff ff       	call   f0100d27 <getuint>
			base = 10;
f01010a4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010a9:	eb 46                	jmp    f01010f1 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01010ab:	8d 45 14             	lea    0x14(%ebp),%eax
f01010ae:	e8 74 fc ff ff       	call   f0100d27 <getuint>
			base = 8;
f01010b3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01010b8:	eb 37                	jmp    f01010f1 <vprintfmt+0x356>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01010ba:	83 ec 08             	sub    $0x8,%esp
f01010bd:	53                   	push   %ebx
f01010be:	6a 30                	push   $0x30
f01010c0:	ff d6                	call   *%esi
			putch('x', putdat);
f01010c2:	83 c4 08             	add    $0x8,%esp
f01010c5:	53                   	push   %ebx
f01010c6:	6a 78                	push   $0x78
f01010c8:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010ca:	8b 45 14             	mov    0x14(%ebp),%eax
f01010cd:	8d 50 04             	lea    0x4(%eax),%edx
f01010d0:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010d3:	8b 00                	mov    (%eax),%eax
f01010d5:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01010da:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010dd:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01010e2:	eb 0d                	jmp    f01010f1 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010e4:	8d 45 14             	lea    0x14(%ebp),%eax
f01010e7:	e8 3b fc ff ff       	call   f0100d27 <getuint>
			base = 16;
f01010ec:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010f1:	83 ec 0c             	sub    $0xc,%esp
f01010f4:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01010f8:	57                   	push   %edi
f01010f9:	ff 75 e0             	pushl  -0x20(%ebp)
f01010fc:	51                   	push   %ecx
f01010fd:	52                   	push   %edx
f01010fe:	50                   	push   %eax
f01010ff:	89 da                	mov    %ebx,%edx
f0101101:	89 f0                	mov    %esi,%eax
f0101103:	e8 70 fb ff ff       	call   f0100c78 <printnum>
			break;
f0101108:	83 c4 20             	add    $0x20,%esp
f010110b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010110e:	e9 ae fc ff ff       	jmp    f0100dc1 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101113:	83 ec 08             	sub    $0x8,%esp
f0101116:	53                   	push   %ebx
f0101117:	51                   	push   %ecx
f0101118:	ff d6                	call   *%esi
			break;
f010111a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010111d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101120:	e9 9c fc ff ff       	jmp    f0100dc1 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101125:	83 ec 08             	sub    $0x8,%esp
f0101128:	53                   	push   %ebx
f0101129:	6a 25                	push   $0x25
f010112b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010112d:	83 c4 10             	add    $0x10,%esp
f0101130:	eb 03                	jmp    f0101135 <vprintfmt+0x39a>
f0101132:	83 ef 01             	sub    $0x1,%edi
f0101135:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101139:	75 f7                	jne    f0101132 <vprintfmt+0x397>
f010113b:	e9 81 fc ff ff       	jmp    f0100dc1 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101140:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101143:	5b                   	pop    %ebx
f0101144:	5e                   	pop    %esi
f0101145:	5f                   	pop    %edi
f0101146:	5d                   	pop    %ebp
f0101147:	c3                   	ret    

f0101148 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101148:	55                   	push   %ebp
f0101149:	89 e5                	mov    %esp,%ebp
f010114b:	83 ec 18             	sub    $0x18,%esp
f010114e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101151:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101154:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101157:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010115b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010115e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101165:	85 c0                	test   %eax,%eax
f0101167:	74 26                	je     f010118f <vsnprintf+0x47>
f0101169:	85 d2                	test   %edx,%edx
f010116b:	7e 22                	jle    f010118f <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010116d:	ff 75 14             	pushl  0x14(%ebp)
f0101170:	ff 75 10             	pushl  0x10(%ebp)
f0101173:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101176:	50                   	push   %eax
f0101177:	68 61 0d 10 f0       	push   $0xf0100d61
f010117c:	e8 1a fc ff ff       	call   f0100d9b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101181:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101184:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101187:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010118a:	83 c4 10             	add    $0x10,%esp
f010118d:	eb 05                	jmp    f0101194 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010118f:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101194:	c9                   	leave  
f0101195:	c3                   	ret    

f0101196 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101196:	55                   	push   %ebp
f0101197:	89 e5                	mov    %esp,%ebp
f0101199:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010119c:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010119f:	50                   	push   %eax
f01011a0:	ff 75 10             	pushl  0x10(%ebp)
f01011a3:	ff 75 0c             	pushl  0xc(%ebp)
f01011a6:	ff 75 08             	pushl  0x8(%ebp)
f01011a9:	e8 9a ff ff ff       	call   f0101148 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011ae:	c9                   	leave  
f01011af:	c3                   	ret    

f01011b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011b0:	55                   	push   %ebp
f01011b1:	89 e5                	mov    %esp,%ebp
f01011b3:	57                   	push   %edi
f01011b4:	56                   	push   %esi
f01011b5:	53                   	push   %ebx
f01011b6:	83 ec 0c             	sub    $0xc,%esp
f01011b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011bc:	85 c0                	test   %eax,%eax
f01011be:	74 11                	je     f01011d1 <readline+0x21>
		cprintf("%s", prompt);
f01011c0:	83 ec 08             	sub    $0x8,%esp
f01011c3:	50                   	push   %eax
f01011c4:	68 da 1d 10 f0       	push   $0xf0101dda
f01011c9:	e8 82 f7 ff ff       	call   f0100950 <cprintf>
f01011ce:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01011d1:	83 ec 0c             	sub    $0xc,%esp
f01011d4:	6a 00                	push   $0x0
f01011d6:	e8 7e f4 ff ff       	call   f0100659 <iscons>
f01011db:	89 c7                	mov    %eax,%edi
f01011dd:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01011e0:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01011e5:	e8 5e f4 ff ff       	call   f0100648 <getchar>
f01011ea:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011ec:	85 c0                	test   %eax,%eax
f01011ee:	79 18                	jns    f0101208 <readline+0x58>
			cprintf("read error: %e\n", c);
f01011f0:	83 ec 08             	sub    $0x8,%esp
f01011f3:	50                   	push   %eax
f01011f4:	68 bc 1f 10 f0       	push   $0xf0101fbc
f01011f9:	e8 52 f7 ff ff       	call   f0100950 <cprintf>
			return NULL;
f01011fe:	83 c4 10             	add    $0x10,%esp
f0101201:	b8 00 00 00 00       	mov    $0x0,%eax
f0101206:	eb 79                	jmp    f0101281 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101208:	83 f8 08             	cmp    $0x8,%eax
f010120b:	0f 94 c2             	sete   %dl
f010120e:	83 f8 7f             	cmp    $0x7f,%eax
f0101211:	0f 94 c0             	sete   %al
f0101214:	08 c2                	or     %al,%dl
f0101216:	74 1a                	je     f0101232 <readline+0x82>
f0101218:	85 f6                	test   %esi,%esi
f010121a:	7e 16                	jle    f0101232 <readline+0x82>
			if (echoing)
f010121c:	85 ff                	test   %edi,%edi
f010121e:	74 0d                	je     f010122d <readline+0x7d>
				cputchar('\b');
f0101220:	83 ec 0c             	sub    $0xc,%esp
f0101223:	6a 08                	push   $0x8
f0101225:	e8 0e f4 ff ff       	call   f0100638 <cputchar>
f010122a:	83 c4 10             	add    $0x10,%esp
			i--;
f010122d:	83 ee 01             	sub    $0x1,%esi
f0101230:	eb b3                	jmp    f01011e5 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101232:	83 fb 1f             	cmp    $0x1f,%ebx
f0101235:	7e 23                	jle    f010125a <readline+0xaa>
f0101237:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010123d:	7f 1b                	jg     f010125a <readline+0xaa>
			if (echoing)
f010123f:	85 ff                	test   %edi,%edi
f0101241:	74 0c                	je     f010124f <readline+0x9f>
				cputchar(c);
f0101243:	83 ec 0c             	sub    $0xc,%esp
f0101246:	53                   	push   %ebx
f0101247:	e8 ec f3 ff ff       	call   f0100638 <cputchar>
f010124c:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010124f:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101255:	8d 76 01             	lea    0x1(%esi),%esi
f0101258:	eb 8b                	jmp    f01011e5 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010125a:	83 fb 0a             	cmp    $0xa,%ebx
f010125d:	74 05                	je     f0101264 <readline+0xb4>
f010125f:	83 fb 0d             	cmp    $0xd,%ebx
f0101262:	75 81                	jne    f01011e5 <readline+0x35>
			if (echoing)
f0101264:	85 ff                	test   %edi,%edi
f0101266:	74 0d                	je     f0101275 <readline+0xc5>
				cputchar('\n');
f0101268:	83 ec 0c             	sub    $0xc,%esp
f010126b:	6a 0a                	push   $0xa
f010126d:	e8 c6 f3 ff ff       	call   f0100638 <cputchar>
f0101272:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101275:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010127c:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101281:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101284:	5b                   	pop    %ebx
f0101285:	5e                   	pop    %esi
f0101286:	5f                   	pop    %edi
f0101287:	5d                   	pop    %ebp
f0101288:	c3                   	ret    

f0101289 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101289:	55                   	push   %ebp
f010128a:	89 e5                	mov    %esp,%ebp
f010128c:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010128f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101294:	eb 03                	jmp    f0101299 <strlen+0x10>
		n++;
f0101296:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101299:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010129d:	75 f7                	jne    f0101296 <strlen+0xd>
		n++;
	return n;
}
f010129f:	5d                   	pop    %ebp
f01012a0:	c3                   	ret    

f01012a1 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012a1:	55                   	push   %ebp
f01012a2:	89 e5                	mov    %esp,%ebp
f01012a4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012a7:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012aa:	ba 00 00 00 00       	mov    $0x0,%edx
f01012af:	eb 03                	jmp    f01012b4 <strnlen+0x13>
		n++;
f01012b1:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012b4:	39 c2                	cmp    %eax,%edx
f01012b6:	74 08                	je     f01012c0 <strnlen+0x1f>
f01012b8:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01012bc:	75 f3                	jne    f01012b1 <strnlen+0x10>
f01012be:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01012c0:	5d                   	pop    %ebp
f01012c1:	c3                   	ret    

f01012c2 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01012c2:	55                   	push   %ebp
f01012c3:	89 e5                	mov    %esp,%ebp
f01012c5:	53                   	push   %ebx
f01012c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01012cc:	89 c2                	mov    %eax,%edx
f01012ce:	83 c2 01             	add    $0x1,%edx
f01012d1:	83 c1 01             	add    $0x1,%ecx
f01012d4:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01012d8:	88 5a ff             	mov    %bl,-0x1(%edx)
f01012db:	84 db                	test   %bl,%bl
f01012dd:	75 ef                	jne    f01012ce <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01012df:	5b                   	pop    %ebx
f01012e0:	5d                   	pop    %ebp
f01012e1:	c3                   	ret    

f01012e2 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01012e2:	55                   	push   %ebp
f01012e3:	89 e5                	mov    %esp,%ebp
f01012e5:	53                   	push   %ebx
f01012e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01012e9:	53                   	push   %ebx
f01012ea:	e8 9a ff ff ff       	call   f0101289 <strlen>
f01012ef:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01012f2:	ff 75 0c             	pushl  0xc(%ebp)
f01012f5:	01 d8                	add    %ebx,%eax
f01012f7:	50                   	push   %eax
f01012f8:	e8 c5 ff ff ff       	call   f01012c2 <strcpy>
	return dst;
}
f01012fd:	89 d8                	mov    %ebx,%eax
f01012ff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101302:	c9                   	leave  
f0101303:	c3                   	ret    

f0101304 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101304:	55                   	push   %ebp
f0101305:	89 e5                	mov    %esp,%ebp
f0101307:	56                   	push   %esi
f0101308:	53                   	push   %ebx
f0101309:	8b 75 08             	mov    0x8(%ebp),%esi
f010130c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010130f:	89 f3                	mov    %esi,%ebx
f0101311:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101314:	89 f2                	mov    %esi,%edx
f0101316:	eb 0f                	jmp    f0101327 <strncpy+0x23>
		*dst++ = *src;
f0101318:	83 c2 01             	add    $0x1,%edx
f010131b:	0f b6 01             	movzbl (%ecx),%eax
f010131e:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101321:	80 39 01             	cmpb   $0x1,(%ecx)
f0101324:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101327:	39 da                	cmp    %ebx,%edx
f0101329:	75 ed                	jne    f0101318 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010132b:	89 f0                	mov    %esi,%eax
f010132d:	5b                   	pop    %ebx
f010132e:	5e                   	pop    %esi
f010132f:	5d                   	pop    %ebp
f0101330:	c3                   	ret    

f0101331 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101331:	55                   	push   %ebp
f0101332:	89 e5                	mov    %esp,%ebp
f0101334:	56                   	push   %esi
f0101335:	53                   	push   %ebx
f0101336:	8b 75 08             	mov    0x8(%ebp),%esi
f0101339:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010133c:	8b 55 10             	mov    0x10(%ebp),%edx
f010133f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101341:	85 d2                	test   %edx,%edx
f0101343:	74 21                	je     f0101366 <strlcpy+0x35>
f0101345:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101349:	89 f2                	mov    %esi,%edx
f010134b:	eb 09                	jmp    f0101356 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010134d:	83 c2 01             	add    $0x1,%edx
f0101350:	83 c1 01             	add    $0x1,%ecx
f0101353:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101356:	39 c2                	cmp    %eax,%edx
f0101358:	74 09                	je     f0101363 <strlcpy+0x32>
f010135a:	0f b6 19             	movzbl (%ecx),%ebx
f010135d:	84 db                	test   %bl,%bl
f010135f:	75 ec                	jne    f010134d <strlcpy+0x1c>
f0101361:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101363:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101366:	29 f0                	sub    %esi,%eax
}
f0101368:	5b                   	pop    %ebx
f0101369:	5e                   	pop    %esi
f010136a:	5d                   	pop    %ebp
f010136b:	c3                   	ret    

f010136c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010136c:	55                   	push   %ebp
f010136d:	89 e5                	mov    %esp,%ebp
f010136f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101372:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101375:	eb 06                	jmp    f010137d <strcmp+0x11>
		p++, q++;
f0101377:	83 c1 01             	add    $0x1,%ecx
f010137a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010137d:	0f b6 01             	movzbl (%ecx),%eax
f0101380:	84 c0                	test   %al,%al
f0101382:	74 04                	je     f0101388 <strcmp+0x1c>
f0101384:	3a 02                	cmp    (%edx),%al
f0101386:	74 ef                	je     f0101377 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101388:	0f b6 c0             	movzbl %al,%eax
f010138b:	0f b6 12             	movzbl (%edx),%edx
f010138e:	29 d0                	sub    %edx,%eax
}
f0101390:	5d                   	pop    %ebp
f0101391:	c3                   	ret    

f0101392 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101392:	55                   	push   %ebp
f0101393:	89 e5                	mov    %esp,%ebp
f0101395:	53                   	push   %ebx
f0101396:	8b 45 08             	mov    0x8(%ebp),%eax
f0101399:	8b 55 0c             	mov    0xc(%ebp),%edx
f010139c:	89 c3                	mov    %eax,%ebx
f010139e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01013a1:	eb 06                	jmp    f01013a9 <strncmp+0x17>
		n--, p++, q++;
f01013a3:	83 c0 01             	add    $0x1,%eax
f01013a6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013a9:	39 d8                	cmp    %ebx,%eax
f01013ab:	74 15                	je     f01013c2 <strncmp+0x30>
f01013ad:	0f b6 08             	movzbl (%eax),%ecx
f01013b0:	84 c9                	test   %cl,%cl
f01013b2:	74 04                	je     f01013b8 <strncmp+0x26>
f01013b4:	3a 0a                	cmp    (%edx),%cl
f01013b6:	74 eb                	je     f01013a3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01013b8:	0f b6 00             	movzbl (%eax),%eax
f01013bb:	0f b6 12             	movzbl (%edx),%edx
f01013be:	29 d0                	sub    %edx,%eax
f01013c0:	eb 05                	jmp    f01013c7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013c2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01013c7:	5b                   	pop    %ebx
f01013c8:	5d                   	pop    %ebp
f01013c9:	c3                   	ret    

f01013ca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01013ca:	55                   	push   %ebp
f01013cb:	89 e5                	mov    %esp,%ebp
f01013cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013d4:	eb 07                	jmp    f01013dd <strchr+0x13>
		if (*s == c)
f01013d6:	38 ca                	cmp    %cl,%dl
f01013d8:	74 0f                	je     f01013e9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01013da:	83 c0 01             	add    $0x1,%eax
f01013dd:	0f b6 10             	movzbl (%eax),%edx
f01013e0:	84 d2                	test   %dl,%dl
f01013e2:	75 f2                	jne    f01013d6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01013e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01013e9:	5d                   	pop    %ebp
f01013ea:	c3                   	ret    

f01013eb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01013eb:	55                   	push   %ebp
f01013ec:	89 e5                	mov    %esp,%ebp
f01013ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01013f1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01013f5:	eb 03                	jmp    f01013fa <strfind+0xf>
f01013f7:	83 c0 01             	add    $0x1,%eax
f01013fa:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01013fd:	38 ca                	cmp    %cl,%dl
f01013ff:	74 04                	je     f0101405 <strfind+0x1a>
f0101401:	84 d2                	test   %dl,%dl
f0101403:	75 f2                	jne    f01013f7 <strfind+0xc>
			break;
	return (char *) s;
}
f0101405:	5d                   	pop    %ebp
f0101406:	c3                   	ret    

f0101407 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101407:	55                   	push   %ebp
f0101408:	89 e5                	mov    %esp,%ebp
f010140a:	57                   	push   %edi
f010140b:	56                   	push   %esi
f010140c:	53                   	push   %ebx
f010140d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101410:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101413:	85 c9                	test   %ecx,%ecx
f0101415:	74 36                	je     f010144d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101417:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010141d:	75 28                	jne    f0101447 <memset+0x40>
f010141f:	f6 c1 03             	test   $0x3,%cl
f0101422:	75 23                	jne    f0101447 <memset+0x40>
		c &= 0xFF;
f0101424:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101428:	89 d3                	mov    %edx,%ebx
f010142a:	c1 e3 08             	shl    $0x8,%ebx
f010142d:	89 d6                	mov    %edx,%esi
f010142f:	c1 e6 18             	shl    $0x18,%esi
f0101432:	89 d0                	mov    %edx,%eax
f0101434:	c1 e0 10             	shl    $0x10,%eax
f0101437:	09 f0                	or     %esi,%eax
f0101439:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010143b:	89 d8                	mov    %ebx,%eax
f010143d:	09 d0                	or     %edx,%eax
f010143f:	c1 e9 02             	shr    $0x2,%ecx
f0101442:	fc                   	cld    
f0101443:	f3 ab                	rep stos %eax,%es:(%edi)
f0101445:	eb 06                	jmp    f010144d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101447:	8b 45 0c             	mov    0xc(%ebp),%eax
f010144a:	fc                   	cld    
f010144b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010144d:	89 f8                	mov    %edi,%eax
f010144f:	5b                   	pop    %ebx
f0101450:	5e                   	pop    %esi
f0101451:	5f                   	pop    %edi
f0101452:	5d                   	pop    %ebp
f0101453:	c3                   	ret    

f0101454 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101454:	55                   	push   %ebp
f0101455:	89 e5                	mov    %esp,%ebp
f0101457:	57                   	push   %edi
f0101458:	56                   	push   %esi
f0101459:	8b 45 08             	mov    0x8(%ebp),%eax
f010145c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010145f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101462:	39 c6                	cmp    %eax,%esi
f0101464:	73 35                	jae    f010149b <memmove+0x47>
f0101466:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101469:	39 d0                	cmp    %edx,%eax
f010146b:	73 2e                	jae    f010149b <memmove+0x47>
		s += n;
		d += n;
f010146d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101470:	89 d6                	mov    %edx,%esi
f0101472:	09 fe                	or     %edi,%esi
f0101474:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010147a:	75 13                	jne    f010148f <memmove+0x3b>
f010147c:	f6 c1 03             	test   $0x3,%cl
f010147f:	75 0e                	jne    f010148f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101481:	83 ef 04             	sub    $0x4,%edi
f0101484:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101487:	c1 e9 02             	shr    $0x2,%ecx
f010148a:	fd                   	std    
f010148b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010148d:	eb 09                	jmp    f0101498 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010148f:	83 ef 01             	sub    $0x1,%edi
f0101492:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101495:	fd                   	std    
f0101496:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101498:	fc                   	cld    
f0101499:	eb 1d                	jmp    f01014b8 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010149b:	89 f2                	mov    %esi,%edx
f010149d:	09 c2                	or     %eax,%edx
f010149f:	f6 c2 03             	test   $0x3,%dl
f01014a2:	75 0f                	jne    f01014b3 <memmove+0x5f>
f01014a4:	f6 c1 03             	test   $0x3,%cl
f01014a7:	75 0a                	jne    f01014b3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01014a9:	c1 e9 02             	shr    $0x2,%ecx
f01014ac:	89 c7                	mov    %eax,%edi
f01014ae:	fc                   	cld    
f01014af:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014b1:	eb 05                	jmp    f01014b8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01014b3:	89 c7                	mov    %eax,%edi
f01014b5:	fc                   	cld    
f01014b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01014b8:	5e                   	pop    %esi
f01014b9:	5f                   	pop    %edi
f01014ba:	5d                   	pop    %ebp
f01014bb:	c3                   	ret    

f01014bc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01014bc:	55                   	push   %ebp
f01014bd:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01014bf:	ff 75 10             	pushl  0x10(%ebp)
f01014c2:	ff 75 0c             	pushl  0xc(%ebp)
f01014c5:	ff 75 08             	pushl  0x8(%ebp)
f01014c8:	e8 87 ff ff ff       	call   f0101454 <memmove>
}
f01014cd:	c9                   	leave  
f01014ce:	c3                   	ret    

f01014cf <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01014cf:	55                   	push   %ebp
f01014d0:	89 e5                	mov    %esp,%ebp
f01014d2:	56                   	push   %esi
f01014d3:	53                   	push   %ebx
f01014d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014da:	89 c6                	mov    %eax,%esi
f01014dc:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014df:	eb 1a                	jmp    f01014fb <memcmp+0x2c>
		if (*s1 != *s2)
f01014e1:	0f b6 08             	movzbl (%eax),%ecx
f01014e4:	0f b6 1a             	movzbl (%edx),%ebx
f01014e7:	38 d9                	cmp    %bl,%cl
f01014e9:	74 0a                	je     f01014f5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01014eb:	0f b6 c1             	movzbl %cl,%eax
f01014ee:	0f b6 db             	movzbl %bl,%ebx
f01014f1:	29 d8                	sub    %ebx,%eax
f01014f3:	eb 0f                	jmp    f0101504 <memcmp+0x35>
		s1++, s2++;
f01014f5:	83 c0 01             	add    $0x1,%eax
f01014f8:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01014fb:	39 f0                	cmp    %esi,%eax
f01014fd:	75 e2                	jne    f01014e1 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01014ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101504:	5b                   	pop    %ebx
f0101505:	5e                   	pop    %esi
f0101506:	5d                   	pop    %ebp
f0101507:	c3                   	ret    

f0101508 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101508:	55                   	push   %ebp
f0101509:	89 e5                	mov    %esp,%ebp
f010150b:	53                   	push   %ebx
f010150c:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010150f:	89 c1                	mov    %eax,%ecx
f0101511:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101514:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101518:	eb 0a                	jmp    f0101524 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010151a:	0f b6 10             	movzbl (%eax),%edx
f010151d:	39 da                	cmp    %ebx,%edx
f010151f:	74 07                	je     f0101528 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101521:	83 c0 01             	add    $0x1,%eax
f0101524:	39 c8                	cmp    %ecx,%eax
f0101526:	72 f2                	jb     f010151a <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101528:	5b                   	pop    %ebx
f0101529:	5d                   	pop    %ebp
f010152a:	c3                   	ret    

f010152b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010152b:	55                   	push   %ebp
f010152c:	89 e5                	mov    %esp,%ebp
f010152e:	57                   	push   %edi
f010152f:	56                   	push   %esi
f0101530:	53                   	push   %ebx
f0101531:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101534:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101537:	eb 03                	jmp    f010153c <strtol+0x11>
		s++;
f0101539:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010153c:	0f b6 01             	movzbl (%ecx),%eax
f010153f:	3c 20                	cmp    $0x20,%al
f0101541:	74 f6                	je     f0101539 <strtol+0xe>
f0101543:	3c 09                	cmp    $0x9,%al
f0101545:	74 f2                	je     f0101539 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101547:	3c 2b                	cmp    $0x2b,%al
f0101549:	75 0a                	jne    f0101555 <strtol+0x2a>
		s++;
f010154b:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010154e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101553:	eb 11                	jmp    f0101566 <strtol+0x3b>
f0101555:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010155a:	3c 2d                	cmp    $0x2d,%al
f010155c:	75 08                	jne    f0101566 <strtol+0x3b>
		s++, neg = 1;
f010155e:	83 c1 01             	add    $0x1,%ecx
f0101561:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101566:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010156c:	75 15                	jne    f0101583 <strtol+0x58>
f010156e:	80 39 30             	cmpb   $0x30,(%ecx)
f0101571:	75 10                	jne    f0101583 <strtol+0x58>
f0101573:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101577:	75 7c                	jne    f01015f5 <strtol+0xca>
		s += 2, base = 16;
f0101579:	83 c1 02             	add    $0x2,%ecx
f010157c:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101581:	eb 16                	jmp    f0101599 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101583:	85 db                	test   %ebx,%ebx
f0101585:	75 12                	jne    f0101599 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101587:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010158c:	80 39 30             	cmpb   $0x30,(%ecx)
f010158f:	75 08                	jne    f0101599 <strtol+0x6e>
		s++, base = 8;
f0101591:	83 c1 01             	add    $0x1,%ecx
f0101594:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101599:	b8 00 00 00 00       	mov    $0x0,%eax
f010159e:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01015a1:	0f b6 11             	movzbl (%ecx),%edx
f01015a4:	8d 72 d0             	lea    -0x30(%edx),%esi
f01015a7:	89 f3                	mov    %esi,%ebx
f01015a9:	80 fb 09             	cmp    $0x9,%bl
f01015ac:	77 08                	ja     f01015b6 <strtol+0x8b>
			dig = *s - '0';
f01015ae:	0f be d2             	movsbl %dl,%edx
f01015b1:	83 ea 30             	sub    $0x30,%edx
f01015b4:	eb 22                	jmp    f01015d8 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01015b6:	8d 72 9f             	lea    -0x61(%edx),%esi
f01015b9:	89 f3                	mov    %esi,%ebx
f01015bb:	80 fb 19             	cmp    $0x19,%bl
f01015be:	77 08                	ja     f01015c8 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01015c0:	0f be d2             	movsbl %dl,%edx
f01015c3:	83 ea 57             	sub    $0x57,%edx
f01015c6:	eb 10                	jmp    f01015d8 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01015c8:	8d 72 bf             	lea    -0x41(%edx),%esi
f01015cb:	89 f3                	mov    %esi,%ebx
f01015cd:	80 fb 19             	cmp    $0x19,%bl
f01015d0:	77 16                	ja     f01015e8 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01015d2:	0f be d2             	movsbl %dl,%edx
f01015d5:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01015d8:	3b 55 10             	cmp    0x10(%ebp),%edx
f01015db:	7d 0b                	jge    f01015e8 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01015dd:	83 c1 01             	add    $0x1,%ecx
f01015e0:	0f af 45 10          	imul   0x10(%ebp),%eax
f01015e4:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01015e6:	eb b9                	jmp    f01015a1 <strtol+0x76>

	if (endptr)
f01015e8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01015ec:	74 0d                	je     f01015fb <strtol+0xd0>
		*endptr = (char *) s;
f01015ee:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015f1:	89 0e                	mov    %ecx,(%esi)
f01015f3:	eb 06                	jmp    f01015fb <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015f5:	85 db                	test   %ebx,%ebx
f01015f7:	74 98                	je     f0101591 <strtol+0x66>
f01015f9:	eb 9e                	jmp    f0101599 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01015fb:	89 c2                	mov    %eax,%edx
f01015fd:	f7 da                	neg    %edx
f01015ff:	85 ff                	test   %edi,%edi
f0101601:	0f 45 c2             	cmovne %edx,%eax
}
f0101604:	5b                   	pop    %ebx
f0101605:	5e                   	pop    %esi
f0101606:	5f                   	pop    %edi
f0101607:	5d                   	pop    %ebp
f0101608:	c3                   	ret    
f0101609:	66 90                	xchg   %ax,%ax
f010160b:	66 90                	xchg   %ax,%ax
f010160d:	66 90                	xchg   %ax,%ax
f010160f:	90                   	nop

f0101610 <__udivdi3>:
f0101610:	55                   	push   %ebp
f0101611:	57                   	push   %edi
f0101612:	56                   	push   %esi
f0101613:	53                   	push   %ebx
f0101614:	83 ec 1c             	sub    $0x1c,%esp
f0101617:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010161b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010161f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101623:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101627:	85 f6                	test   %esi,%esi
f0101629:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010162d:	89 ca                	mov    %ecx,%edx
f010162f:	89 f8                	mov    %edi,%eax
f0101631:	75 3d                	jne    f0101670 <__udivdi3+0x60>
f0101633:	39 cf                	cmp    %ecx,%edi
f0101635:	0f 87 c5 00 00 00    	ja     f0101700 <__udivdi3+0xf0>
f010163b:	85 ff                	test   %edi,%edi
f010163d:	89 fd                	mov    %edi,%ebp
f010163f:	75 0b                	jne    f010164c <__udivdi3+0x3c>
f0101641:	b8 01 00 00 00       	mov    $0x1,%eax
f0101646:	31 d2                	xor    %edx,%edx
f0101648:	f7 f7                	div    %edi
f010164a:	89 c5                	mov    %eax,%ebp
f010164c:	89 c8                	mov    %ecx,%eax
f010164e:	31 d2                	xor    %edx,%edx
f0101650:	f7 f5                	div    %ebp
f0101652:	89 c1                	mov    %eax,%ecx
f0101654:	89 d8                	mov    %ebx,%eax
f0101656:	89 cf                	mov    %ecx,%edi
f0101658:	f7 f5                	div    %ebp
f010165a:	89 c3                	mov    %eax,%ebx
f010165c:	89 d8                	mov    %ebx,%eax
f010165e:	89 fa                	mov    %edi,%edx
f0101660:	83 c4 1c             	add    $0x1c,%esp
f0101663:	5b                   	pop    %ebx
f0101664:	5e                   	pop    %esi
f0101665:	5f                   	pop    %edi
f0101666:	5d                   	pop    %ebp
f0101667:	c3                   	ret    
f0101668:	90                   	nop
f0101669:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101670:	39 ce                	cmp    %ecx,%esi
f0101672:	77 74                	ja     f01016e8 <__udivdi3+0xd8>
f0101674:	0f bd fe             	bsr    %esi,%edi
f0101677:	83 f7 1f             	xor    $0x1f,%edi
f010167a:	0f 84 98 00 00 00    	je     f0101718 <__udivdi3+0x108>
f0101680:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101685:	89 f9                	mov    %edi,%ecx
f0101687:	89 c5                	mov    %eax,%ebp
f0101689:	29 fb                	sub    %edi,%ebx
f010168b:	d3 e6                	shl    %cl,%esi
f010168d:	89 d9                	mov    %ebx,%ecx
f010168f:	d3 ed                	shr    %cl,%ebp
f0101691:	89 f9                	mov    %edi,%ecx
f0101693:	d3 e0                	shl    %cl,%eax
f0101695:	09 ee                	or     %ebp,%esi
f0101697:	89 d9                	mov    %ebx,%ecx
f0101699:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010169d:	89 d5                	mov    %edx,%ebp
f010169f:	8b 44 24 08          	mov    0x8(%esp),%eax
f01016a3:	d3 ed                	shr    %cl,%ebp
f01016a5:	89 f9                	mov    %edi,%ecx
f01016a7:	d3 e2                	shl    %cl,%edx
f01016a9:	89 d9                	mov    %ebx,%ecx
f01016ab:	d3 e8                	shr    %cl,%eax
f01016ad:	09 c2                	or     %eax,%edx
f01016af:	89 d0                	mov    %edx,%eax
f01016b1:	89 ea                	mov    %ebp,%edx
f01016b3:	f7 f6                	div    %esi
f01016b5:	89 d5                	mov    %edx,%ebp
f01016b7:	89 c3                	mov    %eax,%ebx
f01016b9:	f7 64 24 0c          	mull   0xc(%esp)
f01016bd:	39 d5                	cmp    %edx,%ebp
f01016bf:	72 10                	jb     f01016d1 <__udivdi3+0xc1>
f01016c1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01016c5:	89 f9                	mov    %edi,%ecx
f01016c7:	d3 e6                	shl    %cl,%esi
f01016c9:	39 c6                	cmp    %eax,%esi
f01016cb:	73 07                	jae    f01016d4 <__udivdi3+0xc4>
f01016cd:	39 d5                	cmp    %edx,%ebp
f01016cf:	75 03                	jne    f01016d4 <__udivdi3+0xc4>
f01016d1:	83 eb 01             	sub    $0x1,%ebx
f01016d4:	31 ff                	xor    %edi,%edi
f01016d6:	89 d8                	mov    %ebx,%eax
f01016d8:	89 fa                	mov    %edi,%edx
f01016da:	83 c4 1c             	add    $0x1c,%esp
f01016dd:	5b                   	pop    %ebx
f01016de:	5e                   	pop    %esi
f01016df:	5f                   	pop    %edi
f01016e0:	5d                   	pop    %ebp
f01016e1:	c3                   	ret    
f01016e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016e8:	31 ff                	xor    %edi,%edi
f01016ea:	31 db                	xor    %ebx,%ebx
f01016ec:	89 d8                	mov    %ebx,%eax
f01016ee:	89 fa                	mov    %edi,%edx
f01016f0:	83 c4 1c             	add    $0x1c,%esp
f01016f3:	5b                   	pop    %ebx
f01016f4:	5e                   	pop    %esi
f01016f5:	5f                   	pop    %edi
f01016f6:	5d                   	pop    %ebp
f01016f7:	c3                   	ret    
f01016f8:	90                   	nop
f01016f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101700:	89 d8                	mov    %ebx,%eax
f0101702:	f7 f7                	div    %edi
f0101704:	31 ff                	xor    %edi,%edi
f0101706:	89 c3                	mov    %eax,%ebx
f0101708:	89 d8                	mov    %ebx,%eax
f010170a:	89 fa                	mov    %edi,%edx
f010170c:	83 c4 1c             	add    $0x1c,%esp
f010170f:	5b                   	pop    %ebx
f0101710:	5e                   	pop    %esi
f0101711:	5f                   	pop    %edi
f0101712:	5d                   	pop    %ebp
f0101713:	c3                   	ret    
f0101714:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101718:	39 ce                	cmp    %ecx,%esi
f010171a:	72 0c                	jb     f0101728 <__udivdi3+0x118>
f010171c:	31 db                	xor    %ebx,%ebx
f010171e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101722:	0f 87 34 ff ff ff    	ja     f010165c <__udivdi3+0x4c>
f0101728:	bb 01 00 00 00       	mov    $0x1,%ebx
f010172d:	e9 2a ff ff ff       	jmp    f010165c <__udivdi3+0x4c>
f0101732:	66 90                	xchg   %ax,%ax
f0101734:	66 90                	xchg   %ax,%ax
f0101736:	66 90                	xchg   %ax,%ax
f0101738:	66 90                	xchg   %ax,%ax
f010173a:	66 90                	xchg   %ax,%ax
f010173c:	66 90                	xchg   %ax,%ax
f010173e:	66 90                	xchg   %ax,%ax

f0101740 <__umoddi3>:
f0101740:	55                   	push   %ebp
f0101741:	57                   	push   %edi
f0101742:	56                   	push   %esi
f0101743:	53                   	push   %ebx
f0101744:	83 ec 1c             	sub    $0x1c,%esp
f0101747:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010174b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010174f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101753:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101757:	85 d2                	test   %edx,%edx
f0101759:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010175d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101761:	89 f3                	mov    %esi,%ebx
f0101763:	89 3c 24             	mov    %edi,(%esp)
f0101766:	89 74 24 04          	mov    %esi,0x4(%esp)
f010176a:	75 1c                	jne    f0101788 <__umoddi3+0x48>
f010176c:	39 f7                	cmp    %esi,%edi
f010176e:	76 50                	jbe    f01017c0 <__umoddi3+0x80>
f0101770:	89 c8                	mov    %ecx,%eax
f0101772:	89 f2                	mov    %esi,%edx
f0101774:	f7 f7                	div    %edi
f0101776:	89 d0                	mov    %edx,%eax
f0101778:	31 d2                	xor    %edx,%edx
f010177a:	83 c4 1c             	add    $0x1c,%esp
f010177d:	5b                   	pop    %ebx
f010177e:	5e                   	pop    %esi
f010177f:	5f                   	pop    %edi
f0101780:	5d                   	pop    %ebp
f0101781:	c3                   	ret    
f0101782:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101788:	39 f2                	cmp    %esi,%edx
f010178a:	89 d0                	mov    %edx,%eax
f010178c:	77 52                	ja     f01017e0 <__umoddi3+0xa0>
f010178e:	0f bd ea             	bsr    %edx,%ebp
f0101791:	83 f5 1f             	xor    $0x1f,%ebp
f0101794:	75 5a                	jne    f01017f0 <__umoddi3+0xb0>
f0101796:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010179a:	0f 82 e0 00 00 00    	jb     f0101880 <__umoddi3+0x140>
f01017a0:	39 0c 24             	cmp    %ecx,(%esp)
f01017a3:	0f 86 d7 00 00 00    	jbe    f0101880 <__umoddi3+0x140>
f01017a9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017ad:	8b 54 24 04          	mov    0x4(%esp),%edx
f01017b1:	83 c4 1c             	add    $0x1c,%esp
f01017b4:	5b                   	pop    %ebx
f01017b5:	5e                   	pop    %esi
f01017b6:	5f                   	pop    %edi
f01017b7:	5d                   	pop    %ebp
f01017b8:	c3                   	ret    
f01017b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017c0:	85 ff                	test   %edi,%edi
f01017c2:	89 fd                	mov    %edi,%ebp
f01017c4:	75 0b                	jne    f01017d1 <__umoddi3+0x91>
f01017c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01017cb:	31 d2                	xor    %edx,%edx
f01017cd:	f7 f7                	div    %edi
f01017cf:	89 c5                	mov    %eax,%ebp
f01017d1:	89 f0                	mov    %esi,%eax
f01017d3:	31 d2                	xor    %edx,%edx
f01017d5:	f7 f5                	div    %ebp
f01017d7:	89 c8                	mov    %ecx,%eax
f01017d9:	f7 f5                	div    %ebp
f01017db:	89 d0                	mov    %edx,%eax
f01017dd:	eb 99                	jmp    f0101778 <__umoddi3+0x38>
f01017df:	90                   	nop
f01017e0:	89 c8                	mov    %ecx,%eax
f01017e2:	89 f2                	mov    %esi,%edx
f01017e4:	83 c4 1c             	add    $0x1c,%esp
f01017e7:	5b                   	pop    %ebx
f01017e8:	5e                   	pop    %esi
f01017e9:	5f                   	pop    %edi
f01017ea:	5d                   	pop    %ebp
f01017eb:	c3                   	ret    
f01017ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017f0:	8b 34 24             	mov    (%esp),%esi
f01017f3:	bf 20 00 00 00       	mov    $0x20,%edi
f01017f8:	89 e9                	mov    %ebp,%ecx
f01017fa:	29 ef                	sub    %ebp,%edi
f01017fc:	d3 e0                	shl    %cl,%eax
f01017fe:	89 f9                	mov    %edi,%ecx
f0101800:	89 f2                	mov    %esi,%edx
f0101802:	d3 ea                	shr    %cl,%edx
f0101804:	89 e9                	mov    %ebp,%ecx
f0101806:	09 c2                	or     %eax,%edx
f0101808:	89 d8                	mov    %ebx,%eax
f010180a:	89 14 24             	mov    %edx,(%esp)
f010180d:	89 f2                	mov    %esi,%edx
f010180f:	d3 e2                	shl    %cl,%edx
f0101811:	89 f9                	mov    %edi,%ecx
f0101813:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101817:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010181b:	d3 e8                	shr    %cl,%eax
f010181d:	89 e9                	mov    %ebp,%ecx
f010181f:	89 c6                	mov    %eax,%esi
f0101821:	d3 e3                	shl    %cl,%ebx
f0101823:	89 f9                	mov    %edi,%ecx
f0101825:	89 d0                	mov    %edx,%eax
f0101827:	d3 e8                	shr    %cl,%eax
f0101829:	89 e9                	mov    %ebp,%ecx
f010182b:	09 d8                	or     %ebx,%eax
f010182d:	89 d3                	mov    %edx,%ebx
f010182f:	89 f2                	mov    %esi,%edx
f0101831:	f7 34 24             	divl   (%esp)
f0101834:	89 d6                	mov    %edx,%esi
f0101836:	d3 e3                	shl    %cl,%ebx
f0101838:	f7 64 24 04          	mull   0x4(%esp)
f010183c:	39 d6                	cmp    %edx,%esi
f010183e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101842:	89 d1                	mov    %edx,%ecx
f0101844:	89 c3                	mov    %eax,%ebx
f0101846:	72 08                	jb     f0101850 <__umoddi3+0x110>
f0101848:	75 11                	jne    f010185b <__umoddi3+0x11b>
f010184a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010184e:	73 0b                	jae    f010185b <__umoddi3+0x11b>
f0101850:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101854:	1b 14 24             	sbb    (%esp),%edx
f0101857:	89 d1                	mov    %edx,%ecx
f0101859:	89 c3                	mov    %eax,%ebx
f010185b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010185f:	29 da                	sub    %ebx,%edx
f0101861:	19 ce                	sbb    %ecx,%esi
f0101863:	89 f9                	mov    %edi,%ecx
f0101865:	89 f0                	mov    %esi,%eax
f0101867:	d3 e0                	shl    %cl,%eax
f0101869:	89 e9                	mov    %ebp,%ecx
f010186b:	d3 ea                	shr    %cl,%edx
f010186d:	89 e9                	mov    %ebp,%ecx
f010186f:	d3 ee                	shr    %cl,%esi
f0101871:	09 d0                	or     %edx,%eax
f0101873:	89 f2                	mov    %esi,%edx
f0101875:	83 c4 1c             	add    $0x1c,%esp
f0101878:	5b                   	pop    %ebx
f0101879:	5e                   	pop    %esi
f010187a:	5f                   	pop    %edi
f010187b:	5d                   	pop    %ebp
f010187c:	c3                   	ret    
f010187d:	8d 76 00             	lea    0x0(%esi),%esi
f0101880:	29 f9                	sub    %edi,%ecx
f0101882:	19 d6                	sbb    %edx,%esi
f0101884:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101888:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010188c:	e9 18 ff ff ff       	jmp    f01017a9 <__umoddi3+0x69>
