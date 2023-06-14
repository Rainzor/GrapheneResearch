% 定义常量
a = 1.42e-10;    % 晶格常数
m = 1.99e-26;    % 碳原子质量
kpoints = 400;
h_bar = 1.0546e-34;
kB = 1.38065e-23;
% 设置参数 a

% 计算顶点坐标
b1 = 2*pi / (3*a);
b2 = 2*pi / (sqrt(3)*a);

% 创建矩形网格
[x, y] = meshgrid(linspace(-b1,b1,kpoints), linspace(-b2,b2,kpoints));

% 找到位于菱形内部的点
in_diamond = (abs(x/b1) + abs(y/b2)) <= 1;

% 获取位于菱形内部的点的坐标
x_diamond = x(in_diamond);
y_diamond = y(in_diamond);

% 生成力常数的对角矩阵
f = diag([36.50, 24.50, 9.82, 8.80, -3.23, -0.40, 3.00, -5.25, 0.15, -1.92, 2.29, -0.58])*10 ;



% 以A为圆心周围的原子的坐标 以及 B的相应坐标
[FA, FB] = rotate(2/3*pi, [1; 0; 0]*a);          % 第一近邻
[SA, SB] = rotate(1/3*pi, [3/2; sqrt(3)/2; 0]*a);     % 第二近邻
[TA, TB] = rotate(2/3*pi, [1; sqrt(3); 0]*a);         % 第三近邻
[LA1, LB1] = rotate(2/3*pi, [2.5; sqrt(3)/2; 0]*a);   % 第四近邻，两种角度
[LA2, LB2] = rotate(2/3*pi, [2.5; -sqrt(3)/2; 0]*a);
LA = [LA1, LA2];                                       
LB = [LB1, LB2];

% 得到初始K矩阵，角度由文献的图9.1 可知，分别得到（a）图和(b)图情况的初始K矩阵
[KAB1, KBA1] = rotate(2/3*pi, f(1:3, 1:3));
[KAA, KBB] = rotate(1/3*pi, K(1/6*pi, f(4:6, 4:6)));
[KAB3, KBA3] = rotate(2/3*pi, K(1/3*pi, f(7:9, 7:9)));
[KAB4f, KBA4f] = rotate(2/3*pi, K(acos(2.5/sqrt(7)), f(10:12, 10:12)));
[KAB4s, KBA4s] = rotate(2/3*pi, K(2*pi-acos(2.5/sqrt(7)), f(10:12, 10:12)));
KAB4 = cat(3,KAB4f, KAB4s);
KBA4 = cat(3,KBA4f, KBA4s);

kpoints = length(x_diamond);
k_list = zeros(3,kpoints);
for ii = 1:kpoints
    k_list(:,ii) = [x_diamond(ii);y_diamond(ii);0];
end

% 求解本征值
kpoints = size(k_list,2);
W = zeros(6,kpoints);
for ii = 1:kpoints
        k = k_list(:,ii)';
        % 计算动力学矩阵
        D = zeros(6, 6);
        DAAs = zeros(3,3);
        DBBs = zeros(3,3);
        DBAs = zeros(3,3);
        DABs = zeros(3,3);
        % 以上四个矩阵由文献的 9.7 式可知，并组合成一个完整的D矩阵
        for ll = 1:3
            DAAs = DAAs + KAA(:,:,ll) * exp(1i * k * (-SA(:, ll))) + KAA(:,:,ll+3) * exp(1i * k * (-SA(:, ll+3)));
            DBBs = DBBs + KBB(:,:,ll) * exp(1i * k * (-SB(:, ll))) + KBB(:,:,ll+3) * exp(1i * k * (-SB(:, ll+3)));
            DABs = DABs + KAB1(:,:,ll) * exp(1i * k * (-FA(:, ll))) + KAB3(:,:,ll) * exp(1i * k * (-TA(:, ll))) +...
                   KAB4(:,:,ll) * exp(1i * k * (-LA(:, ll))) + KAB4(:,:,ll + 3) * exp(1i * k * (-LA(:, ll + 3)));
            DBAs = DBAs + KBA1(:,:,ll) * exp(1i * k * (-FB(:, ll))) + KBA3(:,:,ll) * exp(1i * k * (-TB(:, ll))) + ...
                   KBA4(:,:,ll) * exp(1i * k * (-LB(:, ll))) + KBA4(:,:,ll + 3) * exp(1i * k * (-LB(:, ll + 3)));
        end
        D(1:3, 4:6) = -DABs;
        D(4:6, 1:3) = -DBAs;
        D(1:3, 1:3) = sum(KAB1,3) + sum(KAA,3) + sum(KAB3,3) + sum(KAB4f,3) + sum(KAB4s,3) - DAAs;
        D(4:6, 4:6) = sum(KAB1,3) + sum(KAA,3) + sum(KAB3,3) + sum(KAB4f,3) + sum(KAB4s,3) - DBBs;
        e = eig(D);
        w = sort(e);
        W(:,ii) = real(sqrt(w))/sqrt(m);
