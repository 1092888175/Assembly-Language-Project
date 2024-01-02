# define NODE struct node
# struct node
# {
# 	Node* l;
# 	Node* r;
#   long value;
# }	
	.bss						# 在bss段声明三个全局变量
# NODE *head[2000000];			这里声明了2000000个NODE指针用于存储线段树的根节点，每个根节点代表一个历史版本
	.globl	head				# head是全局变量
	.align 32					# head对齐到32字节
	.type	head, @object		# head的类型是对象
	.size	head, 16000000		# head所占空间是2000000 * 8 = 16000000字节
head:							# head字段
	.zero	16000000			# 填充head字段，使用零填充
# long n,m						# 在bss段声明两个全局变量n，m
	.globl	n					# n是全局变量
	.align 8					# n对齐到8字节
	.type	n, @object			# n的类型是对象
	.size	n, 8				# n所占空间为8
n:								# n字段
	.zero	8					# 用0填充n所占的空间
# long n,m						# 同上
	.globl	m
	.align 8
	.type	m, @object
	.size	m, 8
m:
	.zero	8
# 开始代码字段
	.text
# void build(long l,long r, NODE** p)	# 声明Build函数，用于初始化最开始的线段树
	.globl	build				# build是全局的
	.type	build, @function	# build的类型是函数
build:							
	pushq	%rbp				# 保存栈底指针
	movq	%rsp, %rbp			# 将栈顶指针的值赋值给栈底指针，创建一个新栈
	subq	$48, %rsp			# 将栈顶指针减48，创建出一个拥有48字节空间的栈
	movq	%rdi, -24(%rbp)		# %rdi中存了第一个long参数l，将其存放在地址为(%rbp-24)的栈空间
	movq	%rsi, -32(%rbp)		# %rsi中存了第二个long参数r，将其存放在地址为(%rbp-32)的栈空间
	movq	%rdx, -40(%rbp)		# %rdx中存了第三个NODE**参数p，将其存放在地址为(%rbp-40)的栈空间
	movq	-40(%rbp), %rax		# 将参数p的值赋给%rax
# if(*p==(NODE*)NULL))
	movq	(%rax), %rax		# 参数p为指针，取参数p所指向的NODE*的值即*p，赋给%rax寄存器,
	testq	%rax, %rax			# testq测试%rax寄存器中的值是否为0
	jne	.L2						# 若不等于零，跳转到.L2
# (*p) == (NODE*)malloc(sizeof(NODE))
	movl	$24, %edi			# sizeof(NODE)的值为24，此处为malloc的第一个函数，意为malloc24字节的空间
	call	malloc@PLT			# 调用malloc分配空间
	movq	%rax, %rdx			# 将malloc分配到的空间地址赋给%rdx
	movq	-40(%rbp), %rax		# 将参数p的值赋给%rax
	movq	%rdx, (%rax)		# 将malloc分配到的内存地址写入到参数p指向的内存地址
.L2:
# if(l==r)
	movq	-24(%rbp), %rax		# 将参数l赋值给rax
	cmpq	-32(%rbp), %rax		# 比较参数l和参数r是否相等
	jne	.L3						# 若不相等，跳转到.L3
# (*p)->value = 0
	movq	-40(%rbp), %rax		# 将参数p的值赋给%rax
	movq	(%rax), %rax		# 取*p，赋给%rax
	movq	$0, 16(%rax)		# (*p)->value，即*p中第三个字段，相比于*p的起始地址偏移16位
# return
	jmp	.L1						# 函数返回
.L3:
# long mid = (l+r)/2
	movq	-24(%rbp), %rdx		# 取参数l赋值给%rdx
	movq	-32(%rbp), %rax		# 取参数r赋值给%rax
	addq	%rdx, %rax			# 参数l和参数r相加	
	movq	%rax, %rdx			# 将和赋值给%rdx
	# 使用移位优化来代替除法
	shrq	$63, %rdx
	addq	%rdx, %rax
	sarq	%rax				# 得到（l+r）/2 赋值给%rax
	movq	%rax, -8(%rbp)		# 将（l+r）/2存放到栈空间中
