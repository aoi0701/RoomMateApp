import { Filter, ArrowUpDown, ChevronLeft, ChevronRight } from 'lucide-react'

const tickets = [
  { category: 'THANH TOÁN', id: 'Vé #FL-9021', title: 'Sai lệch trong việc chia hóa đơn điện nước hàng tháng', desc: 'Người dùng báo cáo rằng tính toán tiền điện tử động không tính cho nửa...', priority: 'ƯU TIÊN CAO', priorityColor: 'bg-red-50 dark:bg-red-950 text-red-600 dark:text-red-400 ring-1 ring-red-100 dark:ring-red-900', status: 'MỞ', statusColor: 'bg-primary-light dark:bg-primary/20 text-primary', time: '2 phút trước' },
  { category: 'HỒ SƠ', id: 'Vé #FL-8944', title: 'Không thể cập nhật thông tin liên lạc khẩn cấp', desc: 'Thông báo lỗi hiện lên mỗi khi nhấn nút Lưu trong trang cài đặt hồ sơ...', priority: 'ƯU TIÊN THẤP', priorityColor: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-100 dark:ring-emerald-900', status: 'ĐANG CHỜ', statusColor: 'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400', time: '45 phút trước' },
  { category: 'KỸ THUẬT', id: 'Vé #FL-8812', title: 'Ứng dụng di động bị treo khi khởi động trên iOS 17.4', desc: 'Nhật ký hiển thị lỗi con trỏ null khi khởi tạo màn hình chờ...', priority: 'TRUNG BÌNH', priorityColor: 'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900', status: 'MỞ', statusColor: 'bg-primary-light dark:bg-primary/20 text-primary', time: '2 giờ trước' },
  { category: 'THANH TOÁN', id: 'Vé #FL-8750', title: 'Yêu cầu hoàn tiền cho việc thanh toán trùng trong tháng 1', desc: 'Đã giải quyết: Tiền đã được hoàn vào số dư tài khoản và thông báo cho người dùng...', priority: 'ƯU TIÊN THẤP', priorityColor: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-100 dark:ring-emerald-900', status: 'ĐÃ GIẢI QUYẾT', statusColor: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400', time: '5 giờ trước' },
]

const leaderboard = [
  { initials: 'AS', name: 'Alex Smith', count: '12 Giải quyết', color: 'bg-primary' },
  { initials: 'MJ', name: 'Maria Jones', count: '09 Giải quyết', color: 'bg-violet-600' },
]

export default function Support() {
  return (
    <div className="space-y-8">
      <div className="pb-4">
        <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white">Trung tâm Hỗ trợ</h1>
        <p className="text-gray-400 dark:text-gray-500 text-sm font-medium mt-2 mb-2">Quản lý thắc mắc của người dùng và giải quyết vé hỗ trợ.</p>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Vé đang mở', value: '24', color: 'text-primary' },
          { label: 'Phản hồi TB', value: '1.2g', color: 'text-gray-700 dark:text-gray-200' },
          { label: 'Chưa phân công', value: '08', color: 'text-red-500' },
          { label: 'Hài lòng', value: '98%', color: 'text-emerald-600 dark:text-emerald-400' },
        ].map(s => (
          <div key={s.label} className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5
            hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 cursor-default">
            <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest mb-3">{s.label}</p>
            <p className={`text-4xl font-extrabold tabular-nums ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm">
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between">
          <h2 className="text-base font-bold text-gray-800 dark:text-gray-100">Yêu cầu hỗ trợ gần đây</h2>
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-semibold border border-gray-200 dark:border-gray-700
              rounded-xl text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 transition-all cursor-pointer">
              <Filter size={13} /> Lọc
            </button>
            <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-semibold border border-gray-200 dark:border-gray-700
              rounded-xl text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 transition-all cursor-pointer">
              <ArrowUpDown size={13} /> Sắp xếp
            </button>
          </div>
        </div>

        <div className="divide-y divide-gray-50 dark:divide-gray-800">
          {tickets.map((t, i) => (
            <div key={i} className="px-5 py-4 hover:bg-gray-50 dark:hover:bg-gray-800/60 transition-colors duration-100 cursor-pointer">
              <div className="flex items-start justify-between gap-4">
                <div className="flex gap-3 flex-1 min-w-0">
                  <div className="w-9 h-9 rounded-xl bg-primary-light dark:bg-primary/20 flex items-center justify-center
                    flex-shrink-0 text-primary text-xs font-extrabold">
                    {t.category[0]}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <span className="text-xs font-extrabold text-primary">{t.category}</span>
                      <span className="text-xs font-semibold text-gray-400 dark:text-gray-500">· {t.id}</span>
                    </div>
                    <p className="text-sm font-bold text-gray-800 dark:text-gray-100 truncate">{t.title}</p>
                    <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-0.5 truncate">{t.desc}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  <div className="text-right">
                    <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${t.priorityColor}`}>{t.priority}</span>
                    <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 mt-1">{t.time}</p>
                  </div>
                  <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${t.statusColor}`}>{t.status}</span>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-400 dark:text-gray-500">Hiển thị 4 trên 24 vé</p>
          <div className="flex gap-1">
            <button className="p-1.5 border border-gray-200 dark:border-gray-700 rounded-xl text-gray-500 dark:text-gray-400
              hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-all"><ChevronLeft size={16} /></button>
            <button className="p-1.5 border border-gray-200 dark:border-gray-700 rounded-xl text-gray-500 dark:text-gray-400
              hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-all"><ChevronRight size={16} /></button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5">
          <h3 className="text-base font-bold text-gray-800 dark:text-gray-100">Tối ưu hóa thời gian phản hồi</h3>
          <p className="text-sm font-medium text-gray-500 dark:text-gray-400 mt-2">Phân tích AI cho thấy 40% vé Thanh toán có thể giải quyết bằng hướng dẫn tự động. Bạn có muốn tạo mẫu không?</p>
          <button className="mt-4 px-4 py-2.5 bg-primary text-white text-sm font-bold rounded-xl
            hover:bg-primary-dark active:scale-[0.98] transition-all duration-150 cursor-pointer">Bật Mẫu tự động</button>
        </div>

        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5">
          <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest mb-4">Bảng xếp hạng hỗ trợ</p>
          <div className="space-y-3">
            {leaderboard.map((l, i) => (
              <div key={i} className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className={`w-8 h-8 rounded-full ${l.color} flex items-center justify-center text-white text-xs font-extrabold`}>{l.initials}</div>
                  <span className="text-sm font-bold text-gray-800 dark:text-gray-100">{l.name}</span>
                </div>
                <span className="text-sm font-semibold text-gray-400 dark:text-gray-500">{l.count}</span>
              </div>
            ))}
          </div>
          <button className="w-full mt-4 py-2.5 bg-gray-900 dark:bg-gray-700 text-white text-sm font-bold rounded-xl
            hover:bg-gray-800 dark:hover:bg-gray-600 active:scale-[0.98] transition-all duration-150 cursor-pointer">
            Báo cáo đầy đủ
          </button>
        </div>
      </div>
    </div>
  )
}
