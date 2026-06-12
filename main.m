clear; close all; clc;

%% 1. 实验配置 (文件夹与参数)
config = struct();

% --- 文件夹路径配置 (请在此处修改) ---
config.input_dir = 'E:\Academic\paper3\HMRT\target1\';  % 输入原始图像文件夹
config.output_dir = 'E:\Academic\paper3\HMRT\target1\result'; % 输出主文件夹
config.file_ext = '*.bmp';   % 图片格式

% 自动创建并设置目标和背景输出子文件夹
dir_tar = fullfile(config.output_dir, 'Target');
dir_bg = fullfile(config.output_dir, 'Background');
if ~exist(dir_tar, 'dir'), mkdir(dir_tar); end
if ~exist(dir_bg, 'dir'), mkdir(dir_bg); end

% 获取图片文件名
dirOutput = dir(fullfile(config.input_dir, config.file_ext));
if isempty(dirOutput), error('输入文件夹为空！'); end
fileNames = {dirOutput.name};

% --- 算法参数 (科研调参核心) ---
% 【全新核心参数】: 时间窗口大小 (每多少帧构建一次流形)
config.window_size = 8;   % 可根据视频动态变化剧烈程度调节 (如 10, 20, 30)

config.beta = 200;          
mt = 133;
nt = 109;

config.lambda_scale = 0.2; 
config.k_neighbor = 50;      
config.max_iter = 100;        

%% 2. 加载数据
fprintf('📂 [Step 1] 加载原始数据...\n');
[D_obs, file_names] = load_image_sequence(config.input_dir, config.file_ext);
[H, W, total_F] = size(D_obs);

D_obs = double(D_obs);
min_val = min(D_obs(:));
max_val = max(D_obs(:));
D_obs = (D_obs - min_val) / (max_val - min_val);

%% 3 & 4. 调用核心算法 (局部时间分块处理)
fprintf('🚀 [Step 2 & 3] 执行局部时间块分解 (Window Size = %d)...\n', config.window_size);
tic

% =========================================================================
% 调用 HMRT 核心求解器
% 注: 该函数在开源包中作为加密的 .p 文件提供以保护核心数学实现
% =========================================================================
[L_hat_total, S_hat_total] = HMRT_solver(D_obs, config);

time_cost = toc;
fprintf('⏱️ 分解完成！总耗时: %.2f 秒\n', time_cost);

%% 5. 结果保存与指标计算
fprintf('💾 [Step 4] 计算指标并保存结果...\n');

for i = 1:total_F
    [~, baseName, ext] = fileparts(file_names(i).name);
    
    target_data = S_hat_total(:,:,i);
    Back = L_hat_total(:,:,i);
    
    target_data(target_data < 1e-5) = 0; 
    E = mat2gray(target_data);
    A = mat2gray(Back);

    % 仅在第1帧时计算并打印指标 (根据你的需求调整)
    if i == 1
        img = D_obs(:,:,i);
        
        % ==========================================
        % 🔍 量级自适应检测与统一 (转换至 0-255)
        % ==========================================
        % 判断 img 的量级并转换
        if max(img(:)) <= 1.05 % 留出微小的浮点误差余量
            img_eval = img * 255.0;
        else
            img_eval = img;
        end
        
        % 判断 E 的量级并转换
        if max(E(:)) <= 1.05
            E_eval = E * 255.0;
        else
            E_eval = E;
        end
        % ==========================================
        
        figure(1);
        imshow(E_eval, []); % 显示时自动适应量级
        title(sprintf('Frame %d - Detected Target', i));
        
        try
            % 统一使用转换后的 img_eval 和 E_eval 计算指标
            % 注意：请确保你的当前路径下有 jisuan_snr, BSF, SSIM 这三个评价函数的.m文件
            [avg_data, snr, snr2] = jisuan_snr(E_eval, mt, nt);
            bsf = BSF(E_eval, img_eval);
            
            % 计算 SSIM 所需的背景差异图
            B_metric = img_eval - E_eval; 
            ssim_val = SSIM(img_eval, B_metric);
            
            fprintf('📌 第 %d 帧去噪指标：SNR=%.2f dB，SSIM=%.4f，BSF=%.4f\n', i, snr, ssim_val, bsf);
        catch ME
            % 打印具体的报错信息，方便排查是哪个函数缺了或者算崩了
            fprintf('⚠️ 指标计算出错: %s\n', ME.message);
        end
    end
    
    saveName_E = fullfile(dir_tar, [baseName, '_target', ext]);
    saveName_A = fullfile(dir_bg, [baseName, '_bg', ext]);
    % imwrite(E, saveName_E);
    % imwrite(A, saveName_A);
end

fprintf('✅ 所有结果已成功保存在: %s\n', config.output_dir);

%% ================== 数据读取辅助函数 ==================
function [Tensor, files] = load_image_sequence(folder_path, ext)
    files = dir(fullfile(folder_path, ext));
    if isempty(files), error('无文件'); end
    img1 = imread(fullfile(folder_path, files(1).name));
    if size(img1, 3) > 1, img1 = rgb2gray(img1); end
    [H, W] = size(img1);
    Tensor = zeros(H, W, length(files));
    for i = 1:length(files)
        img = imread(fullfile(folder_path, files(i).name));
        if size(img, 3) > 1, img = rgb2gray(img); end
        Tensor(:,:,i) = im2double(img);
    end
end