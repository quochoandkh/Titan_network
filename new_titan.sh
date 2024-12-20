#!/bin/bash

# Kiểm tra xem script có được chạy với quyền root không
if [ "$(id -u)" != "0" ]; then
    echo "Script này cần được chạy với quyền root."
    echo "Hãy thử sử dụng lệnh 'sudo -i' để chuyển sang người dùng root, sau đó chạy lại script này."
    exit 1
fi

# Kiểm tra và cài đặt Node.js và npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js đã được cài đặt."
    else
        echo "Node.js chưa được cài đặt, đang tiến hành cài đặt..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm đã được cài đặt."
    else
        echo "npm chưa được cài đặt, đang tiến hành cài đặt..."
        sudo apt-get install -y npm
    fi
}

# Kiểm tra và cài đặt PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 đã được cài đặt."
    else
        echo "PM2 chưa được cài đặt, đang tiến hành cài đặt..."
        npm install pm2@latest -g
    fi
}

# Tự động thiết lập phím tắt
function check_and_set_alias() {
    local alias_name="art"
    local shell_rc="$HOME/.bashrc"

    # Đối với người dùng Zsh, sử dụng .zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # Kiểm tra xem phím tắt đã được thiết lập chưa
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "Thiết lập phím tắt '$alias_name' trong $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        echo "Phím tắt '$alias_name' đã được thiết lập. Hãy chạy 'source $shell_rc' để kích hoạt hoặc mở lại terminal."
    else
        echo "Phím tắt '$alias_name' đã được thiết lập trong $shell_rc."
        echo "Nếu phím tắt không hoạt động, hãy thử chạy 'source $shell_rc' hoặc mở lại terminal."
    fi
}

# Chức năng cài đặt node
function install_node() {
    install_nodejs_and_npm
    install_pm2

    # Cập nhật và cài đặt các phần mềm cần thiết
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

    # Cài đặt Go
        sudo rm -rf /usr/local/go
        curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
        source $HOME/.bash_profile
        go version

    # Cài đặt các tệp nhị phân
    cd $HOME
    git clone https://github.com/Titannet-dao/titan-chain.git
    cd titan-chain
    go build ./cmd/titand
    cp titand /usr/local/bin

    # Cấu hình titand
    export MONIKER="My_Node"
    titand init $MONIKER --chain-id titan-test-4
    titand config node tcp://localhost:53457

    # Lấy tệp khởi tạo và sổ địa chỉ
    wget https://raw.githubusercontent.com/Titannet-dao/titan-chain/main/genesis/genesis.json
    mv genesis.json ~/.titan/config/genesis.json

    # Cấu hình nút
    SEEDS="bb075c8cc4b7032d506008b68d4192298a09aeea@47.76.107.159:26656"
    PEERS=""
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.titan/config/config.toml

    wget https://raw.githubusercontent.com/Titannet-dao/titan-chain/main/addrbook/addrbook.json
    mv addrbook.json ~/.titan/config/addrbook.json

    # Cấu hình cắt tỉa
    sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.titan/config/app.toml
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.titan/config/app.toml
    sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"0\"/" $HOME/.titan/config/app.toml
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.titan/config/app.toml
    sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025uttnt\"/;" ~/.titan/config/app.toml

    # Cấu hình cổng
    node_address="tcp://localhost:53457"
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:53458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:53457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:53460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:53456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":53466\"%" $HOME/.titan/config/config.toml
    sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:53417\"%; s%^address = \":8080\"%address = \":53480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:53490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:53491\"%; s%:8545%:53445%; s%:8546%:53446%; s%:6065%:53465%" $HOME/.titan/config/app.toml
    echo "export TITAN_RPC_PORT=$node_address" >> $HOME/.bash_profile
    source $HOME/.bash_profile

    pm2 start titand -- start && pm2 save && pm2 startup

    pm2 restart titand

    echo '====================== Cài đặt hoàn tất, vui lòng chạy source $HOME/.bash_profile để tải lại biến môi trường ==========================='
}

# Kiểm tra trạng thái dịch vụ titan
function check_service_status() {
    pm2 list
}

# Xem nhật ký nút titan
function view_logs() {
    pm2 logs titand
}

