% 定义常数和函数
a0 = 1.42e-10; % 定义a的值
a = 2.46e-10;
gamma0 = 3.033;
s0 = 0.129;
f = @(kx, ky) sqrt(1 + 4*cos((sqrt(3)*a/2)*kx).*cos(a/2*ky) + 4*cos(a/2*ky).^2);
e1 = @(kx, ky) (gamma0*f(kx, ky))./(1 - s0*f(kx, ky));
e2 = @(kx, ky) (-gamma0*f(kx, ky))./(1 + s0*f(kx, ky));

% 定义kx和ky的范围
k_min = -1.5*pi/a;
k_max = 1.5*pi/a;
num_points = 1000;
kx_path =  linspace(-2*pi/(a*sqrt(3)),2*pi/(a*sqrt(3)),num_points);
ky_path = linspace(-2*pi/(a*3),2*pi/(a*3),num_points);
t = linspace(-1,1,num_points);
% 创建kx和ky的网格
[kx, ky] = meshgrid(linspace(k_min, k_max, num_points));

% 计算e1和e2的值
e1_values = e1(kx, ky);
e2_values = e2(kx, ky);

% 绘制e1和e2的图像
figure;
surf(kx, ky, e1_values);

hold on
surf(kx, ky, e2_values);
xlabel('kx');
ylabel('ky');
zlabel('Energy(eV)');
title(' Band structure of graphene ');
shading interp;


% 计算路径上的e1和e2值
e1_path = e1(kx_path, ky_path);
e2_path = e2(kx_path, ky_path);
hold off
figure;
plot(t, e1_path, 'b', 'LineWidth', 2);
hold on;
plot(t, e2_path, 'r', 'LineWidth', 2);
% 设置横坐标刻度和标签
xticks([-1, 0, 1]);
xticklabels({'K', '\Gamma', 'K'});
xlabel('t');
ylabel('Energy(ev)');
legend('\pi^*', '\pi');

title('Energy bands along [sqrt(3)/2, 1/2] direction');
grid on;

% 计算顶点坐标
b1 = 2*pi / (3*a0);
b2 = 2*pi / (sqrt(3)*a0);

% 创建矩形网格
kpoints = 200;
[x, y] = meshgrid(linspace(-b1,b1,kpoints), linspace(-b2,b2,kpoints));

% 找到位于菱形内部的点
in_diamond = (abs(x/b1) + abs(y/b2)) <= 1;

% 获取位于菱形内部的点的坐标
x_diamond = x(in_diamond);
y_diamond = y(in_diamond);