# build(l,mid,&(*p)->l)
	movq	-40(%rbp), %rax		# 取参数p赋值给rax
	movq	(%rax), %rax		# 取*p赋值给rax
	movq	%rax, %rdx			# 将*p赋值给%rdx（第三个参数)，此处*p即为&(*p)->l的地址值
	movq	-8(%rbp), %rcx		# 将(l+r)/2赋值给%rcx
	movq	-24(%rbp), %rax		# 将l赋值给%rax
	movq	%rcx, %rsi			# 将（l+r）/2赋值给%rsi（第二个参数）
	movq	%rax, %rdi			# 将l赋值给%rdi（第一个参数）
	call	build				# 调用build函数
# build(mid+1,r,&(*p)->r)
	movq	-40(%rbp), %rax		# 取参数p赋值给rax
	movq	(%rax), %rax		# 取*p赋值给rax
	leaq	8(%rax), %rdx		# 将%rax+8的值赋值给%rdx（第三个参数)，此处即为&(*p)->r的地址值
	movq	-8(%rbp), %rax		# 将(l+r)/2赋值给%rax
	leaq	1(%rax), %rcx		# 计算出%rax + 1赋值给%rcx
	movq	-32(%rbp), %rax		# 取参数r赋值给%rax
	movq	%rax, %rsi			# 将参数r赋值给%rsi（第二个参数）
	movq	%rcx, %rdi			# 将值mid+1赋值给%rdi（第一个参数）
	call	build				# 调用build函数
	nop							
.L1:							
# return
	leave						# 恢复栈阵，等效于movq %rbp,%rsp popq %rbp
	ret							# 从函数返回
	.size	build, .-build
# long query(long d,long l,long r, NODE **p)	#声明query函数，用于查询根节点为p的历史版本的d处对应的值
	.globl	query				# query是全局的
	.type	query, @function	# query的类型是函数
query:
	pushq	%rbp				# 保存栈底指针
	movq	%rsp, %rbp			# 将栈顶指针的值赋值给栈底指针，创建一个新栈
	subq	$48, %rsp			# 将栈顶指针减48，创建出一个拥有48字节空间的栈
	movq	%rdi, -24(%rbp)		# %rdi中存了第一个long参数d，将其存放在地址为(%rbp-24)的栈空间
	movq	%rsi, -32(%rbp)		# %rsi中存了第二个long参数l，将其存放在地址为(%rbp-32)的栈空间
	movq	%rdx, -40(%rbp)		# %rdx中存了第三个long参数r，将其存放在地址为(%rbp-40)的栈空间
	movq	%rcx, -48(%rbp)		# %rcx中存了第四个NODE**参数p，将其存放在地址为(%rbp-48)的栈空间
# if（l==r）
	movq	-32(%rbp), %rax		# 取参数l放置到%rax
	cmpq	-40(%rbp), %rax		# 比较参数r和%rax中参数l的大小
	jne	.L6						# 不相等跳转到.L6
# return (*p)->value
	movq	-48(%rbp), %rax		# 取参数p存放到%rax
	movq	(%rax), %rax		# 取*p的值存放到%rax
	movq	16(%rax), %rax		# 取（*p)->r的值存放到%rax作为返回值
	jmp	.L7						# 跳到返回部分
.L6:
# long mid = (l+r)/2
	movq	-32(%rbp), %rdx		# 取参数l放置于%rdx
	movq	-40(%rbp), %rax		# 取参数r放置于%rax
	addq	%rdx, %rax			# 将%rdx(l)+%rax(r)赋值给%rax
	movq	%rax, %rdx			# 将和赋值给%rdx
	# 使用移位优化来代替除法
	shrq	$63, %rdx
	addq	%rdx, %rax
	sarq	%rax				# 得到（l+r）/2 赋值给%rax
	movq	%rax, -8(%rbp)		# 将（l+r）/2存放到栈空间中
