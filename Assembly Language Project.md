# Assembly Language Project 

同济大学软件学院汇编语言课程项目，分析C语言代码

## 项目结构

C语言文件：project.c

带有分析注释的汇编文件：project.s

## 项目背景

可持久化数组是一种支持在历史版本上进行操作的结构，其基本操作如下：

对于长度为N的数组，支持以下操作

1. 在某个历史版本上修改某一个位置上的值
2. 访问某个历史版本上的某一位置的值

此处我们规定，每进行一次操作，就会生成一个新的版本，以版本0为初始版本

输入的第一行包含两个正整数 N,M， 分别表示数组的长度和操作的个数

接下来M行每行包含3或4个整数，代表两种操作之一（i为基于的历史版本号）：

1. 对于操作1，格式为v_i 1 loc_i value_i，即为在版本vi的基础上，将a_loc_i修改为 value_i。
2. 对于操作2，格式为v_i 2 loc_i，即访问版本v中的 a_loc_i的值

## 项目分析

如果采用传统数组方式，我们每执行一次操作就需要将原数组复制一次，此过程时间复杂度和空间复杂度极高，考虑优化方法

我们注意到，对于修改操作，当前版本与它的上一个版本相比，只更改了一个节点的值，其他大部分节点的值没有变化，而对于查询操作，则所有节点的值都没有变化，我们考虑如何重复利用没有变化的值

通过对数据结构的理解，我们了解到线段树这种数据结构，线段树是一颗二叉搜索树，其核心思想为区间，树上的每一个节点代表一个区间[L,R]，每个节点被两个子节点均分为部分，如下图是区间[0,7]的线段树

![img](https://pic4.zhimg.com/80/v2-5ea1bee19990663a48daef32b91afd67_720w.webp)

我们可以看到，若要修改一个点，我们只需要访问其所在路径上的节点，即logn个节点，其他节点不做更改和访问

对于这样一种数据结构进行可持久化，我们可以得到如下的一种结构

![image-20240102030305893](C:\Users\KingofField\AppData\Roaming\Typora\typora-user-images\image-20240102030305893.png)

我们可以找到如下规律：

1. 我们的每次修改都新增了logn个节点
2. 我们的每次修改新增的非叶节点的子节点一个连向其他版本的节点，一个连向新节点
3. 该二叉搜索森林有很多根，其中每个根代表一个历史版本
4. 对于每一个根都可以构成一颗完整的线段树

对于节点的设计，我们需要两个指针和一个值，一个指向左节点，一个指向右节点，还有一个用于存储当前指针的值

~~~c
struct node
{
	NODE* l;
	NODE* r;
	long value;
}
~~~

对于节点的新建，调用malloc函数进行创建

~~~c
(*p) = (NODE*)malloc(sizeof(NODE));
~~~

在程序开始之前，应该先建立一棵所有数全为0的线段树，并作为后续线段树的基础

~~~c
void build(long l, long r, NODE** p)
{
	if (*p == (NODE*)NULL)
		(*p) = (NODE*)malloc(sizeof(NODE));
	if (l == r)
	{
		(*p)->value=0;
		return;
	}
	long mid = (l + r) / 2;
	build(l, mid, &(*p)->l);
	build(mid + 1, r, &(*p)->r);
	return;
}
~~~

查询过程就是遍历树的过程

~~~c
long query(long d, long l, long r, NODE** p)
{
	if (l == r)return (*p)->value;
	long mid = (l + r) / 2;
	if (d <= mid)
		return query(d, l, mid, &(*p)->l);
	else
		return query(d, mid + 1, r, &(*p)->r);
}
~~~

更新过程需要在过程中不断新建节点，同时将过去的节点连接到当前版本

~~~
void update(long d, long l, long r, NODE** p, NODE** history, long v)
{
	if ((*p) == NULL)
		(*p) = (NODE*)malloc(sizeof(NODE));
	if (l == r)
	{
		(*p)->value = v;
		return;
	}
	long mid = (l + r) / 2;
	if (d <= mid)
	{
		update(d, l, mid, &(*p)->l, &(*history)->l, v);
		(*p)->r = (*history)->r;
	}
	else
	{
		update(d, mid + 1, r, &(*p)->r, &(*history)->r, v);
		(*p)->l = (*history)->l;
	}
}
~~~

## 项目实现

通过对C代码的分析，我们可以看到，我们的汇编程序应该主要包含三个函数

build，包含三个参数l，r，p

query，包含四个参数d，l，r，p

update，包含六个参数d，l，r，p，history，v

让我们分析对应的汇编代码

~~~assembly
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
~~~

~~~assembly
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
~~~

~~~assembly
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
~~~

## 项目心得

本次项目对一个较为复杂的数据结构C代码生成的汇编代码进行了分析，在过程中，我对汇编代码所能进行的优化行为和数据在内存中的实际存储形态有了更加深入的理解。例如对于NODE**p这样一个指向指针的指针，\*p和&(\*p)->l在汇编中实际上相同。有了对汇编代码的理解学习，我对计算机程序如何运行有了更为底层、更为细节的理解，如在C语言代码中对于整数进行除以2操作可以在汇编中表示为三行移位运算，移位运算远快于整数除法，这类细节优化让我对如何写出更好的代码有所心得。此外，我发现函数在编程语言中起到了至关重要的作用，在汇编中，函数和其他语言类似，可以帮助我们减少很多重复的代码片段，使程序的易读性更好，同时让我们可以实现递归等高级操作。

