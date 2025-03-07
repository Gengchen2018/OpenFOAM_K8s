%任务图的拓扑结构
Flag=zeros(1,16);%判断找到的子域是否已经被调度
Graph=cell(16,1);%快速找到和该点相邻的子域以及与该子域的通信量
directions=[-1,0;0,-1;0,1;1,0;];%上%左%右%下
for i=1:1:4
    for j=1:1:4
        t=(i-1)*4+j;
        temp=[];
        count=0;
        for x=1:1:4
            x_x=directions(x,1);
            y_y=directions(x,2);
            if(i+x_x>=1&&i+x_x<=4&&j+y_y>=1&&j+y_y<=4)
                count=count+1;
                temp(count)=t+4*x_x+y_y;
            end
        end
        temp1=ones(size(temp));
        Graph{t}=[temp;temp1];
    end
end
%任务图的通信量
Graph{1}(2,:)=[13,12];
Graph{2}(2,:)=[13,5,11];
Graph{3}(2,:)=[5,13,12];
Graph{4}(2,:)=[13,12];
Graph{5}(2,:)=[12,13,11];
Graph{6}(2,:)=[11,13,12,12];
Graph{7}(2,:)=[12,12,13,13];
Graph{8}(2,:)=[12,13,11];
Graph{9}(2,:)=[11,12,11];
Graph{10}(2,:)=[12,12,14,12];
Graph{11}(2,:)=[13,14,13,12];
Graph{12}(2,:)=[11,13,12];
Graph{13}(2,:)=[11,13];
Graph{14}(2,:)=[12,13,12];
Graph{15}(2,:)=[12,12,12];
Graph{16}(2,:)=[12,12];
%Pod_net代表了相邻的子域数目
Pod_net=zeros(4,4);
for i=1:1:4
    for j=1:1:4
        l=(i-1)*4+j;
        Pod_net(i,j)=sum(Graph{l}(2,:));%区别在于是否转置
    end
end
%Pod_net具体信息
Pod_net=[25,29,30,25;36,38,50,36;34,50,52,36;34,50,52,36;24,37,36,24];
%节点原始信息 CPU/核 Mem/MB Net/Mbps
Node=[16, 32, 30; 32, 64, 40; 16, 32, 30 ];
sum_cpu=sum(Node(:,1));
sum_mem=sum(Node(:,2));
sum_net=sum(Node(:,3));
sum_node=[sum_cpu, sum_mem, sum_net];%节点资源总和
for i=1:1:3
    for j=1:1:3
        Node(i,j)=Node(i,j)/sum_node(j);
    end
end
%Pod_cpu request
Pod_cpu=[1,1,1,1;1,1,1,1;1,1,1,1;1,1,1,1];
total_cpu = sum(Pod_cpu(:));
Pod_cpu=Pod_cpu/total_cpu; %归一化
%Pod_mem request
Pod_mem=[156,143,124,144;136,140,149,142;132,148,150,137;143,136,144,144];
total_mem = sum(Pod_mem(:));
Pod_mem=Pod_mem/total_mem;%归一化
%Pod_net request (pod_i, pod_j)
total_net = sum(Pod_net(:));
total_temp_net=total_net;%留着有用
Pod_net=Pod_net/total_net;%归一化
%Pod_cpu cost
total_cpu=16;
cpu_cost=total_cpu/sum_cpu;%本次pod组cpu总共消耗的百分比
Pod_cpu=Pod_cpu*cpu_cost;
%Pod_mem cost
total_mem=16;
mem_cost=total_mem/sum_mem;%本次pod组Mem总共消耗的百分比
Pod_mem=Pod_mem*mem_cost;
%Pod_net cost (pod_i, pod_j)
total_net=20;
net_cost=total_net/sum_net;%本次pod组net总共消耗的百分比
Pod_net=Pod_net*net_cost;%net是会随着调度过程变的

Location=zeros(4, 4);%返回的调度结果
Node_state=zeros(3,3);%Node的使用情况
Node_state=Node;
Node_use=zeros(3,3);%本次任务调度结束后各个节点的增量

count=0;%从节点1开始 转一次到节点2
spin=0;%刚开始不需要旋转
set_pointer=1;%指向第一个节点