# if (d<=mid)
	movq	-24(%rbp), %rax		# 取参数d存放于%rax中
	cmpq	-8(%rbp), %rax		# 比较mid与d
	jg	.L8						# d>mid则跳转到.L8
# query(d,l,mid,&(*p)->l)
	movq	-48(%rbp), %rax		# 取参数p放置于%rax
	movq	(%rax), %rax		# 取*p赋值给rax
	movq	%rax, %rcx			# 将*p赋值给%rcx(第四个参数)，此处*p即为&(*p)->l的地址值
	movq	-8(%rbp), %rdx		# 将mid赋值给%rdx(第三个参数)
	movq	-32(%rbp), %rsi		# 将l赋值给%rsi(第二个参数)
	movq	-24(%rbp), %rax		# 将d赋值給%rax
	movq	%rax, %rdi			# 将%rax（d）赋值给%rdi（第一个参数）
	call	query				# 调用query函数
	jmp	.L7						# 跳转到返回
# else
.L8:
# query(d,mid+1,r,&(*p)->r)
	movq	-48(%rbp), %rax		# 取参数p放置于%rax
	movq	(%rax), %rax		# 取*p赋值给rax
	leaq	8(%rax), %rcx		# 将%rax+8的值赋值给%rcx（第四个参数)，此处即为&(*p)->r的地址值
	movq	-8(%rbp), %rax		# 取mid赋值给%rax
	leaq	1(%rax), %rsi		# 将%rax + 1的值赋给%rsi（第二个参数）
	movq	-40(%rbp), %rdx		# 取参数r的值赋给%rdx（第三个参数）
	movq	-24(%rbp), %rax		# 取参数d的值赋给%rax
	movq	%rax, %rdi			# 将%rax的值d赋给%rdi（第一个参数）
	call	query				# 调用query函数
.L7:
# return query(_,_,_,_,_)
	leave						# 恢复栈阵，等效于movq %rbp,%rsp popq %rbp
	ret							# 从函数返回
	.size	query, .-query
# void update(long d, long l, long r, NODE** p, NODE** history, long v)
# 此函数中p是当前版本节点指针，history是历史版本节点指针，v是要修改的值
# 此函数用于更新线段树
	.globl	update				# update是全局的
	.type	update, @function	# update的类型是函数
update:	
	pushq	%rbp				# 保存栈底指针
	movq	%rsp, %rbp			# 将栈顶指针的值赋值给栈底指针，创建一个新栈
	subq	$64, %rsp			# 将栈顶指针减64，创建出一个拥有64字节空间的栈
	movq	%rdi, -24(%rbp)		# %rdi中存了第一个long参数d，将其存放在地址为(%rbp-24)的栈空间
	movq	%rsi, -32(%rbp)		# %rsi中存了第二个long参数l，将其存放在地址为(%rbp-32)的栈空间
	movq	%rdx, -40(%rbp)		# %rdx中存了第三个long参数r，将其存放在地址为(%rbp-40)的栈空间
	movq	%rcx, -48(%rbp)		# %rcx中存了第四个NODE**参数p，将其存放在地址为(%rbp-48)的栈空间
	movq	%r8, -56(%rbp)		# %r8中存了第五个NODE**参数history，将其存放在地址为(%rbp-56)的栈空间
	movq	%r9, -64(%rbp)		# %r9中存了第六个long参数v，将其存放在地址为(%rbp-64)的栈空间
# if ((*p) == NULL)
	movq	-48(%rbp), %rax		# 取参数p的值，赋给%rax寄存器
	movq	(%rax), %rax		# 取参数p所指向的NODE*的值*p，赋给%rax寄存器
	testq	%rax, %rax			# testq测试%rax寄存器中的值是否为0
	jne	.L10					# 不相等跳转到.L10
	movl	$24, %edi			# sizeof(NODE)的值为24，此处为malloc的第一个函数，意为malloc24字节的空间
	call	malloc@PLT			# 调用malloc分配空间
	movq	%rax, %rdx			# 将malloc分配到的空间地址赋给%rdx
	movq	-48(%rbp), %rax		# 将参数p的值赋给%rax
	movq	%rdx, (%rax)		# 将malloc分配到的内存地址写入到参数p指向的内存地址
