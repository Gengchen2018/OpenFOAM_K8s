%�ڵ�ԭʼ��Ϣ CPU/�� Mem/G Net/Mbps
Node=[16, 32, 30; 32, 64, 40; 16, 32, 30 ];
sum_cpu=sum(Node(:,1));
sum_mem=sum(Node(:,2));
sum_net=sum(Node(:,3));
%�ڵ���Դ�ܺ�
sum_node=[sum_cpu, sum_mem, sum_net];
%�ڵ���Ϣ��һ��
for i=1:1:3
    for j=1:1:3
        Node(i,j)=Node(i,j)/sum_node(j);
    end
end
%Pod_cpu request
Pod_cpu=[1,1,1,1;1,1,1,1;1,1,1,1;1,1,1,1];
total_cpu = sum(Pod_cpu(:));
Pod_cpu=Pod_cpu/total_cpu; %��һ��
%Pod_mem request �����ʷֵĵ��������Ŀ
Pod_mem=[156,143,124,144;136,140,149,142;132,148,150,137;143,136,144,144];
total_mem = sum(Pod_mem(:));
Pod_mem=Pod_mem/total_mem;%��һ��
%Pod_net request (pod_i, pod_j)
Pod_net=[25,29,30,25;36,38,50,36;34,50,52,36;34,50,52,36;24,37,36,24];
total_net = sum(Pod_net(:));
Pod_net=Pod_net/total_net;%��һ��
%Pod_cpu cost
total_cpu=16;
cpu_cost=total_cpu/sum_cpu;%����pod��cpu�ܹ����ĵİٷֱ�
Pod_cpu=Pod_cpu*cpu_cost;
%Pod_mem cost
total_mem=16;
mem_cost=total_mem/sum_mem;%����pod��Mem�ܹ����ĵİٷֱ�
Pod_mem=Pod_mem*mem_cost;
%Pod_net cost (pod_i, pod_j)
total_net=20;
net_cost=total_net/sum_net;%����pod��net�ܹ����ĵİٷֱ�
Pod_net=Pod_net*net_cost;%net�ǻ����ŵ��ȱ仯��

Location=zeros(4, 4);%���صĵ��Ƚ��
Node_state=zeros(3,3);%Node��ʹ�����
Node_use=zeros(3,3);%����������Ƚ���������ڵ������
%cpu+mem+average
Node_use=zeros(size(Node_use));%�������ǰ�Ȱ���һ�������use����
for i=1:1:4
    for j=1:1:4
        [Location(i,j), Node_state, Node_use]=L_cpu_mem(Pod_cpu(i,j), Pod_mem(i,j), Pod_net(i,j), Node, Node_state, Node_use);
    end
end
Node_percent=Node_state./Node;
%cpu+mem+average����Ƭ��
function [L, state, use]=L_cpu_mem(cpu, mem, net, Node, Node_state, Node_use)
cpu_weight=0.5;%�ĸ���ԴȨ�ظ��� �ĸ��͸�����
mem_weight=0.5;
temp=zeros(1,3);
temp_pod=[cpu, mem, net];
for i=1:1:3
    x=max(cpu_weight*(Node(i,1)-Node_state(i,1)-cpu)/Node(i,1),0);
    y=max(mem_weight*(Node(i,2)-Node_state(i,2)-mem)/Node(i,2),0);
    if(abs(x-0)<0.00001||abs(y-0)<0.0001)
        temp(i)=0;%�����һ����Դ�ľ��Ļ�������
    else
        temp(i)=x+y;%�������ӵõ�������Դ����
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
