classdef Particle
    properties
        x%%λ��
        l%%����
        u%%����
        v%%�ٶ�
        cost%%�ɱ�
        infeasablity%%������
        pBest%%���弫ֵ��λ�ã����������Ž�
        pBestCost%%����ɱ�
        pBestinfeasablity%%������
        GridIndex%%������
        isDominated%%�Ƿ�֧�䣬false����û��
    end
    methods
        function obj = Particle(lower,upper,problem)%%%��1����ʼ������
            if nargin > 0
                obj.GridIndex = 0;
                obj.isDominated = false;%%%�Ƿ�֧����жϣ������ʾû�б�֧��
                obj.x = unifrnd(lower,upper);   %��1����ʼ�������ɾ��ȷֲ�����
                obj.l = lower;
                obj.u = upper;
                obj.v = zeros(1,max(length(lower),length(upper)));
                [obj.cost, obj.infeasablity] = problem(obj.x);%%%�����problem��Ŀ�꺯������mopso���Ǻ������@prob����Ҫ������ű���x�����ľ��Ǳ���
                obj.pBest = obj.x;                            %%%problem��������������Ŀ�꺯���ĳɱ���������c
                obj.pBestCost = obj.cost;
                obj.pBestinfeasablity = obj.infeasablity;
            end
        end
        function obj = update(obj,w,c,pm,gBest,problem)%��2�����º���
            obj = obj.updateV(w,c,gBest);%�ٶȸ��£���ʽ��
            obj = obj.updateX();%λ�ø��£���ʽ��
            [obj.cost, obj.infeasablity] = problem(obj.x);%���¼���Ŀ�꺯��
            obj = obj.applyMutatation(pm,problem);%ͻ�䣬��ʽ��
            obj = obj.updatePbest();%��������ֵ���£���ʽ��
        end
        function obj = updateV(obj,w,c,gBest)%%%�ٶȸ��¹�ʽ
            obj.v = w.*obj.v + c(1).*rand.*(obj.pBest-obj.x) + c(2).*rand.*(gBest.x-obj.x);
        end
        function obj = updateX(obj)%%%λ�ø��¹�ʽ
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
        function obj = applyMutatation(obj,pm,problem)%%%ͻ��Ӧ��
            if rand<pm
                X=obj.Mutate(pm);
                [X.cost,X.infeasablity]=problem(X.x);%%��ͻ������ֵ����ɱ���������
                if X.dominates(obj)
                    obj=X;
                elseif ~obj.dominates(X)
                    if rand<0.5
                        obj=X;
                    end
                end
            end
        end
        function obj=Mutate(obj,pm)%��ͻ��Ľ�һ������
            nVar=numel(obj.x);
            j=randi([1 nVar]);
            dx=pm*(obj.u(j)-obj.l(j));
            lb=max(obj.x(j)-dx,obj.l(j));
            ub=min(obj.x(j)+dx,obj.u(j));
            obj.x(j)=unifrnd(lb,ub);
        end
        function d = dominates(obj,obj1)%%֧�䣬Ҳ��ͻ�䲽������Ӧ�õ���
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
        function obj=updateGridIndex(obj,Grid)%%�����������ڵ�������
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
        function swarm = updateDomination(swarm)%%�浵ʱ�ã�ÿ�δ浵���Ǵ�ĸ��¹���ǰ����
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

