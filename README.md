wget -O Titan.sh https://raw.githubusercontent.com/a3165458/Titan-Network/main/Titan.sh && chmod +x Titan.sh && ./Titan.sh

wget -O duokai.sh https://raw.githubusercontent.com/a3165458/Titan-Network/main/duokai.sh && chmod +x duokai.sh && ./duokai.sh

wget -O duokaixianzhiban.sh https://raw.githubusercontent.com/a3165458/Titan-Network/main/duokaixianzhiban.sh && chmod +x duokaixianzhiban.sh && ./duokaixianzhiban.sh

Chi tiết cài:

sudo -i
cd /
mkdir -p /root/mnt/g
sudo mount -t drvfs G: /root/mnt/g
ls /root/mnt/g
sudo nano ~/.bashrc
thêm dòng này vào cuối file
sudo mount -t drvfs G: /root/mnt/g
save lại
source ~/.bashrc

cd ~/mnt/g
git clone https://github.com/quochoandkh/Titan_network.git
cd Titan_network
sudo chmod +x titan.sh
sudo bash titan.sh
đến đoạn chọn đường dẫn nhập (ví dụ đang mount vào ổ G):
/root/mnt/g/
