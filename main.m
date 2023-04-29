clear
clc 
warning off
load PV
load WT
load P_load
load R_load
load L_load
load G_price_buy
load  G_price_sell
load price_C
load price_H
load price_G
PV=2*PV;
WT=2*WT;
L_load=1.5*L_load;
global P_load;  %����ȫ�ֱ���  �縺��
global R_load; %����ȫ�ֱ���  �ȸ���
global L_load; %����ȫ�ֱ���  �为��
global  G_price_buy;%�����ۣ�1.2�������ۣ�
global G_price_sell;%������
global PV;%�����������
global WT;%����������
global  price_C %����۸�
global price_H %���ȼ۸�
global price_G %����۸�
% Grid ��   ��heat  �� cool
gas_price=0.175;  %����
ngas_G=0.35; %��ת��Ч��
ngas_h=0.9; %��ת��Ч��
ngas_c=0.9; %��ת��Ч��
nGB_h=0.9; %���ȹ�¯����Ч��
COP_EC=3.5; %�������������Ч��
price_G=[0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000,1.20000000000000,1.20000000000000,1.20000000000000,1.20000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,1.20000000000000,1.20000000000000,1.20000000000000,0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000];
price_C=price_H;
%��ʼ������****************************************
%��ȼ���������ֵ
GTMaxPower=200;
%��ȼ��������Сֵ
GTMinPower=0;
%���ȹ�¯�������
GBMaxPower=100;
%���ȹ�¯����С����
GBMinPower=0;
%�����������������
ECMaxPower=50;
%��������������С����
ECMinPower=0;
%������󹺵繦��
GridMaxPower=200;
%������С���繦��
GriMinPower=-100;
mm=mopso();
nn=length(mm.swarm);%%%�ҵ����յ�ǰ�����е�����
%%%�ҳ�ǰ��������ӣ����ǵ�����Ŀ�꺯��ֵ
for i=1:nn
   xx(i)= mm.swarm(1,i).cost(1);
  yy(i)= mm.swarm(1,i).cost(2);
   zz(i)=mm.swarm(1,i).cost(3);
end
%%%����һ���Ĺ�����ǰ������ѡ�����ŵ����ӣ�������Ժ����ı䣬��Ҫ��Ϊ�˺�����ͼ������õó�һ���������ܻ���ͼ��
m1=max( xx);
m2=max( yy);
m3=max( zz);
for i=1:nn
    object(i)= mm.swarm(1,i).cost(1)./m1+ mm.swarm(1,i).cost(2)./m2+ mm.swarm(1,i).cost(3)./m3;
  
end
[m,p]=min(object);                     %%�ҵ�object�����ģ�������ֵ��m����������object�е�����Ϊp
pg=mm.swarm(1,p).x;                    %%����object���������ڶ����Ⱥ�е�λ��mm.swarm(1,p)����������������x������x�洢�����Ż�����

%%%�ҵ������ŵ��Ǹ����ӣ������Ƿ������еĸ����Ż����

P_gas_G=pg(1:24)*ngas_G;                     
P_gas_H=pg(1:24)*ngas_h;
P_gas_C=pg(1:24)*ngas_c;
P_gas=pg(1:24); %��Ȼ������ ���������ҵ������ŵ����ӣ�ǰ24������Ȼ������
P_mh=pg(25:48);  %���ȹ�¯����
P_mc=pg(49:72);  %�����������
P_GBh=pg(25:48)*nGB_h;
P_EC=pg(49:72)*COP_EC;
G_PV=pg(97:120);  %���
G_WT=pg(121:144);  %���
G_grid=pg(73:96);  %����
response_L=pg(145:168); %���ȵ縺�ɵı仯��
response_R=pg(169:192);
response_P=pg(193:216);
dload_L=(L_load+response_L)-(P_EC+P_gas_C);  %�为�ɵĹ��ʲ�ƽ���� ���Կ������ܵĳ���
dload_R=(R_load+response_R)-(P_GBh+P_gas_H);  %�ȸ��ɵĹ��ʲ�ƽ����
dload_P=(P_load+response_P)-(G_PV+G_WT+P_gas_G+G_grid-P_mh-P_mc);  %�縺�ɵĹ��ʲ�ƽ����  ��ΪG_grid  ��Ϊ���  ��Ϊ����
 for i=1:24
    profit(i)=(0.86-0.23)*1000*G_PV(i)+(0.53-0.16)*1000*G_WT(i); %�������  ����-�ɱ�
 end 
 cost_buy=0;
 cost_sell=0;
  for i=1:24
  CCHP_benefit(i)=price_G(i)*1000*P_gas_G(i)+price_H(i)*1000*P_gas_H(i)+price_C(i)*1000*P_gas_C(i); %CCHP  �����ȵ�����
  if G_grid(i)>0
      cost_buy= cost_buy+G_grid(i)* G_price_buy(i);
  else 
   cost_sell=cost_sell+G_grid(i)* G_price_sell(i);
  end 
 cost_device(i)=0.02*P_mh(i)+0.023*P_mc(i)+0.075*P_gas(i);  %�豸�ɱ�
 benefit_grid(i)=G_price_sell(i)*(P_mc(i)+P_mh(i));
 
  end
 
  for i=1:24
  uesrs_buy(i)=price_G(i)*1000*(P_load(i)+response_P(i))+price_H(i)*1000*(R_load(i)+response_R(i))+price_C(i)*1000*(L_load(i)+response_L(i)); %CCHP  �����ȵ�����

  end

y(1) =sum( profit);
y(2) = sum(CCHP_benefit)+cost_sell+sum( benefit_grid)-cost_buy-sum(cost_device);  %CCHP ����+��������-���ֳɱ�
y(3)=sum(  uesrs_buy); %�û���������ĳɱ�


figure(2)
bar( G_grid-P_mh-P_mc)
hold on
plot( G_PV,'-d')
xlim([1 24])
grid

plot( G_WT,'-*')

plot(P_gas_G,'-s')
plot(P_load+response_P,'-^')
plot(P_load,'-+')
grid
title('���������мƻ�')
legend('���۵�','��� ','���','��ת��','������Ӧ����','ԭ����')
xlabel('ʱ��')
ylabel('����')


figure(3)
plot( P_GBh,'-d')
xlim([1 24])
hold on
plot(P_gas_H,'-*')

plot(R_load+response_R,'-^')
plot(R_load,'-+')
grid
title('�������мƻ�')
legend('���ȹ�¯','��ת��','������Ӧ����','ԭ����')
xlabel('ʱ��')
ylabel('����')

figure(4)
plot( P_EC,'-d')
xlim([1 24])
hold on
plot(P_gas_C,'-*')

plot(L_load+response_L,'-^')
plot(L_load,'-+')
grid
title('�������мƻ�')
legend('�������','��ת��','������Ӧ����','ԭ����')
xlabel('ʱ��')
ylabel('����')



disp('�Ż���ĸ���ɱ�������')
y