function [REP]= mopso(c,iw,max_iter,lower_bound,upper_bound,swarm_size,rep_size,grid_size,alpha,beta,gamma,mu,problem)
%mopso is an implementation of multi objective particle swarm optimization
%technique for a minimization problem
%% initialize parameters
global PV;
global WT;
%��ȼ���������ֵ
GTMaxPower=80;
%��ȼ��������Сֵ
GTMinPower=0;
%���ȹ�¯�������
GBMaxPower=200;
%���ȹ�¯����С����
GBMinPower=0;
%�����������������
ECMaxPower=20;
%��������������С����
ECMinPower=0;
%������󹺵繦��
GridMaxPower=500;
%������С���繦��
GriMinPower=-200;
if nargin==0
    c = [0.1,0.2]; % [cognitive acceleration, social acceleration] coefficients
    iw = [0.5 0.001]; % [starting, ending] inertia weight
    max_iter = 100; % maximum iterations
     for j=1:216                           %9*24����9��������24Сʱ  ���е�������Ҫ�����ﶨ�壡��������
        if j<7
            upper_bound(j)=1;
            lower_bound (j)=GTMinPower;
           elseif j>6&&j<19
           upper_bound(j)=GTMaxPower;
            lower_bound (j)=GTMinPower;
              elseif j>18&&j<25
           upper_bound(j)=20;
            lower_bound (j)=GTMinPower;     %��Ȼ��������Լ��
        elseif j>24&&j<31
           upper_bound(j)=1;
            lower_bound (j)=GBMinPower;
              elseif j>30&&j<49
           upper_bound(j)=GBMaxPower;
            lower_bound (j)=GBMinPower;      %���ȹ�¯����Լ��
        elseif j>48&&j<55
              upper_bound(j)=1;
            lower_bound (j)=ECMinPower;
             elseif j>54&&j<73
              upper_bound(j)=ECMaxPower;
            lower_bound (j)=ECMinPower;        %�����������Լ��
             elseif j>72&&j<97
              upper_bound(j)=GridMaxPower;
            lower_bound (j)=GriMinPower;       %��������Լ��
              elseif j>96&&j<121
       
              upper_bound(j)=PV(j-96);
            lower_bound (j)=0;                 %PV����Լ������Ӧ��PV����Ԥ������
              elseif j>120&&j<145
              upper_bound(j)=WT(j-120);
            lower_bound (j)=0;                  %WT����Լ��
             elseif j>144&&j<169
              upper_bound(j)=10;
            lower_bound (j)=-10;                %  �为�ɵı仯����������������Ӧ����
             elseif j>168&&j<193
              upper_bound(j)=20;
            lower_bound (j)=-20;                 %  �ȸ��ɵı仯����Ӧ��Ҳ��������Ӧ
             elseif j>192
              upper_bound(j)=30;
            lower_bound (j)=-30;                 %   �縺�ɵı仯����ͬ��Ϊ������Ӧ
        
        end
     end
 %%%%%��Ŀ���Ż��Ļ�����������
    swarm_size=100; % swarm size
    rep_size=100; % Repository Size
    grid_size=7; % Number of Grids per Dimension��������
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
swarm(1,swarm_size) = Particle();%%����100�����ӣ�ÿһ�����Ӷ�����Particle�ж��������
for i = 1:swarm_size
    swarm(i)=Particle(lower_bound,upper_bound,problem);    %  Particle�Ǹ��࣬Ⱥswarm���ÿ�����嶼��һ�����ӣ�������Ӿ���particle��     
    retry = 0;                                              %�кܶ�����
    while swarm(i).infeasablity > 0 && retry < 100
        swarm(i)=Particle(lower_bound,upper_bound,problem);
        retry = retry + 1;
    end
end
REP = Repository(swarm,rep_size,grid_size,alpha,beta,gamma);%����ʼ�������ӽ��д浵
%% Loop
fprintf('Starting the optimization loop ...\n')
for it=1:max_iter
    leader = REP.SelectLeader();%%�쵼��ѡ��
    wc = w(it); %current inertia weight��Ȩ�غ�ͻ�����Ǳ仯��
    pc=pm(it); %current mutation rate
    for i =1:swarm_size %update particles
        swarm(i)=swarm(i).update(wc,c,pc,leader,problem);%%�浵�е����Ӹ��£�����ǰǰ������ڵ���Щ����Ҫ��ʼ����õķ������
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
    plot3(1000000-swarm_costs(:,1),swarm_costs(:,2), swarm_costs(:,3),'go')%%��ÿ�ε��������еĿ��н�Ͳ����н⣬����ĳɱ�Ҫ��һ�£���
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
rep_costs=vertcat(rep.cost);%%%��ֱ�������飬��rep.cost���������������д浵���ӵĳɱ�
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