end

% 绘制声子色散关系
flatten_w = W(:);
% 绘制直方图

bin_width = 2.0200e+12;
bin_list1 = 5e10:5e10:1e14;
bin_list2 = 1.02e14:2e12:3.02e14;
bins = cat(2,bin_list1,bin_list2);
figure
%h = histogram(flatten_w,bins,'Normalization','pdf');
h = histogram(flatten_w,200,'Normalization','pdf');
% 设置坐标轴标签和标题
xlabel('Frequency');
ylabel('Density');
title('Density of states');



%计算热容
pdf = h.Values;
frequency = (h.BinEdges(1:end-1)+h.BinEdges(2:end))/2;
w_width = h.BinWidth;
%x=h_bar*w/(kB*T)
capacity_per_x = @(x) kB*(x.^2).*exp(x)./((exp(x)-1).^2);
%拟合实际热容极限温度
T_limit = 1e5;

x_limit = (h_bar/kB)*frequency' * (1./T_limit);
capacity_limit = capacity_per_x(x_limit);
capacity_limit = sum(capacity_limit)*w_width;
c_lim_true = 24.943;
capacity_limit = c_lim_true/capacity_limit;
%0-2000K温度范围
T_list1 = (0:50:2000)+0.001;
x_mat1 = (h_bar/kB)*frequency' * (1./T_list1);
capacity1 = capacity_per_x(x_mat1);
capacity1 = sum(capacity1)*w_width*capacity_limit;
figure
hold on
plot(T_list1,capacity1,'b',"LineStyle","-",'LineWidth',1);
scatter(T_list1,capacity1,10,'MarkerEdgeColor',[0 .2 .2],...
        'MarkerFaceColor',[0 .5 .5],...
        'LineWidth',1);
xlim([0,2001]);
xlabel("T(k)")
ylabel("Specific Heat(J mol^{-1} K^{-1})")
title("Specific heats of graphene")
hold off
%0-100K范围
figure
hold on
T_list2 = (0:10:100)+1e-10;
x_mat2 = (h_bar/kB)*frequency' * (1./T_list2);
capacity2 = capacity_per_x(x_mat2);
capacity2 = sum(capacity2)*w_width*capacity_limit;
plot(T_list2,capacity2,'b',"LineStyle","-",'LineWidth',1);
scatter(T_list2,capacity2,50,...
        'MarkerFaceColor',[1 0.5 0]);
xlim([0,100.1]);
xlabel("T(k)")
ylabel("Specific Heat(J mol^{-1} K^{-1})")
title("Specific heats of graphene")
hold off
% 定义旋转函数
function [R, RB] = rotate(theta, r)
    Um = [cos(theta), sin(theta), 0; -sin(theta), cos(theta), 0; 0, 0, 1];
    inv_Um = [cos(theta), -sin(theta), 0; sin(theta), cos(theta), 0; 0, 0, 1];
    U = [cos(pi), sin(pi), 0; -sin(pi), cos(pi), 0; 0, 0, 1];
    inv_U = [cos(pi), -sin(pi), 0; sin(pi), cos(pi), 0; 0, 0, 1];
    n = 2*pi/theta;
    if numel(r) == 3
        R = zeros(3,n);      
        RB = zeros(3,n);
    else
        R = zeros(3,3,n);      
        RB = zeros(3,3,n);
    end
    for i = 1:n
        if numel(r) == 3
            r = inv_Um * r;
            rb = r*(-1);
            R(:, i) = r;
            RB(:, i) = rb;
        else
            r = inv_Um * r * Um;
            rb = inv_U * r * U;
            R(:, :, i) = r;
            RB(:, :, i) = rb;
        end

    end
end

% 构建初始的Kij，中心原子与正右侧的原子间的K矩阵为对角矩阵，通过旋转，得到中心原子与每个近邻的第一个原子间的K矩阵
function k = K(theta, k)
    U = [cos(theta), sin(theta), 0; -sin(theta), cos(theta), 0; 0, 0, 1];
    inv_U = [cos(theta), -sin(theta), 0; sin(theta), cos(theta), 0; 0, 0, 1];
    k = inv_U * k * U;
end

