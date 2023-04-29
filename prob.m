function [y,c] = prob(x)
global P_load;  %����ȫ�ֱ���  �縺��
global R_load; %����ȫ�ֱ���  �ȸ���
global L_load; %����ȫ�ֱ���  �为��
global  G_price_buy;%������
global G_price_sell;%������
global  price_C %����۸�
global price_H %���ȼ۸�
global price_G %����۸�
% Grid ��   ��heat  �� cool
ngas_G=0.35; %��ת��Ч��
ngas_h=0.9; %��ת��Ч��
ngas_c=0.9; %��ת��Ч��
nGB_h=0.9; %���ȹ�¯����Ч��
COP_EC=3.5; %�������������Ч��
BT_max=30;
% x:1-24 CCHP 25-48�����ȹ�¯  49-72��������  73-96���������۵�  97-120��PV   121-144 ��WT
%ֱ�ӽ������x�����Լ����Ż������ֲ�����
P_gas_G=x(1:24)*ngas_G;
P_gas_H=x(1:24)*ngas_h;
P_gas_C=x(1:24)*ngas_c;
P_gas=x(1:24);
P_mh=x(25:48);
P_mc=x(49:72);
P_GBh=x(25:48)*nGB_h;
P_EC=x(49:72)*COP_EC;
G_PV=x(97:120);
G_WT=x(121:144);
G_grid=x(73:96);
response_L=x(145:168);
response_R=x(169:192);
response_P=x(193:216);
dload_L=(L_load+response_L)-(P_EC+P_gas_C);  %�为�ɵĹ��ʲ�ƽ����
dload_R=(R_load+response_R)-(P_GBh+P_gas_H);  %�ȸ��ɵĹ��ʲ�ƽ����
dload_P=(P_load+response_P)-(G_PV+G_WT+P_gas_G+G_grid-P_mh-P_mc);  %�縺�ɵĹ��ʲ�ƽ����  ��ΪG_grid  ��Ϊ���  ��Ϊ����
 rp_L_sum=0;
 rp_R_sum=0;
 rp_P_sum=0;
 rp_L_sum=sum(response_L);
 rp_R_sum=sum(response_R);
 rp_P_sum=sum(response_P);
c=1;
c1=1;
c2=1;
c3=1;
c4=1;
re_sum_CCHP= abs(rp_L_sum)+ abs(rp_R_sum)+ abs(rp_R_sum);  %�������Ӧ����ƽ��Ĵ���
if re_sum_CCHP>100
    c4=0;
end
   d_sum1=sum(abs(dload_L));
if d_sum1>1000
     c1=0;
end
   d_sum2=sum(abs(dload_R));
if d_sum2>1500
     c2=0;
end
   d_sum3=sum(abs(dload_P));
if d_sum3>2500
     c3=0;
end
 
c=1-c1*c2*c3*c4;%%%������ϵ����Ϊ1�򲻿��У�Ϊ0������ζ��c1234��Ϊ1����ʽԼ���������������ʽ�Ļ����÷�����
BT_L=0;
BT_R=0;
BT_P=0;
BT_L_sum=0;
BT_R_sum=0;
BT_P_sum=0;
for  i=1:24
   BT_L= BT_L+dload_L(i);
   BT_R= BT_R+dload_R(i);
   BT_P= BT_P+dload_P(i);
   if  BT_L<0
       BT_L_sum= BT_L_sum+abs( BT_L);
   elseif  BT_L>BT_max
        BT_L_sum= BT_L_sum+abs( BT_L-BT_max);
   end
   
      if  BT_R<0
       BT_R_sum= BT_R_sum+abs( BT_R);
   elseif  BT_L>BT_max
        BT_R_sum= BT_R_sum+abs( BT_R-BT_max);
      end
   
    if  BT_P<0
       BT_P_sum= BT_P_sum+abs( BT_P);
   elseif  BT_L>BT_max
        BT_P_sum= BT_P_sum+abs( BT_P-BT_max);
    end  
end
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

y(1) =1000000- sum( profit);
y(2) =10000000-  sum(CCHP_benefit)+cost_sell+sum( benefit_grid)-cost_buy-sum(cost_device);  %CCHP ����+��������-���ֳɱ�
y(3)=sum(  uesrs_buy); %�û���������ĳɱ�

end