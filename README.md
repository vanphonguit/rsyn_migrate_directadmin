# rsyn_migrate_directadmin

script giúp chuyển dữ liệu VPS từ 1 VPS directadmin sang 1 vps directadmin, mục đích:

+ Chuyển dữ liệu từ các VPS gần full dữ liệu disk sang vps mới tránh việc backup lỗi file.
+ Trên VPS mới, mỗi một tên miền sẽ được tạo một user mới, tránh việc sử dụng quá nhiều tên miền trên 1 user, chỉ đồng bộ source và database không đồng bộ user giúp bảo mật tốt hơn.
+ Tự động cấu hình lại database đối với các website là wordpress được chuyển sang.


# chạy chương trình :

Tại VPS cần chuyển dữ liệu tới tải file :

1. **wget -O https://github.com/vanphonguit/rsyn_migrate_directadmin/blob/main/movevpsda.sh**

+ edit file tải về sửa IP VPS cần sysn data.
+ sửa giá trị **pass_da** là pass admin của VPS directadmin cần chuyển dữ liệu tới.

Chạy lệnh sau để bắt đầu chuyển dữ liệu: 

2. **bash movevpsda.sh**


Nhập pass root VPS vps remote để chuyển.


# Một số thông tin khác log.

+ Nếu cần bỏ qua tên miền nào không cần chuyển dữ liệu qua, tạo file : **not_tranfer** nhập các tên miền cần bỏ qua, mỗi tên miền ở một dòng.
+ Thông tin của các user/domain/password đăng nhập trang directadmin trên VPS mới sẽ được lưu ở file: **log_tranfer/listaccount**
+ Thông tin các tên miền không chuyển dữ liệu qua do không có folder web trên VPS cũ ở file log **log_tranfer/listdomainfail**
+ Thông tin domain và cấu hình database mới chuyển qua với các website là wordpress ở file : **log_tranfer/wp-done**
+ Thông tin các domain đã chuyển dữ liệu qua nhưng không phải là wordpress cần cấu hình lại database ở file : **log_tranfer/not-wp**
+ Tất cả các database chưa import, cấu hình trên website nào ở vps mới sẽ được lưu ở folder **data_mysql**
