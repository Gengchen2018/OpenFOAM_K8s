%����ͼ�����˽ṹ
Flag=zeros(1,16);%�ж��ҵ��������Ƿ��Ѿ�������
Graph=cell(16,1);%�����ҵ��͸õ����ڵ������Լ���������ͨ����
directions=[-1,0;0,-1;0,1;1,0;];%��%��%��%��
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
%����ͼ��ͨ����
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
%Pod_net���������ڵ�������Ŀ
Pod_net=zeros(4,4);
for i=1:1:4
    for j=1:1:4
        l=(i-1)*4+j;
        Pod_net(i,j)=sum(Graph{l}(2,:));%���������Ƿ�ת��
    end
end
%Pod_net������Ϣ
Pod_net=[25,29,30,25;36,38,50,36;34,50,52,36;34,50,52,36;24,37,36,24];
%�ڵ�ԭʼ��Ϣ CPU/�� Mem/MB Net/Mbps
Node=[16, 32, 30; 32, 64, 40; 16, 32, 30 ];
sum_cpu=sum(Node(:,1));
sum_mem=sum(Node(:,2));
sum_net=sum(Node(:,3));
sum_node=[sum_cpu, sum_mem, sum_net];%�ڵ���Դ�ܺ�
for i=1:1:3
    for j=1:1:3
        Node(i,j)=Node(i,j)/sum_node(j);
    end
end
%Pod_cpu request
Pod_cpu=[1,1,1,1;1,1,1,1;1,1,1,1;1,1,1,1];
total_cpu = sum(Pod_cpu(:));
Pod_cpu=Pod_cpu/total_cpu; %��һ��
%Pod_mem request
Pod_mem=[156,143,124,144;136,140,149,142;132,148,150,137;143,136,144,144];
total_mem = sum(Pod_mem(:));
Pod_mem=Pod_mem/total_mem;%��һ��
%Pod_net request (pod_i, pod_j)
total_net = sum(Pod_net(:));
total_temp_net=total_net;
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
Pod_net=Pod_net*net_cost;%net�ǻ����ŵ��ȹ��̱��

Location=zeros(4, 4);%���صĵ��Ƚ��
Node_state=zeros(3,3);%Node��ʹ�����
Node_state=Node;
Node_use=zeros(3,3);%����������Ƚ���������ڵ������

count=0;%�ӽڵ�1��ʼ תһ�ε��ڵ�2
spin=0;%�տ�ʼ����Ҫ��ת
set_pointer=1;%ָ���һ���ڵ�

%��ʼ������pod
A_pod=4;
B_pod=11;
C_pod=13;
%��ʼ��ÿ���ڵ���ѵ���pod��Location
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
%��ʼ��my_set
my_set=cell(3,1);
my_set{1}=set1;
my_set{2}=set2;
my_set{3}=set3;
%����Node_state�Ѿ����ȵĵ�Ҫ�����ǵ�ʹ�÷�ӳ��Node_state
Node_state(1,:)=[Pod_cpu(a_x,a_y),Pod_mem(a_x,a_y),Pod_net(a_x,a_y)];
Node_state(2,:)=[Pod_cpu(b_x,b_y),Pod_mem(b_x,b_y),Pod_net(b_x,b_y)];
Node_state(3,:)=[Pod_cpu(c_x,c_y),Pod_mem(c_x,c_y),Pod_net(c_x,c_y)];
while(sum(Flag(:))<16)%���ܻ����û����ȫ�����ȵ����
    if(spin)
        count=count+1;
        set_pointer=get_pointer(count);
        spin=0;
    end
    %��ָ��Ľڵ���ѵ���pod��ʼ���б���
    temp_set=[];
    for elememt=my_set{set_pointer}
        temp_set=[temp_set,Graph{elememt}];
    end
    %ɾ���Ѿ����ȵ�pod
    columnsToRemove=Flag(temp_set(1,:))==1;
    temp_set(:, columnsToRemove) = [];
    [unique_values, ~, indices] = unique(temp_set(1, :));
    summed_values = accumarray(indices, temp_set(2, :));
    temp_set=[];
    temp_set=[unique_values;summed_values'];
    %��ȡ���ͨ������pod��key��value
    %ֻҪɾ���Ѿ����ȵľ��п��Բ���ȥ��
    [maxValue, maxColumn] = max(temp_set(2, :));%value
    maxNum=temp_set(1,maxColumn);%key
    %��keyӳ��i,j
    row=floor((maxNum-1)/4)+1; 
    col=mod(maxNum-1,4)+1;
    %�õ�row��col����Խ�����Դ����
    [Location(row,col), Node_state, Node_use, spin, my_set, Flag]=...
    L_cpu_mem_topo(Pod_cpu(row,col), Pod_mem(row,col), Pod_net(row,col), Node, Node_state, Node_use,...
    spin,set_pointer,my_set, Flag, maxNum);
end
%�鿴��Դ��ʹ�����
Node_percent=Node_state./Node;
%ת��set��ָ��
function pointer=get_pointer(count)
pointer=mod(count,3)+1;
end
%ԭ����cpu+mem
function [L,state,use,bool,set,flag]=L_cpu_mem_topo(cpu, mem, net, Node, Node_state, Node_use, spin, set_pointer, my_set, Flag, maxNum)
cpu_weight=0.5;%�ĸ�Ȩ�ش� �ĸ��͸�����
mem_weight=0.5;
temp_pod=[cpu, mem, net];
temp=[];
for i=1:1:3
    x=max(cpu_weight*(Node(i,1)-Node_state(i,1)-cpu)/Node(i,1),0);
    y=max(mem_weight*(Node(i,2)-Node_state(i,2)-mem)/Node(i,2),0);
    temp=[temp,x+y];%�������ӵõ�������Դ����
end
[~, node_num]=max(temp);
if node_num==set_pointer
    my_set{set_pointer}=[my_set{set_pointer},maxNum];%%����ڵ㵽����
    spin=0;%������ת
    Flag(maxNum)=1;%���Ϊ�ѵ���
    %����״̬
    for i=1:1:3
        Node_use(node_num,i)=Node_use(node_num,i)+temp_pod(i);
        Node_state(node_num,i)=Node_state(node_num,i)+temp_pod(i);
    end
else
    node_num=0;%������ȸ�ֵΪ0
    spin=1;%��Ҫ��ת
end
L=node_num;
state=Node_state;
use=Node_use;
bool=spin;
set=my_set;
flag=Flag;
end
