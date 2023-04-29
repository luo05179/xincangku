classdef Particle
    properties
        x%%位置
        l%%下限
        u%%上限
        v%%速度
        cost%%成本
        infeasablity%%可行性
        pBest%%个体极值的位置，即个体最优解
        pBestCost%%个体成本
        pBestinfeasablity%%可行性
        GridIndex%%网格数
        isDominated%%是否被支配，false就是没有
    end
    methods
        function obj = Particle(lower,upper,problem)%%%（1）初始化函数
            if nargin > 0
                obj.GridIndex = 0;
                obj.isDominated = false;%%%是否被支配的判断，这个表示没有被支配
                obj.x = unifrnd(lower,upper);   %（1）初始化是生成均匀分布数组
                obj.l = lower;
                obj.u = upper;
                obj.v = zeros(1,max(length(lower),length(upper)));
                [obj.cost, obj.infeasablity] = problem(obj.x);%%%这里的problem是目标函数，在mopso中是函数句柄@prob，主要改这个脚本，x里面存的就是变量
                obj.pBest = obj.x;                            %%%problem函数会计算出三个目标函数的成本及可行性c
                obj.pBestCost = obj.cost;
                obj.pBestinfeasablity = obj.infeasablity;
            end
        end
        function obj = update(obj,w,c,pm,gBest,problem)%（2）更新函数
            obj = obj.updateV(w,c,gBest);%速度更新，下式有
            obj = obj.updateX();%位置更新，下式有
            [obj.cost, obj.infeasablity] = problem(obj.x);%重新计算目标函数
            obj = obj.applyMutatation(pm,problem);%突变，下式有
            obj = obj.updatePbest();%个体最优值更新，下式有
        end
        function obj = updateV(obj,w,c,gBest)%%%速度更新公式
            obj.v = w.*obj.v + c(1).*rand.*(obj.pBest-obj.x) + c(2).*rand.*(gBest.x-obj.x);
        end
        function obj = updateX(obj)%%%位置更新公式
            i=find(or(obj.x+obj.v>obj.u,obj.x+obj.v<obj.l));
            obj.v(i) = -obj.v(i);
            obj.x = max(min(obj.x+obj.v,obj.u),obj.l);
        end
        function obj = updatePbest(obj)
            if obj.infeasablity == 0
                if obj.pBestinfeasablity > 0
                    obj.pBest = obj.x;
                    obj.pBestCost = obj.cost;
                    obj.pBestinfeasablity = obj.infeasablity;
                elseif all(obj.pBestCost >= obj.cost) && any(obj.pBestCost > obj.cost)
                    obj.pBest = obj.x;
                    obj.pBestCost = obj.cost;
                    obj.pBestinfeasablity = obj.infeasablity;
                end
            else
                if obj.pBestinfeasablity >= obj.infeasablity
                    obj.pBest = obj.x;
                    obj.pBestCost = obj.cost;
                    obj.pBestinfeasablity = obj.infeasablity;
                end
            end
        end
        function obj = applyMutatation(obj,pm,problem)%%%突变应用
            if rand<pm
                X=obj.Mutate(pm);
                [X.cost,X.infeasablity]=problem(X.x);%%对突变后的数值计算成本及可行性
                if X.dominates(obj)
                    obj=X;
                elseif ~obj.dominates(X)
                    if rand<0.5
                        obj=X;
                    end
                end
            end
        end
        function obj=Mutate(obj,pm)%对突变的进一步解释
            nVar=numel(obj.x);
            j=randi([1 nVar]);
            dx=pm*(obj.u(j)-obj.l(j));
            lb=max(obj.x(j)-dx,obj.l(j));
            ub=min(obj.x(j)+dx,obj.u(j));
            obj.x(j)=unifrnd(lb,ub);
        end
        function d = dominates(obj,obj1)%%支配，也是突变步骤里面应用到的
            if obj.infeasablity == 0
                if obj1.infeasablity == 0
                    if all(obj.cost <= obj1.cost) &&  any(obj.cost < obj1.cost)
                        d = true;
                    else
                        d = false;
                    end
                else
                    d = true;
                end
            elseif obj1.infeasablity == 0
                d = false;
            elseif obj.infeasablity < obj1.infeasablity
                d = true;
            else
                d = false;
            end
        end
        function obj=updateGridIndex(obj,Grid)%%更新粒子所在的网格标号
            nObj=length(obj.cost);
            nGrid=length(Grid(1).LB);
            GridSubIndex=zeros(1,nObj);
            for j=1:nObj
                GridSubIndex(j)=find(obj.cost(j)<Grid(j).UB,1,'first');
            end
            obj.GridIndex=GridSubIndex(1);
            for j=2:nObj
                obj.GridIndex=obj.GridIndex-1;
                obj.GridIndex=nGrid*obj.GridIndex;
                obj.GridIndex=obj.GridIndex+GridSubIndex(j);
            end
        end
    end
    methods (Static)
        function swarm = updateDomination(swarm)%%存档时用，每次存档都是存的更新过的前沿面
            for index = 1:length(swarm)
            swarm(index).isDominated = false;
                for i = 1:length(swarm)
                    if i == index
                        continue
                    end
                    if swarm(i).dominates(swarm(index))
                        swarm(index).isDominated = true;
                        break
                    end
                end
            end
        end
    end
end

