%节点原始信息 CPU/核 Mem/G Net/Mbps
Node=[16, 32, 30; 32, 64, 40; 16, 32, 30 ];
sum_cpu=sum(Node(:,1));
sum_mem=sum(Node(:,2));
sum_net=sum(Node(:,3));
%节点资源总和
sum_node=[sum_cpu, sum_mem, sum_net];
%节点信息归一化
for i=1:1:3
    for j=1:1:3
        Node(i,j)=Node(i,j)/sum_node(j);
    end
end
%Pod_cpu request
Pod_cpu=[1,1,1,1;1,1,1,1;1,1,1,1;1,1,1,1];
total_cpu = sum(Pod_cpu(:));
Pod_cpu=Pod_cpu/total_cpu; %归一化
%Pod_mem request 根据剖分的点或者面数目
Pod_mem=[156,143,124,144;136,140,149,142;132,148,150,137;143,136,144,144];
total_mem = sum(Pod_mem(:));
Pod_mem=Pod_mem/total_mem;%归一化
%Pod_net request (pod_i, pod_j)
Pod_net=[25,29,30,25;36,38,50,36;34,50,52,36;34,50,52,36;24,37,36,24];
total_net = sum(Pod_net(:));
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
Pod_net=Pod_net*net_cost;%net是会随着调度变化的

Location=zeros(4, 4);%返回的调度结果
Node_state=zeros(3,3);%Node的使用情况
Node_use=zeros(3,3);%本次任务调度结束后各个节点的增量
%cpu+mem+average
Node_use=zeros(size(Node_use));%任务调度前先把上一个任务的use清零
for i=1:1:4
    for j=1:1:4
        [Location(i,j), Node_state, Node_use]=L_cpu_mem(Pod_cpu(i,j), Pod_mem(i,j), Pod_net(i,j), Node, Node_state, Node_use);
    end
end
Node_percent=Node_state./Node;
%cpu+mem+average函数片段
function [L, state, use]=L_cpu_mem(cpu, mem, net, Node, Node_state, Node_use)
cpu_weight=0.5;%哪个资源权重更大 哪个就更均衡
mem_weight=0.5;
temp=zeros(1,3);
temp_pod=[cpu, mem, net];
for i=1:1:3
    x=max(cpu_weight*(Node(i,1)-Node_state(i,1)-cpu)/Node(i,1),0);
    y=max(mem_weight*(Node(i,2)-Node_state(i,2)-mem)/Node(i,2),0);
    if(abs(x-0)<0.00001||abs(y-0)<0.0001)
        temp(i)=0;%如果有一种资源耗尽的话则置零
    else
        temp(i)=x+y;%否则就相加得到空余资源分数
    end
end
[~, node_num]=max(temp);
for i=1:1:3
    Node_use(node_num,i)=Node_use(node_num,i)+temp_pod(i);
    Node_state(node_num,i)=Node_state(node_num,i)+temp_pod(i);
end
L=node_num;
state=Node_state;
use=Node_use;
end
