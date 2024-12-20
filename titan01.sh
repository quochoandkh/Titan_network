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

# Nhập cổng RPC bắt đầu
read -p "Nhập cổng RPC bắt đầu (đề nghị sử dụng 30001): " start_rpc_port

# Nhập dung lượng lưu trữ cho node
read -p "Nhập dung lượng lưu trữ cho node (GB), giới hạn tối đa 2TB: " storage_gb

# Nhập đường dẫn lưu trữ (tùy chọn)
read -p "Nhập đường dẫn lưu trữ dữ liệu cho node trên máy chủ (bỏ qua để sử dụng đường dẫn mặc định titan_storage_01): " custom_storage_path

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

# Xác định đường dẫn lưu trữ (nếu không nhập, sử dụng mặc định)
if [ -z "$custom_storage_path" ]; then
    # Sử dụng đường dẫn mặc định
    storage_path="$PWD/titan_storage_01"
else
    # Sử dụng đường dẫn do người dùng nhập
    storage_path="$custom_storage_path"
fi

# Tạo thư mục lưu trữ
mkdir -p "$storage_path"

# Khởi chạy container và thiết lập chính sách khởi động lại luôn
container_id=$(docker run -d --restart always -v "$storage_path:/root/.titanedge/titan_01" --name "titan_01" --net=host  nezha123/titan-edge:1.7)

echo "Node titan_01 đã được khởi động với Container ID: $container_id"

sleep 30

# Chỉnh sửa tệp cấu hình để cài đặt dung lượng lưu trữ và cổng RPC
docker exec $container_id bash -c "\
    sed -i 's/^[[:space:]]*#StorageGB = .*/StorageGB = $storage_gb/' /root/.titanedge/config.toml && \
    sed -i 's/^[[:space:]]*#ListenAddress = \"0.0.0.0:1234\"/ListenAddress = \"0.0.0.0:$current_rpc_port\"/' /root/.titanedge/config.toml && \
    echo 'Node titan_01 đã được cấu hình với dung lượng lưu trữ $storage_gb GB, cổng RPC là $start_rpc_port'"

# Khởi động lại container để áp dụng cài đặt
docker restart $container_id

# Liên kết container với mã định danh
docker exec $container_id bash -c "\
    titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
echo "Node titan_01 đã được liên kết."

echo "============================== Node titan_01 đã được cài đặt và khởi chạy thành công ==================================="
}

# Chức năng gỡ cài đặt node
function uninstall_node() {
    echo "Bạn có chắc chắn muốn gỡ bỏ chương trình Titan Node? Tất cả dữ liệu liên quan sẽ bị xóa. [Y/N]"
    read -r -p "Vui lòng xác nhận: " response

    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Bắt đầu gỡ cài đặt node..."
            sudo docker stop "titan_01" && sudo docker rm "titan_01"
            rm -rf "$PWD/titan_storage_01"
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
        echo "Script cài đặt Titan Node."
        echo "================================================================"
        echo "Vui lòng chọn hành động:"
        echo "1. Cài đặt Node Titan_01"
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
