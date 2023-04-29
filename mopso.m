function [REP]= mopso(c,iw,max_iter,lower_bound,upper_bound,swarm_size,rep_size,grid_size,alpha,beta,gamma,mu,problem)
%mopso is an implementation of multi objective particle swarm optimization
%technique for a minimization problem
%% initialize parameters
global PV;
global WT;
%天燃气供给最大值
GTMaxPower=80;
%天燃气供给最小值
GTMinPower=0;
%电热锅炉的最大功率
GBMaxPower=200;
%电热锅炉的最小功率
GBMinPower=0;
%电制冷机与电网最大功率
ECMaxPower=20;
%电制冷机与电网最小功率
ECMinPower=0;
%电网最大购电功率
GridMaxPower=500;
%电网最小购电功率
GriMinPower=-200;
if nargin==0
    c = [0.1,0.2]; % [cognitive acceleration, social acceleration] coefficients
    iw = [0.5 0.001]; % [starting, ending] inertia weight
    max_iter = 100; % maximum iterations
     for j=1:216                           %9*24，共9个变量的24小时  所有的上下限要在这里定义！！！！！
        if j<7
            upper_bound(j)=1;
            lower_bound (j)=GTMinPower;
           elseif j>6&&j<19
           upper_bound(j)=GTMaxPower;
            lower_bound (j)=GTMinPower;
              elseif j>18&&j<25
           upper_bound(j)=20;
            lower_bound (j)=GTMinPower;     %天然气供给量约束
        elseif j>24&&j<31
           upper_bound(j)=1;
            lower_bound (j)=GBMinPower;
              elseif j>30&&j<49
           upper_bound(j)=GBMaxPower;
            lower_bound (j)=GBMinPower;      %电热锅炉出力约束
        elseif j>48&&j<55
              upper_bound(j)=1;
            lower_bound (j)=ECMinPower;
             elseif j>54&&j<73
              upper_bound(j)=ECMaxPower;
            lower_bound (j)=ECMinPower;        %电制冷机出力约束
             elseif j>72&&j<97
              upper_bound(j)=GridMaxPower;
            lower_bound (j)=GriMinPower;       %电网购电约束
              elseif j>96&&j<121
       
              upper_bound(j)=PV(j-96);
            lower_bound (j)=0;                 %PV出力约束，对应到PV出力预测数据
              elseif j>120&&j<145
              upper_bound(j)=WT(j-120);
            lower_bound (j)=0;                  %WT出力约束
             elseif j>144&&j<169
              upper_bound(j)=10;
            lower_bound (j)=-10;                %  冷负荷的变化量，估计是需求响应来的
             elseif j>168&&j<193
              upper_bound(j)=20;
            lower_bound (j)=-20;                 %  热负荷的变化量，应该也是需求响应
             elseif j>192
              upper_bound(j)=30;
            lower_bound (j)=-30;                 %   电负荷的变化量，同样为需求响应
        
        end
     end
 %%%%%多目标优化的基本参数设置
    swarm_size=100; % swarm size
    rep_size=100; % Repository Size
    grid_size=7; % Number of Grids per Dimension，网格数
    alpha=0.1; % Inflation Rate
    beta=2; % Leader Selection Pressure
    gamma=2; % Deletion Selection Pressure
    mu=0.1; % Mutation Rate
    problem=@prob; % objective function
end
%% initialize particles
fprintf('Initializing swarm ...\n')
w = @(it) ((max_iter - it) - (iw(1) - iw(2)))/max_iter + iw(2);
pm = @(it) (1-(it-1)/(max_iter-1))^(1/mu);
swarm(1,swarm_size) = Particle();%%生成100个粒子，每一个粒子都包含Particle中定义的属性
for i = 1:swarm_size
    swarm(i)=Particle(lower_bound,upper_bound,problem);    %  Particle是个类，群swarm里的每个个体都是一个粒子，这个粒子就是particle类     
    retry = 0;                                              %有很多属性
    while swarm(i).infeasablity > 0 && retry < 100
        swarm(i)=Particle(lower_bound,upper_bound,problem);
        retry = retry + 1;
    end
end
REP = Repository(swarm,rep_size,grid_size,alpha,beta,gamma);%将初始化的粒子进行存档
%% Loop
fprintf('Starting the optimization loop ...\n')
for it=1:max_iter
    leader = REP.SelectLeader();%%领导者选择
    wc = w(it); %current inertia weight，权重和突变率是变化的
    pc=pm(it); %current mutation rate
    for i =1:swarm_size %update particles
        swarm(i)=swarm(i).update(wc,c,pc,leader,problem);%%存档中的粒子更新，即当前前沿面存在的那些粒子要开始向更好的方向更新
    end
    REP = REP.update(swarm);
    Title = sprintf('Iteration %d, Number of Rep Members = %d',it,length(REP.swarm));
    PlotCosts(swarm,REP.swarm,Title)
    disp(Title);
end
end
function PlotCosts(swarm,rep,Title)
figure(1)
feasable_swarm = swarm([swarm.infeasablity]==0);
infeasable_swarm = swarm([swarm.infeasablity]>0);
LEG = {};
if ~isempty(feasable_swarm)
    swarm_costs=vertcat(feasable_swarm.cost);
    plot3(1000000-swarm_costs(:,1),swarm_costs(:,2), swarm_costs(:,3),'go')%%画每次迭代过程中的可行解和不可行解，这里的成本要变一下！！
    hold on
    LEG = {'Current feasable SWARM'};
    Title = sprintf([Title '\nfeasable swarm=%d'],length(feasable_swarm));
end
if ~isempty(infeasable_swarm)
    swarm_costs=vertcat(infeasable_swarm.cost);
    plot3(1000000-swarm_costs(:,1),swarm_costs(:,2),swarm_costs(:,3),'ro')
    hold on
    LEG = [LEG, 'Current infeasable SWARM'];
    if contains(Title,newline)
        Title = sprintf([Title ', infeasable swarm=%d'],length(infeasable_swarm));
    else
        Title = sprintf([Title '\ninfeasable swarm=%d'],length(infeasable_swarm));
    end
end
rep_costs=vertcat(rep.cost);%%%垂直连接数组，将rep.cost连接起来，即所有存档粒子的成本
plot3(1000000-rep_costs(:,1),rep_costs(:,2), rep_costs(:,3),'b*')
xlabel('1^{st} Objective')
ylabel('2^{nd} Objective')
zlabel('3^{nd} Objective')
grid on
hold off
title(Title)
legend([LEG ,'REPASITORY'],'location','best')
drawnow
end