.L10:
# if (l == r)
	movq	-32(%rbp), %rax		# 将参数l赋值给rax
	cmpq	-40(%rbp), %rax		# 比较参数l和参数r是否相等
	jne	.L11					# 若不相等，跳转到.L11
# (*p)->value = v;
	movq	-48(%rbp), %rax		# 将参数p的值赋给%rax
	movq	(%rax), %rax		# 取*p，赋给%rax
	movq	-64(%rbp), %rdx		# 取参数v放入%rdx
	movq	%rdx, 16(%rax)		# 将参数v赋值给(*p)->value
# return
	jmp	.L9						# 跳转到结束
.L11:
# long mid = (l+r)/2
	movq	-32(%rbp), %rdx		# 取参数l赋值给%rdx
	movq	-40(%rbp), %rax		# 取参数r赋值给%rax
	addq	%rdx, %rax			# 参数l和参数r相加	
	movq	%rax, %rdx			# 将和赋值给%rdx
	# 使用移位优化来代替除法
	shrq	$63, %rdx
	addq	%rdx, %rax
	sarq	%rax				# 得到（l+r）/2 赋值给%rax
	movq	%rax, -8(%rbp)		# 将（l+r）/2存放到栈空间中
# if (d <= mid)
	movq	-24(%rbp), %rax		# 取参数d存放于%rax中
	cmpq	-8(%rbp), %rax		# 比较mid与d
	jg	.L13					# d>mid则跳转到.L13
# update(d, l, mid, &(*p)->l, &(*history)->l, v);
	movq	-56(%rbp), %rax		# 取参数history放置于%rax
	movq	(%rax), %rax		# 取值*history存放于%rax
	movq	%rax, %r8			# 将%rax中值*history存放于%r8(第五个参数)，此处*history即为&(*history)->l的地址值
	movq	-48(%rbp), %rax		# 取参数p放置于%rax
	movq	(%rax), %rax		# 取*p赋值给rax
	movq	%rax, %rdi			# 将*p赋值给%rdi，此处*p即为&(*p)->l的地址值
	movq	-64(%rbp), %rcx		# 取参数v赋值给%rcx
	movq	-8(%rbp), %rdx		# 取mid赋值给%rdx
	movq	-32(%rbp), %rsi		# 取参数l赋值给%rsi
	movq	-24(%rbp), %rax		# 取参数d赋值给%rax
	movq	%rcx, %r9			# 将%rcx中的参数v赋值给%r9(第6个参数)
	movq	%rdi, %rcx			# 将%rdi中的参数*p赋值给%rcx(第四个参数)，此处*p的值即为&(*p)->l的地址值
	movq	%rax, %rdi			# 将%rax中的参数d赋值给%rdi(第一个参数)
	call	update				# 调用update函数
# (*p)->r = (*history)->r;
	movq	-56(%rbp), %rax		# 将参数history放置于%rax
	movq	(%rax), %rdx		# 将*history放置于%rdi
	movq	-48(%rbp), %rax		# 将参数p放置于%rax
	movq	(%rax), %rax		# 将*p放置于%rax
	movq	8(%rdx), %rdx		# 将（*history）-> r 放置于%rdx
	movq	%rdx, 8(%rax)		# 将(*history)->l赋值给(*p)->r;
	jmp	.L9						# 跳转到结束
