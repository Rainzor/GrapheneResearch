% 定义常量
a = 1.42e-10;    % 晶格常数
m = 1.99e-26;    % 碳原子质量
pi = 3.141592653589793;
kpoints = 100;

% 生成力常数的对角矩阵
f = diag([36.50, 24.50, 9.82, 8.80, -3.23, -0.40, 3.00, -5.25, 0.15, -1.92, 2.29, -0.58])*10;



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



% 求解矩阵
n = 100; % 沿第一布里渊区的最小重复单元的边界每条边单位长度取100个k点进行计算（主要是为了使点均匀分布，同样可以每条边取n个点进行计算）
k_list = zeros((30 + round(sqrt(3) * 10)) * n, 3); % k点的矩阵
for jj = 1:((30 + round(sqrt(3) * 10)) * n)
    if jj < n * round(10 * sqrt(3)) % 判断i的大小确定k的取值
        kx = (jj-1) * 2 * pi / 3 / a / (n * round(10 * sqrt(3)));
        ky = 0;
    elseif jj < (10 + round(10 * sqrt(3))) * n
        kx = 2 * pi / 3 / a;
        ky = (jj - n * round(10 * sqrt(3))) / (10 * n - 1) * 2 * pi / 3 / a / sqrt(3);
    else
        kx = 2 * pi / 3 / a - (jj - (10 + round(10 * sqrt(3))) * n) / (n * 20 - 1) * 2 * pi / 3 / a;
        ky = kx / sqrt(3);
    end
    k = [kx, ky, 0]; % 得到k值，带入D矩阵
    k_list(jj, :) = k;
end

% 求解本征值
k_num = size(k_list,1);
w_list = zeros(6,k_num);
for l = 1:k_num
    k = k_list(l,:);
    % 计算动力学矩阵
    D = zeros(6, 6);
    DAAs = zeros(3,3);
    DBBs = zeros(3,3);
    DBAs = zeros(3,3);
    DABs = zeros(3,3);
    % 以上四个矩阵由文献的 9.7 式可知，并组合成一个完整的D矩阵
    for jj = 1:3
        DAAs = DAAs + KAA(:,:,jj) * exp(1i * k * (-SA(:, jj))) + KAA(:,:,jj+3) * exp(1i * k * (-SA(:, jj+3)));
        DBBs = DBBs + KBB(:,:,jj) * exp(1i * k * (-SB(:, jj))) + KBB(:,:,jj+3) * exp(1i * k * (-SB(:, jj+3)));
        DABs = DABs + KAB1(:,:,jj) * exp(1i * k * (-FA(:, jj))) + KAB3(:,:,jj) * exp(1i * k * (-TA(:, jj))) +...
               KAB4(:,:,jj) * exp(1i * k * (-LA(:, jj))) + KAB4(:,:,jj + 3) * exp(1i * k * (-LA(:, jj + 3)));
        DBAs = DBAs + KBA1(:,:,jj) * exp(1i * k * (-FB(:, jj))) + KBA3(:,:,jj) * exp(1i * k * (-TB(:, jj))) + ...
               KBA4(:,:,jj) * exp(1i * k * (-LB(:, jj))) + KBA4(:,:,jj + 3) * exp(1i * k * (-LB(:, jj + 3)));
    end
    D(1:3, 4:6) = -DABs;
    D(4:6, 1:3) = -DBAs;
    D(1:3, 1:3) = sum(KAB1,3) + sum(KAA,3) + sum(KAB3,3) + sum(KAB4f,3) + sum(KAB4s,3) - DAAs;
    D(4:6, 4:6) = sum(KAB1,3) + sum(KAA,3) + sum(KAB3,3) + sum(KAB4f,3) + sum(KAB4s,3) - DBBs;
    e = eig(D);
    w = sort(e);
    w_list(:,l) = real(sqrt(w))/sqrt(m);
end


idx0 = (1:6)';
idx = (1:6)';
w_list_b = w_list;
slope = zeros(6,2);
for i = 1:k_num
    if i>1 && i<k_num-1
        for j = 1:5
            if abs(w_list_b(idx0(j),i-1)-(w_list_b(idx0(j+1),i-1))) < 5e11
                if abs(slope(j,1)-slope(j,2))-abs(slope(j,1)-slope(j+1,2))>0
                    if(j==4 || j==1)
                        continue;
                    end
                    pos_1 = find(idx==j);
                    pos_2 = find(idx==(j+1));
                    tmp = idx(pos_1);
                    idx(pos_1) = idx(pos_2);
                    idx(pos_2) = tmp;
                end
            end
        end
    end
    if i>1
        slope(:,1) = w_list_b(idx0,i)-w_list_b(idx0,i-1);
    end

    if(i<k_num-1)
        slope(:,2) = w_list_b(idx0,i+1)-w_list_b(idx0,i);
    end
    w_list(idx0,i) = w_list_b(idx,i);
end



% 绘制声子色散关系
figure;
s = sqrt(3);
xk = [0, s, s + 1, s + 3];
kk = linspace(0, 4.7, k_num); % 作为x轴，使其和本征值矩阵每一列的y的值个数相同
% 绘制图形
colors = {'b','r','g','c','m',[1,0.5,0]};
labels = {'ZA','TA','LA','ZO','LO','TO'};
hold on
for i = 1:6
    plot(kk,w_list(i,:),"Color",colors{i},'DisplayName',labels{i},'LineWidth',1.5);
end
xticks(xk);
xticklabels({'Γ', 'M', 'K', 'Γ'});
xlim([0, 4.75]);
ylim([0, 3.1e14]);
ylabel('ω', 'FontSize', 14);
legend('-DynamicLegend');
ax = gca;

% 仅绘制 x 轴网格线
ax.XGrid = 'on';
ax.YGrid = 'off';
title('Graphene Phonon Dispersion Relation');




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

