#!/bin/bash

# Kiểm tra xem có chạy script với quyền root hay không
if [ "$(id -u)" != "0" ]; then
    echo "Script này cần được chạy với quyền root."
    echo "Hãy thử sử dụng lệnh 'sudo -i' để chuyển sang tài khoản root, sau đó chạy lại script này."
    exit 1
fi

function install_node() {

# Đọc và nhập mã định danh của người dùng
read -p "Nhập mã định danh của bạn: " id

# Cho phép người dùng nhập số lượng container muốn tạo
read -p "Nhập số lượng node bạn muốn tạo (một IP giới hạn tối đa 5 node): " container_count

# Nhập cổng RPC bắt đầu
read -p "Nhập cổng RPC bắt đầu (các cổng sẽ tự động tăng dần, đề nghị sử dụng 30000): " start_rpc_port

# Nhập dung lượng lưu trữ cho mỗi node
read -p "Nhập dung lượng lưu trữ cho mỗi node (GB), giới hạn tối đa 2TB/node: " storage_gb

# Nhập đường dẫn lưu trữ (tùy chọn)
read -p "Nhập đường dẫn lưu trữ dữ liệu cho node trên máy chủ (bỏ qua để sử dụng đường dẫn mặc định titan_storage_$i): " custom_storage_path

apt update

# Kiểm tra Docker đã được cài đặt chưa
if ! command -v docker &> /dev/null
then
    echo "Docker chưa được cài đặt, đang tiến hành cài đặt..."
    apt-get install ca-certificates curl gnupg lsb-release -y

    # Cài đặt phiên bản Docker mới nhất
    apt-get install docker.io -y
else
    echo "Docker đã được cài đặt."
fi

# Tải hình ảnh Docker
docker pull nezha123/titan-edge:1.7

# Tạo số lượng container theo yêu cầu của người dùng
for ((i=1; i<=container_count; i++))
do
    current_rpc_port=$((start_rpc_port + i - 1))

    # Xác định đường dẫn lưu trữ (nếu không nhập, sử dụng mặc định)
    if [ -z "$custom_storage_path" ]; then
        # Sử dụng đường dẫn mặc định
        storage_path="$PWD/titan_storage_$i"
    else
        # Sử dụng đường dẫn do người dùng nhập
        storage_path="$custom_storage_path"
    fi

    # Tạo thư mục lưu trữ
    mkdir -p "$storage_path"

    # Khởi chạy container và thiết lập chính sách khởi động lại luôn
    container_id=$(docker run -d --restart always -v "$storage_path:/root/.titanedge/storage" --name "titan$i" --net=host  nezha123/titan-edge:1.7)

    echo "Node titan$i đã được khởi động với Container ID: $container_id"

    sleep 30

    # Chỉnh sửa tệp cấu hình để cài đặt dung lượng lưu trữ và cổng RPC
    docker exec $container_id bash -c "\
        sed -i 's/^[[:space:]]*#StorageGB = .*/StorageGB = $storage_gb/' /root/.titanedge/config.toml && \
        sed -i 's/^[[:space:]]*#ListenAddress = \"0.0.0.0:1234\"/ListenAddress = \"0.0.0.0:$current_rpc_port\"/' /root/.titanedge/config.toml && \
        echo 'Node titan'$i' đã được cấu hình với dung lượng lưu trữ $storage_gb GB, cổng RPC là $current_rpc_port'"

    # Khởi động lại container để áp dụng cài đặt
    docker restart $container_id

    # Liên kết container với mã định danh
    docker exec $container_id bash -c "\
        titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
    echo "Node titan$i đã được liên kết."

done

echo "============================== Tất cả các node đã được cài đặt và khởi chạy thành công ==================================="

}

# Chức năng gỡ cài đặt các node
function uninstall_node() {
    echo "Bạn có chắc chắn muốn gỡ bỏ chương trình Titan Node? Tất cả dữ liệu liên quan sẽ bị xóa. [Y/N]"
    read -r -p "Vui lòng xác nhận: " response

    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Bắt đầu gỡ cài đặt các node..."
            for i in {1..5}; do
                sudo docker stop "titan$i" && sudo docker rm "titan$i"
            done
            for i in {1..5}; do 
                rmName="storage_titan_$i"
                rm -rf "$rmName"
            done
            echo "Quá trình gỡ cài đặt hoàn tất."
            ;;
        *)
            echo "Hủy bỏ thao tác gỡ cài đặt."
            ;;
    esac
}

# Menu chính
function main_menu() {
    while true; do
        clear
        echo "Script và hướng dẫn được viết bởi người dùng Twitter 大赌哥 @y95277777. Miễn phí mã nguồn mở, không tin vào các yêu cầu phí."
        echo "================================================================"
        echo "Cộng đồng Telegram Node: https://t.me/niuwuriji"
        echo "Kênh Telegram Node: https://t.me/niuwuriji"
        echo "Cộng đồng Discord Node: https://discord.gg/GbMV5EcNWF"
        echo "Để thoát script, nhấn Ctrl+C."
        echo "Vui lòng chọn hành động:"
        echo "1. Cài đặt Node"
        echo "2. Gỡ bỏ Node"
        read -p "Nhập tùy chọn (1-2): " OPTION

        case $OPTION in
        1) install_node ;;
        2) uninstall_node ;;
        *) echo "Tùy chọn không hợp lệ." ;;
        esac
        echo "Nhấn phím bất kỳ để quay lại menu chính..."
        read -n 1
    done
}

# Hiển thị menu chính
main_menu