.L13:
# update(d, mid + 1, r, &(*p)->r, &(*history)->r, v);
	movq	-56(%rbp), %rax		# 取参数history放置于%rax
	movq	(%rax), %rax		# 取值*history存放于%rax
	leaq	8(%rax), %r8		# 取值%rax + 8赋值给%r8(第五个参数)，此处即为&(*history)->r的值
	movq	-48(%rbp), %rax		# 取参数p放置于%rax
	movq	(%rax), %rax		# 取*p赋值给rax
	leaq	8(%rax), %rcx		# 取值%rax + 8赋值给%rcx(第四个参数)，此处即为&(*p)->r的值
	movq	-8(%rbp), %rax		# 取mid赋值给%rax
	leaq	1(%rax), %rsi		# 取值mid+1赋值给%rsi(第二个参数)
	movq	-64(%rbp), %rdi		# 取参数v赋值给%rdi
	movq	-40(%rbp), %rdx		# 取参数r赋值给%rax(第三个参数)
	movq	-24(%rbp), %rax		# 取参数d赋值给%rax
	movq	%rdi, %r9			# 将%rdi中参数v赋值给%r9(第六个参数)
	movq	%rax, %rdi			# 将%rax中参数d赋值给%rdi(第一个参数)
	call	update				# 调用update函数
# (*p)->l = (*history)->l;
	movq	-56(%rbp), %rax		# 将参数history放置于%rax
	movq	(%rax), %rdx		# 将*history放置于%rdi
	movq	-48(%rbp), %rax		# 将参数p放置于%rax
	movq	(%rax), %rax		# 将*p放置于%rax
	movq	(%rdx), %rdx		# 将（*history）-> l 放置于%rdx
	movq	%rdx, (%rax)		# 将(*history)->l赋值给(*p)->r;
.L9:	
	leave						# 恢复栈阵，等效于movq %rbp,%rsp popq %rbp
	ret							# 从函数返回
	.size	update, .-update
# 进入主函数段
	.section	.rodata
.LC0:
	.string	"%d\n"
	.text
	.globl	main				# main是全局的
	.type	main, @function		# main的类型是函数
main:
	pushq	%rbp				# 保存栈底指针	
	movq	%rsp, %rbp			# 将栈顶指针的值赋值给栈底指针，创建一个新栈
	subq	$48, %rsp			# 将栈顶指针减48，创建出一个拥有48字节空间的栈
# n=read();
	movl	$0, %eax			# 置eax为0，用于接受read()函数返回值
	call	read@PLT			# 调用read()函数
	movq	%rax, n(%rip)		# 将返回的值赋给n
# m=read();
	movl	$0, %eax			# 置eax为0，用于接受read()函数返回值
	call	read@PLT			# 调用read()函数
	movq	%rax, m(%rip)		# 将返回的值赋给n
# build(1, n, &head[0]);
	movq	n(%rip), %rax		# 将n的值赋给%rax
	leaq	head(%rip), %rdx	# 将head[0]的值赋给%rdx(第三个参数)
	movq	%rax, %rsi			# 将%rax中n的值赋给%rsi(第二个参数)
	movl	$1, %edi			# 将1赋值给%edi(第一个参数)
	call	build				# 调用build函数
# for (long i = 1; i <= m; i++)
	movq	$1, -8(%rbp)		# 为临时变量i赋值为1
	jmp	.L15					# 跳转到.L15进行条件判断
.L18:
# long his, mode, loc;			# 声明三个临时变量
# his=read();
	movl	$0, %eax			# 置eax为0，用于接受read()函数返回值
	call	read@PLT			# 调用read()函数
	movq	%rax, -16(%rbp)		# 临时变量his存储于-16(%rbp)
# mode=read();
	movl	$0, %eax			# 置eax为0，用于接受read()函数返回值
	call	read@PLT			# 调用read()函数
	movq	%rax, -24(%rbp)		# 临时变量mode存储于-24(%rbp)
# mode=read();
	movl	$0, %eax			# 置eax为0，用于接受read()函数返回值
	call	read@PLT			# 调用read()函数
	movq	%rax, -32(%rbp)		# 临时变量loc存储于-32(%rbp)
# if (mode == 1)
	cmpq	$1, -24(%rbp)		# 比较mode和1
	jne	.L16					# 不相等跳转.L16
# value=read();
	movl	$0, %eax			# 置eax为0，用于接受read()函数返回值
	call	read@PLT			# 调用read()函数
	movq	%rax, -40(%rbp)		# 临时变量value存储于-40(%rbp)