%初始化三个pod
A_pod=1;
B_pod=11;
C_pod=13;
%初始化每个节点的已调度pod和Location
a_x=floor((A_pod-1)/4)+1; 
a_y=mod(A_pod-1,4)+1;
b_x=floor((B_pod-1)/4)+1; 
b_y=mod(B_pod-1,4)+1;
c_x=floor((C_pod-1)/4)+1; 
c_y=mod(C_pod-1,4)+1;
set1=[];set1=[set1,A_pod];
Flag(A_pod)=1;
set2=[];set2=[set2,B_pod];
Flag(B_pod)=1;
set3=[];set3=[set3,C_pod];
Flag(C_pod)=1;
Location(a_x,a_y)=1;
Location(b_x,b_y)=2;
Location(c_x,c_y)=3;
%初始化my_set
my_set=cell(3,1);
my_set{1}=set1;
my_set{2}=set2;
my_set{3}=set3;
%更新Node_state已经调度的点要把他们的使用反映在Node_state
Node_state(1,:)=[Pod_cpu(a_x,a_y),Pod_mem(a_x,a_y),Pod_net(a_x,a_y)];
Node_state(2,:)=[Pod_cpu(b_x,b_y),Pod_mem(b_x,b_y),Pod_net(b_x,b_y)];
Node_state(3,:)=[Pod_cpu(c_x,c_y),Pod_mem(c_x,c_y),Pod_net(c_x,c_y)];
%cpu+mem+net+组合权重
%主观权重w1，重要性：net>cpu>mem 序号：cpu mem net
A=[1,2,1/2;1/2,1,1/2;2,2,1];
[V, D] = eig(A);
temp=diag(D);
[num_value, num_location]=max(temp);
RI=0.52;
CI=(num_value-3)/(3-1);
CR=CI/RI;
w1=V(:,num_location);
w1=[w1(1)/sum(w1(:)), w1(2)/sum(w1(:)), w1(3)/sum(w1(:))];
%客观权重w2
%Node_state/Node
data=Node-Node_state;
% 数据标准化（Min-Max标准化）
data_min = min(data);
data_max = max(data);
Z=(data-data_min)./(data_max-data_min);
%计算每个特征的概率分布
p=Z./sum(Z);
%计算熵值
n=size(data,1);% 样本数量
k=1/log(n);% 常数
e=-k * sum(p.*log(p+eps),1);
%计算权重
w2=(1-e)./sum(1-e);
%组合权重w
w=(w1+w2)/2;
while(sum(Flag(:))<16)%可能会出现没法完全被调度的情况
    if(spin)
        count=count+1;
        set_pointer=get_pointer(count);
        spin=0;
    end
    %从指向的节点的已调度pod开始进行遍历
    temp_set=[];
    for elememt=my_set{set_pointer}
        temp_set=[temp_set,Graph{elememt}];
    end
    %删除已经调度的pod
    columnsToRemove=Flag(temp_set(1,:))==1;
    temp_set(:, columnsToRemove) = [];
    [unique_values, ~, indices] = unique(temp_set(1, :));
    summed_values = accumarray(indices, temp_set(2, :));
    temp_set=[];
    temp_set=[unique_values;summed_values'];
    %获取最大通信量的pod的key和value
    %只要删除已经调度的就行可以不用去重
    [maxValue, maxColumn] = max(temp_set(2, :));%value
    maxNum=temp_set(1,maxColumn);%key
    %从key映射i,j
    row=floor((maxNum-1)/4)+1; 
    col=mod(maxNum-1,4)+1;
    %得到row和col后可以进行资源调度
    [Location(row,col), Node_state, Node_use, spin, my_set, Flag]=...
    L_cpu_mem_topo(Pod_cpu(row,col), Pod_mem(row,col), Pod_net(row,col), Node, Node_state, Node_use,...
    spin,set_pointer,my_set, Flag, maxNum, w, Graph, total_temp_net, net_cost);
end
%查看资源的使用情况
Node_percent=Node_state./Node;
%转动set的指针
function pointer=get_pointer(count)
pointer=mod(count,3)+1;
end
%cpu+mem+net
function [L,state,use,bool,set,flag]=L_cpu_mem_topo(cpu, mem, net, Node, Node_state, Node_use, spin, set_pointer, my_set, Flag, maxNum, w, Graph, total_temp_net, net_cost)
cpu_weight=w(1);%哪个权重大 哪个就更均衡
mem_weight=w(2);
net_weight=w(3);
temp_pod=[cpu, mem, net];
temp=[];
net_reset=0;
alpha=0.8;
%假如放到同一个节点会抵消掉多少个边
A=my_set{set_pointer};
B=[Graph{maxNum}];
%初始化sum
sum=0;
%遍历第二个矩阵的第一行
for i = 1:size(B, 2)
    %检查B的第一行的元素是否在A中
    if ismember(B(1, i), A)
        %如果在累加对应的第二行元素
        sum = sum + B(2, i);
    end
end
net_reset=(sum/total_temp_net)*net_cost;
for i=1:1:3
    x=max(cpu_weight*(Node(i,1)-Node_state(i,1)-cpu)/Node(i,1),0);
    y=max(mem_weight*(Node(i,2)-Node_state(i,2)-mem)/Node(i,2),0);
    z=max(net_weight*(Node(i,3)-Node_state(i,3)-net+alpha*net_reset)/Node(i,3),0);
    temp=[temp,x+y+z];%否则就相加得到空余资源分数
end
[~, node_num]=max(temp);
if node_num==set_pointer
    my_set{set_pointer}=[my_set{set_pointer},maxNum];%%加入节点到集合
    spin=0;%无需旋转
    Flag(maxNum)=1;%标记为已调度
    %更新状态
    for i=1:1:3
        Node_use(node_num,i)=Node_use(node_num,i)+temp_pod(i);
        Node_state(node_num,i)=Node_state(node_num,i)+temp_pod(i);
    end
    Node_state(node_num,3)=Node_state(node_num,3)-alpha*net_reset;
else
    node_num=0;%无需调度赋值为0
    spin=1;%需要旋转
end
L=node_num;
state=Node_state;
use=Node_use;
bool=spin;
set=my_set;
flag=Flag;
end
