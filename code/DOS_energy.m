% 定义常数和函数
a0 = 1.42e-10; % 定义a的值
a = 2.46e-10;
b1 = 2*pi / (3*a0);
b2 = 2*pi / (sqrt(3)*a0);
gamma0 = 3.033;
s0 = 0.129;
f = @(kx, ky) sqrt(1 + 4*cos((sqrt(3)*a/2)*kx).*cos(a/2*ky) + 4*cos(a/2*ky).^2);
e = @(kx, ky) (gamma0*f(kx, ky));

% 创建矩形网格
kpoints = 200;
[x, y] = meshgrid(linspace(-b1,b1,kpoints), linspace(-b2,b2,kpoints));

% 找到位于菱形内部的点
in_diamond = (abs(x/b1) + abs(y/b2)) <= 1;

% 获取位于菱形内部的点的坐标
kx = x(in_diamond);
ky = y(in_diamond);
% 计算e1和e2的值
e1_values = e(kx, ky);
e2_values = -e(kx, ky);

flatten_e = [e1_values(:);e2_values(:)];
figure
h = histogram(flatten_e,200,'Normalization','pdf');
% 设置坐标轴标签和标题
xlabel('Energy(eV)');
ylabel('Density');
title('Density of states');


