%% ��˹-���¶�������
clc; clear;
%% ¼������
max_iter=100;       %����������
error_iter=1e-8;    %�������
baseMVA=100;        %��׼����
bus=[       %�ڵ�����
%�ڵ��� �ڵ����ͣ�ƽ��ڵ�1��PV�ڵ㣬PQ�ڵ�3�� �й����� �޹����� �ڵ��ʼ��ѹ �ӵص���
    1	1	0   	0       1.01	0;
    2	3	0.6     0.35	1       0;
    3	3	0.7     0.42	1       18;
    4	3	0.8     0.5     1       15;
    5   2   0.65    0.36	1       0
    ];
bus(:,6)=bus(:,6)/baseMVA;	%�ӵص��ɱ��ۻ�
gen=[       %���������
    1	0	0;
    5	1.9	0;
    ];
branch=[    %��·����
    1	2	0.0108	0.0649	0   1;
    1	4	0.0235	0.0941	0   1;
    2	5	0.0118	0.0471	0   1;
    3	5	0.0147	0.0588	0   1;
    4   5   0.0118	0.0529	0   1;
    2   3   0       0.04    0   0.975
    ];
%%
%���㵼�ɾ���
n_bus=size(bus,1); n_gen=size(gen,1); n_branch=size(branch,1);
PQ=find(bus(:,2)==3); PV=find(bus(:,2)==2); V0=find(bus(:,2)==1);
G_B=zeros(n_bus,n_bus); %���ɾ���
for i=1:n_branch
    f=branch(i,1); t=branch(i,2); 
    Y=1/complex(branch(i,3),branch(i,4));
    G_B(f,t)=G_B(f,t)-Y/branch(i,6); 
    G_B(t,f)=G_B(t,f)-Y/branch(i,6);
    G_B(f,f)=G_B(f,f)+Y/branch(i,6)^2+complex(0,branch(i,5));
    G_B(t,t)=G_B(t,t)+Y+complex(0,branch(i,5));
end
for i=1:n_bus
    G_B(i,i)=G_B(i,i)+1j*bus(i,6);
end
%%
% P Q V theta
V=bus(:,5);  %��ѹ
theta=zeros(n_bus,1);
V_k=V.*exp(1j*theta);
Q_PV_k=zeros(n_bus,1);
V_k_1=V_k;
z=0;
while(z<=max_iter)
    for i=1:n_bus
        a=find(i==PV); b=find(i==gen(:,1));
        if(i~=V0)
            S=-(bus(i,3)+1j*bus(i,4));
            if(length(a)~=0)
                Q_PV_k(i)=imag(V_k(i)*(G_B(i,:)*V_k_1)');
                S=gen(b,2)-bus(i,3)+1j*Q_PV_k(i);
            end
            V_k_1(i)=((S/V_k(i))'-G_B(i,:)*V_k_1+G_B(i,i)*V_k(i))/G_B(i,i);
        end
        if(length(a)~=0)
            V_k_1(i)=bus(i,5)*V_k_1(i)/abs(V_k_1(i));
        end
    end
    c1=max(abs(abs(V_k_1)-abs(V_k))); c2=max(abs(angle(V_k_1)-angle(V_k)));
    if(c1<=error_iter)&&(c2<=error_iter)
        break;
    end
    V_k=V_k_1;
    z=z+1;
end
%%
%������·����
V=abs(V_k); theta=angle(V_k);
P_b=zeros(n_branch,2); Q_b=zeros(n_branch,2);
for i=1:n_branch
    f=branch(i,1); t=branch(i,2);
    Y=-1/complex(branch(i,3),branch(i,4));
    Y_f=Y/branch(i,6)^2; Y_ft=Y/branch(i,6); 
    P_b(i,1)=-1*V(f)*V(f)*real(Y_f)+V(f)*V(t)*(real(Y_ft)*cos(theta(f)-theta(t))...
        +imag(Y_ft)*sin(theta(f)-theta(t)));
    P_b(i,2)=-1*V(t)*V(t)*real(Y)+V(t)*V(f)*(real(Y_ft)*cos(theta(t)-theta(f))...
        +imag(Y_ft)*sin(theta(t)-theta(f)));
    Q_b(i,1)=V(f)*V(f)*imag(Y_f)+V(f)*V(t)*(real(Y_ft)*sin(theta(f)-theta(t))...
        -imag(Y_ft)*cos(theta(f)-theta(t)))-V(f)*V(f)*branch(i,5);
    Q_b(i,2)=V(t)*V(t)*imag(Y)+V(t)*V(f)*(real(Y_ft)*sin(theta(t)-theta(f))...
        -imag(Y_ft)*cos(theta(t)-theta(f)))-V(t)*V(t)*branch(i,5);
end
for i=1:n_gen
    g=gen(i,1);
    a1=find(branch(:,1)==g); a2=find(branch(:,2)==g);
    results.gen(i,1)=bus(g,3)+sum(P_b(a1,1))+sum(P_b(a2,2));
    results.gen(i,2)=bus(g,4)+sum(Q_b(a1,1))+sum(Q_b(a2,2));
end
results.bus=[V,theta];
results.gen=results.gen*baseMVA;
results.branch=[P_b,Q_b]*baseMVA;
%%
%������
fprintf('����������%.0f��\n',z);
fprintf('***********************************�ڵ�����*******************************************')
fprintf('\n------------�ڵ���              �ڵ��ѹ��ֵ               �ڵ��ѹ���(��)-----------')
format short
for i=1:size(bus,1)
    fprintf('\n     %10.0f %26.4f  %24.4f ',bus(i,1),results.bus(i,1),...
        results.bus(i,2)/pi*180)
end
fprintf('           \n************************************�������������************************************                          ')
fprintf('\n------------�ڵ���              ������й�����               ������޹�����-----------')
for i=1:size(gen,1)
    fprintf('\n     %10.0f %26.3f%26.3f ',gen(i,1),results.gen(i,1),...
        results.gen(i,2))
end
fprintf('\n**************************************************************֧·������************************************************************************')
fprintf('\n--------From_bus       To_bus         From_bus-�й�P(ע��)         From_bus-�޹�Q(ע��)           To_bus-�й�P(����)            T_bus-�޹�Q(����)            ֧·���P            ֧·���Q-----------')
for i=1:n_branch
    fprintf('\n%12.0d %13.0d %24.3f %28.3f %28.3f %30.3f %20.3f %21.3f',...
        branch(i,1),branch(i,2),results.branch(i,1),results.branch(i,3),...
        -results.branch(i,2),-results.branch(i,4),results.branch(i,1)+...
        results.branch(i,2),results.branch(i,3)+results.branch(i,4))
end
fprintf('\n**************************************************************�ڵ㵼�ɾ���************************************************************************\n')
for i=1:n_bus
    for j=1:n_bus
        if(imag(G_B(i,j))>=0)
            fprintf('%10.4f+%.4fi',real(G_B(i,j)),imag(G_B(i,j)));
        else
            fprintf('%10.4f%.4fi',real(G_B(i,j)),imag(G_B(i,j)));
        end
    end
    fprintf('\n');
end
fprintf('\n');




