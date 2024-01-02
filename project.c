#include<stdio.h>
#include<stdlib.h>
#include<ctype.h>
#define NODE struct node
struct node
{
	NODE* l;
	NODE* r;
	long value;
};
inline long read()
{
    long f=1,r=0;char c=getchar();
    while(!isdigit(c)){if(c=='-')f=-1; c=getchar();}
    while(isdigit(c)){r=r*10+c-'0';c=getchar();}
    return f*r;
}
NODE *head[2000000];
long n, m;
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
long query(long d, long l, long r, NODE** p)
{
	if (l == r)return (*p)->value;
	long mid = (l + r) / 2;
	if (d <= mid)
		return query(d, l, mid, &(*p)->l);
	else
		return query(d, mid + 1, r, &(*p)->r);
}
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
int main()
{
	n=read();
	m=read();
	build(1, n, &head[0]);
	for (long i = 1; i <= m; i++)
	{
		long his, mode, loc;
		his=read();
		mode=read();
		loc=read();
		if (mode == 1)
		{
			long value;
			value=read();
			update(loc, 1, n, &head[i], &head[his], value);
		}
		if (mode == 2)
		{
			printf("%d\n", query(loc, 1, n, &head[his]));
			head[i] = head[his];
		}
	}
	return 0;
}