# update(loc, 1, n, &head[i], &head[his], value);
	movq	-16(%rbp), %rax		# 取变量his的值存于%rax
	leaq	0(,%rax,8), %rdx	# 取%rax * 8的值存储与%rdx
	leaq	head(%rip), %rax	# 取head数组的头地址于%rax
	leaq	(%rdx,%rax), %rdi	# 取head + %rdx，算出&head[his]的值存放于%rdi(第四个参数)
	movq	-8(%rbp), %rax		# 取变量i的值存于%rax
	leaq	0(,%rax,8), %rdx	# 取%rax * 8的值存储与%rdx
	leaq	head(%rip), %rax	# 取head数组的头地址于%rax
	leaq	(%rdx,%rax), %rcx	# 取head + %rdx，算出&head[his]的值存放于%rcx
	movq	n(%rip), %rdx		# 取n的值存储于%rdx(第三个参数)
	movq	-40(%rbp), %rsi		# 取变量value存储于%rsi
	movq	-32(%rbp), %rax		# 取变量loc存储于%rax
	movq	%rsi, %r9			# 将%rsi的值value赋给%r9(第六个参数)
	movq	%rdi, %r8			# 将%rdi的值&head[his]赋给%r8(第五个参数)
	movl	$1, %esi			# 将值1赋给%esi(第二个参数)
	movq	%rax, %rdi			# 将%rax的值loc赋值给%rdi(第一个参数)
	call	update
.L16:
# if (mode == 2)
	cmpq	$2, -24(%rbp)		# 比较mode和2
	jne	.L17					# 不相等跳转.L17
# query(loc, 1, n, &head[his])
	movq	-16(%rbp), %rax		# 取变量his的值存于%rax
	leaq	0(,%rax,8), %rdx	# 取%rax * 8的值存储与%rdx
	leaq	head(%rip), %rax	# 取head数组的头地址于%rax
	leaq	(%rdx,%rax), %rcx	# 取head + %rdx，算出&head[his]的值存放于%rdi(第四个参数)
	movq	n(%rip), %rdx		# 取n的值存储于%rdx(第三个参数)
	movq	-32(%rbp), %rax		# 取变量loc存储于%rax
	movl	$1, %esi			# 给%rsi赋值1(第二个参数)
	movq	%rax, %rdi			# 将%rax的值loc赋值给%rdi(第一个参数)
	call	query				# 调用query函数
# printf("%d\n", query(loc, 1, n, &head[his]));
	movq	%rax, %rsi			# 将返回值赋值给%rsi(第二个参数)
	leaq	.LC0(%rip), %rax	# 将字符串"%d\n"的地址赋给%rax
	movq	%rax, %rdi			# 将字符串的地址赋给%rdi(第一个参数)
	movl	$0, %eax			# 清空%eax用于接受返回值
	call	printf@PLT			# 调用printf函数
	movq	-16(%rbp), %rax		# 取变量his的值存于%rax
	leaq	0(,%rax,8), %rdx	# 取%rax * 8的值存储与%rdx
	leaq	head(%rip), %rax	# 取head数组的头地址于%rax
	movq	(%rdx,%rax), %rax	# 取head + %rdx，算出&head[his]的值存放于%rax
	movq	-8(%rbp), %rdx		# 取变量i的值存于%rdx
	leaq	0(,%rdx,8), %rcx	# 取%rdx * 8的值存储与%rcx
	leaq	head(%rip), %rdx	# 取head数组的头地址于%rdx
	movq	%rax, (%rcx,%rdx)	# 将head[his] 赋值给head[i]
.L17:
	addq	$1, -8(%rbp)		# 临时变量i+1
.L15:
	movq	m(%rip), %rax		# 取m的值赋值给%rax
	cmpq	%rax, -8(%rbp)		# 将m的值与临时变量i比较
	jle	.L18					# 小于则跳转.L18
	movl	$0, %eax			# 主函数main返回值0
	leave						# 恢复栈帧
	ret							# 返回(退出程序)
	.size	main, .-main
	.ident	"GCC: (Debian 13.2.0-7) 13.2.0"
	.section	.note.GNU-stack,"",@progbits
