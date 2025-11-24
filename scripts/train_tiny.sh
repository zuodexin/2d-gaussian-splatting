#!/bin/bash

# Quick test for ultra-small 2DGS model
echo "Training ultra-small 2DGS model (target < 300KB)..."

# 解析命令行参数
INPUT_DATA=""
OUTPUT_PATH=""
ITERATIONS=3000
HELP=false

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -i, --input <path>     输入数据集路径 (必需)"
    echo "  -o, --output <path>    输出模型路径 (必需)"
    echo "  --iterations <num>     训练迭代次数 (默认: 3000)"
    echo "  -h, --help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -i data/gso/nerf -o output/my_model"
    echo "  $0 --input data/custom --output models/tiny_gs --iterations 5000"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT_DATA="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        --iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "错误: 未知参数 $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证必需参数
if [[ -z "$INPUT_DATA" ]]; then
    echo "错误: 必须指定输入数据路径 (-i 或 --input)"
    show_help
    exit 1
fi

if [[ -z "$OUTPUT_PATH" ]]; then
    echo "错误: 必须指定输出路径 (-o 或 --output)"
    show_help
    exit 1
fi

# 验证输入路径是否存在
if [[ ! -d "$INPUT_DATA" ]]; then
    echo "错误: 输入数据路径不存在: $INPUT_DATA"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_PATH"

# 自动检测图像格式
IMAGE_EXT=".png"
if [[ -d "$INPUT_DATA/train" ]]; then
    # 检查train目录中的图像文件
    if ls "$INPUT_DATA/train"/*.webp 1> /dev/null 2>&1; then
        IMAGE_EXT=".webp"
    elif ls "$INPUT_DATA/train"/*.jpg 1> /dev/null 2>&1; then
        IMAGE_EXT=".jpg"
    elif ls "$INPUT_DATA/train"/*.jpeg 1> /dev/null 2>&1; then
        IMAGE_EXT=".jpeg"
    fi
fi

echo "配置信息:"
echo "  输入数据: $INPUT_DATA"
echo "  输出路径: $OUTPUT_PATH"
echo "  迭代次数: $ITERATIONS"
echo "  图像格式: $IMAGE_EXT"
echo ""

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
    -s "$INPUT_DATA" \
    --model_path "$OUTPUT_PATH" \
    --iterations "$ITERATIONS" \
    --image_extension "$IMAGE_EXT" \
    --eval \
    -w \
    --sh_degree 0 \
    --densify_grad_threshold 0.0004 \
    --percent_dense 0.01 \
    --densify_until_iter $((ITERATIONS * 2 / 3)) \
    --opacity_reset_interval $((ITERATIONS / 6)) \
    --densification_interval 300

echo "Training completed! Checking model size..."
ls -lh "$OUTPUT_PATH"/point_cloud/iteration_*/point_cloud.ply

echo "Number of Gaussians:"
head -10 "$OUTPUT_PATH"/point_cloud/iteration_*/point_cloud.ply | grep "element vertex"

echo "Rendering test images..."
python render.py -m "$OUTPUT_PATH" -w --skip_mesh
