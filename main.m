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
global P_load;  %定义全局变量  电负荷
global R_load; %定义全局变量  热负荷
global L_load; %定义全局变量  冷负荷
global  G_price_buy;%购电电价（1.2倍卖电电价）
global G_price_sell;%卖电电价
global PV;%光伏出力功率
global WT;%风电出力功率
global  price_C %供冷价格
global price_H %供热价格
global price_G %供电价格
% Grid 电   热heat  冷 cool
gas_price=0.175;  %气价
ngas_G=0.35; %气转电效率
ngas_h=0.9; %气转热效率
ngas_c=0.9; %气转冷效率
nGB_h=0.9; %电热锅炉的热效率
COP_EC=3.5; %电制冷机的制冷效率
price_G=[0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000,1.20000000000000,1.20000000000000,1.20000000000000,1.20000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,0.720000000000000,1.20000000000000,1.20000000000000,1.20000000000000,0.312000000000000,0.312000000000000,0.312000000000000,0.312000000000000];
price_C=price_H;
%初始化条件****************************************
%天燃气供给最大值
GTMaxPower=200;
%天燃气供给最小值
GTMinPower=0;
%电热锅炉的最大功率
GBMaxPower=100;
%电热锅炉的最小功率
GBMinPower=0;
%电制冷机与电网最大功率
ECMaxPower=50;
%电制冷机与电网最小功率
ECMinPower=0;
%电网最大购电功率
GridMaxPower=200;
%电网最小购电功率
GriMinPower=-100;
mm=mopso();
nn=length(mm.swarm);%%%找到最终的前沿面中的粒子
%%%找出前沿面的粒子，他们的三个目标函数值
for i=1:nn
   xx(i)= mm.swarm(1,i).cost(1);
  yy(i)= mm.swarm(1,i).cost(2);
   zz(i)=mm.swarm(1,i).cost(3);
end
%%%依据一定的规则，在前沿面中选出最优的粒子，这里可以后续改变，主要是为了后续画图，必须得得出一个方案才能画出图来
m1=max( xx);
m2=max( yy);
m3=max( zz);
for i=1:nn
    object(i)= mm.swarm(1,i).cost(1)./m1+ mm.swarm(1,i).cost(2)./m2+ mm.swarm(1,i).cost(3)./m3;
  
end
[m,p]=min(object);                     %%找到object中最大的，并返回值给m，返回其在object中的索引为p
pg=mm.swarm(1,p).x;                    %%查找object最大的粒子在定义的群中的位置mm.swarm(1,p)，并查找他的属性x，属性x存储的是优化变量

%%%找到了最优的那个粒子，现在是返回其中的各种优化结果

P_gas_G=pg(1:24)*ngas_G;                     
P_gas_H=pg(1:24)*ngas_h;
P_gas_C=pg(1:24)*ngas_c;
P_gas=pg(1:24); %天然气出力 ，这里是找到了最优的粒子，前24个是天然气出力
P_mh=pg(25:48);  %电热锅炉出力
P_mc=pg(49:72);  %电制冷机出力
P_GBh=pg(25:48)*nGB_h;
P_EC=pg(49:72)*COP_EC;
G_PV=pg(97:120);  %光伏
G_WT=pg(121:144);  %风电
G_grid=pg(73:96);  %电网
response_L=pg(145:168); %冷热电负荷的变化量
response_R=pg(169:192);
response_P=pg(193:216);
dload_L=(L_load+response_L)-(P_EC+P_gas_C);  %冷负荷的功率不平衡量 可以看做储能的出力
dload_R=(R_load+response_R)-(P_GBh+P_gas_H);  %热负荷的功率不平衡量
dload_P=(P_load+response_P)-(G_PV+G_WT+P_gas_G+G_grid-P_mh-P_mc);  %电负荷的功率不平衡量  认为G_grid  正为买电  负为卖电
 for i=1:24
    profit(i)=(0.86-0.23)*1000*G_PV(i)+(0.53-0.16)*1000*G_WT(i); %光伏收益  卖价-成本
 end 
 cost_buy=0;
 cost_sell=0;
  for i=1:24
  CCHP_benefit(i)=price_G(i)*1000*P_gas_G(i)+price_H(i)*1000*P_gas_H(i)+price_C(i)*1000*P_gas_C(i); %CCHP  供冷热电收益
  if G_grid(i)>0
      cost_buy= cost_buy+G_grid(i)* G_price_buy(i);
  else 
   cost_sell=cost_sell+G_grid(i)* G_price_sell(i);
  end 
 cost_device(i)=0.02*P_mh(i)+0.023*P_mc(i)+0.075*P_gas(i);  %设备成本
 benefit_grid(i)=G_price_sell(i)*(P_mc(i)+P_mh(i));
 
  end
 
  for i=1:24
  uesrs_buy(i)=price_G(i)*1000*(P_load(i)+response_P(i))+price_H(i)*1000*(R_load(i)+response_R(i))+price_C(i)*1000*(L_load(i)+response_L(i)); %CCHP  供冷热电收益

  end

y(1) =sum( profit);
y(2) = sum(CCHP_benefit)+cost_sell+sum( benefit_grid)-cost_buy-sum(cost_device);  %CCHP 收益+卖电收益-各种成本
y(3)=sum(  uesrs_buy); %用户购电热冷的成本


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
title('电网网运行计划')
legend('购售电','光伏 ','风电','气转电','需求响应负荷','原负荷')
xlabel('时间')
ylabel('功率')


figure(3)
plot( P_GBh,'-d')
xlim([1 24])
hold on
plot(P_gas_H,'-*')

plot(R_load+response_R,'-^')
plot(R_load,'-+')
grid
title('热网运行计划')
legend('电热锅炉','气转热','需求响应负荷','原负荷')
xlabel('时间')
ylabel('功率')

figure(4)
plot( P_EC,'-d')
xlim([1 24])
hold on
plot(P_gas_C,'-*')

plot(L_load+response_L,'-^')
plot(L_load,'-+')
grid
title('冷网运行计划')
legend('电制冷机','气转冷','需求响应负荷','原负荷')
xlabel('时间')
ylabel('功率')



disp('优化后的各项成本和收益')
y