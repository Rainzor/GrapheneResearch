% 定义常量
a = 1.42e-10;    % 晶格常数
m = 1.99e-26;    % 碳原子质量
pi = 3.141592653589793;
kpoints = 200;

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

kx_path =  linspace(-2*pi/(a*3),2*pi/(a*3),kpoints);
ky_path = linspace(-2*pi/(a*3),2*pi/(a*3),kpoints);
[X,Y] = meshgrid(kx_path,ky_path);

k_list = zeros(3,kpoints,kpoints);

for ii = 1:kpoints
    for ll = 1:kpoints
        k_list(:,ii,ll)  = [X(ii,ll), Y(ii,ll), 0];
    end
end

% 求解本征值
k_num = kpoints*kpoints;
W = zeros(6,kpoints,kpoints);
for ii = 1:kpoints
    for jj = 1:kpoints
        k = k_list(:,ii,jj)';
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
        W(:,ii,jj) = real(sqrt(w))/sqrt(m);
    end
end

% 绘制声子色散关系
figure
colormap('jet')
for i=1:6
   surf(X,Y,reshape(W(i,:,:),kpoints,kpoints),'EdgeAlpha',0.1);
   hold on
end
colorbar
hold off
zlabel('\omega', 'FontSize', 14);
xlabel("k_x",'FontSize', 14);
ylabel("k_y",'FontSize', 14);
title('Graphene Phonon Dispersion Relation');

% 创建新的图像
figure
% 找到最接近y=0的索引
[~, y0_index] = min(abs(Y(:, 1)));
w_list = zeros(6,kpoints);
% 遍历所有曲面
for i = 1:6
    % 绘制曲面在y=0处的X-W投影
    xw_projection_x = X(i,:);
    xw_projection_w = reshape(W(i, :, y0_index), kpoints, 1);
    w_list(i,:) =  reshape(W(i, :, y0_index), kpoints, 1);
    plot(xw_projection_x,xw_projection_w,'b','LineWidth',1.5)
    %scatter(xw_projection_x, xw_projection_w,0.3,"blue","filled");
    hold on
end

% 设置图像属性

idx = xw_projection_x>0&xw_projection_x<0.75e10;
vp = 0;
v_list =1:3;
vg = 0;
for i=1:3
    x = xw_projection_x(idx);
    y = w_list(i,idx);

    if(i==1)
       p = polyfit(x, y, 2);
    else
       p = polyfit(x, y, 1);
       vp = vp + 1/p(1)^2;
    end  
    v_list(i) = p(1);
    vg = vg+p(1)^2;
    % 计算拟合曲线的y值
    y_fit = polyval(p, xw_projection_x(xw_projection_x>0));
    plot(xw_projection_x(xw_projection_x>0), y_fit,'r','LineStyle',  '--', 'DisplayName', 'Linear fit','LineWidth',3);
    hold on
end
vp = sqrt(2/vp);
xlabel("k_x", 'FontSize', 14);
ylabel("\omega", 'FontSize', 14);
ylim([0,3.1e14])
title('X-W Projection of Graphene Phonon Dispersion Relation at \Gamma-M direction');
hold off
grid on;





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