# Gỡ cài đặt nút
function uninstall_node() {
    echo "Bạn có chắc chắn muốn gỡ bỏ chương trình nút titan không? Điều này sẽ xoá toàn bộ dữ liệu liên quan. [Y/N]"
    read -r -p "Xác nhận: " response

    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Đang gỡ cài đặt chương trình nút..."
            pm2 stop titand && pm2 delete titand
            rm -rf $HOME/.titand $HOME/titan $(which titand)
            echo "Chương trình nút đã được gỡ bỏ."
            ;;
        *)
            echo "Đã huỷ bỏ thao tác gỡ cài đặt."
            ;;
    esac
}

# Tạo ví
function add_wallet() {
    titand keys add wallet
}

# Nhập ví
function import_wallet() {
    titand keys add wallet --recover
}

# Kiểm tra số dư
function check_balances() {
    read -p "Vui lòng nhập địa chỉ ví: " wallet_address
    titand query bank balances "$wallet_address"
}

# Xem trạng thái đồng bộ nút
function check_sync_status() {
    titand status | jq .SyncInfo
}

# Tạo trình xác thực
function add_validator() {
    read -p "Nhập tên ví của bạn: " wallet_name
    read -p "Nhập tên của trình xác thực bạn muốn tạo: " validator_name

titand tx staking create-validator \
--amount="1000000uttnt" \
--pubkey=$(titand tendermint show-validator) \
--moniker="$validator_name" \
--commission-max-change-rate=0.01 \
--commission-max-rate=1.0 \
--commission-rate=0.07 \
--min-self-delegation=1 \
--fees 500uttnt \
--from="$wallet_name" \
--chain-id=titan-test-1
}

# Uỷ quyền tự mình làm trình xác thực
function delegate_self_validator() {
read -p "Nhập số lượng token để uỷ quyền (đơn vị là uttnt, 1ttnt=1000000uttnt): " math
read -p "Nhập tên ví: " wallet_name
titand tx staking delegate $(titand keys show $wallet_name --bech val -a)  ${math}uttnt --from $wallet_name --fees 500uttnt
}

# Xuất khoá xác thực cá nhân
function export_priv_validator_key() {
    echo "====================Vui lòng sao lưu toàn bộ nội dung bên dưới vào notepad hoặc excel để lưu trữ===================="
    cat ~/.titan/config/priv_validator_key.json
}

function update_script() {
    SCRIPT_URL="https://raw.githubusercontent.com/a3165458/titan/main/titan.sh"
    curl -o $SCRIPT_PATH $SCRIPT_URL
    chmod +x $SCRIPT_PATH
    echo "Script đã được cập nhật. Vui lòng thoát và chạy lại script này."
}

# Menu chính
function main_menu() {
    while true; do
        clear
        echo "Script và hướng dẫn được viết bởi người dùng Twitter @y95277777, hoàn toàn miễn phí, không nên tin các dịch vụ thu phí."
        echo "============================Cài đặt nút titan===================================="
        echo "Cộng đồng Telegram: https://t.me/niuwuriji"
        echo "Kênh Telegram: https://t.me/niuwuriji"
        echo "Discord: https://discord.gg/GbMV5EcNWF"
        echo "Thoát script bằng tổ hợp phím Ctrl+C."
        echo "Chọn thao tác cần thực hiện:"
        echo "1. Cài đặt nút"
        echo "2. Tạo ví"
        echo "3. Nhập ví"
        echo "4. Kiểm tra số dư ví"
        echo "5. Kiểm tra trạng thái đồng bộ nút"
        echo "6. Kiểm tra trạng thái dịch vụ"
        echo "7. Xem nhật ký chạy"
        echo "8. Gỡ bỏ nút"
        echo "9. Thiết lập phím tắt"  
        echo "10. Tạo trình xác thực"  
        echo "11. Tự mình uỷ quyền" 
        echo "12. Sao lưu khoá xác thực cá nhân" 
        echo "13. Cập nhật script" 
        read -p "Nhập tuỳ chọn (1-13): " OPTION

        case $OPTION in
        1) install_node ;;
        2) add_wallet ;;
        3) import_wallet ;;
        4) check_balances ;;
        5) check_sync_status ;;
        6) check_service_status ;;
        7) view_logs ;;
        8) uninstall_node ;;
        9) check_and_set_alias ;;
        10) add_validator ;;
        11) delegate_self_validator ;;
        12) export_priv_validator_key ;;
        13) update_script ;;
        *) echo "Tuỳ chọn không hợp lệ." ;;
        esac
        echo "Nhấn phím bất kỳ để quay lại menu chính..."
        read -n 1
    done
}

# Hiển thị menu chính
main_menu
