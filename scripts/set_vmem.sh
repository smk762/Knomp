sudo fallocate -l 4G /swapfile1
sudo chmod 600 /swapfile1
sudo mkswap /swapfile1
sudo swapon /swapfile1
echo '/swapfile1 none swap sw 0 0' | sudo tee -a /etc/fstab