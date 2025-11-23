python train.py -s data/gso/nerf --model_path output/gso --iterations 1000 --eval -w --densify_grad_threshold 0.002
python render.py -m output/gso -w