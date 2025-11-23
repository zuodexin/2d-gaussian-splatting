#!/bin/bash

# Quick test for ultra-small 3DGS model
echo "Training ultra-small 3DGS model (target < 300KB)..."

# 参数说明:
# -s: 输入数据集路径
# --model_path: 模型输出保存路径  
# --iterations: 总训练迭代次数 (默认30000，减少以控制模型大小)
# --eval: 启用评估模式，在测试集上计算指标
# -w: 使用白色背景
# --sh_degree: 球谐函数度数 (0=3个系数，3=64个系数)，最大影响模型大小
# --densify_grad_threshold: 密集化梯度阈值 (默认0.0002)，越高越难触发密集化
# --percent_dense: 场景范围百分比 (默认0.01)，控制高斯点最大尺寸
# --densify_until_iter: 密集化结束迭代数 (默认15000)，提前停止控制点数量
# --opacity_reset_interval: 透明度重置间隔 (默认3000)，更频繁修剪无用点
# --densification_interval: 密集化检查间隔 (默认100)，降低密集化频率

python train.py \
    -s data/gso/nerf \
    --model_path output/gso_tiny \
    --iterations 3000 \
    --eval \
    -w \
    --sh_degree 0 \
    --densify_grad_threshold 0.0004 \
    --percent_dense 0.01 \
    --densify_until_iter 2000 \
    --opacity_reset_interval 500 \
    --densification_interval 300

echo "Training completed! Checking model size..."
ls -lh output/gso_tiny/point_cloud/iteration_*/point_cloud.ply

echo "Number of Gaussians:"
head -10 output/gso_tiny/point_cloud/iteration_*/point_cloud.ply | grep "element vertex"

python render.py -m output/gso_tiny -w --skip_mesh

python view.py -s data/gso/nerf -m output/gso_tiny --iteration 3000 --sh_degree 0
