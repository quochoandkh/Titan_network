wget -O Titan.sh https://raw.githubusercontent.com/a3165458/Titan-Network/main/Titan.sh && chmod +x Titan.sh && ./Titan.sh

wget -O duokai.sh https://raw.githubusercontent.com/a3165458/Titan-Network/main/duokai.sh && chmod +x duokai.sh && ./duokai.sh

wget -O duokaixianzhiban.sh https://raw.githubusercontent.com/a3165458/Titan-Network/main/duokaixianzhiban.sh && chmod +x duokaixianzhiban.sh && ./duokaixianzhiban.sh

Chi tiết cài:

Cần mount ổ đĩa lưu trữ trước khi cài đặt 
đối với wsl2: (ví dụ mount ổ D)
mkdir -p ~/mnt_d
sudo mount --bind /mnt/d ~/mnt_d

git clone https://github.com/quochoandkh/Titan_network.git
cd Titan_network
sudo chmod +x duokai_vi.sh
sudo bash duokai_vi.sh
(chọn đường dẫn tuyệt đối ) là /home/username/mnt_d/Titan_node
