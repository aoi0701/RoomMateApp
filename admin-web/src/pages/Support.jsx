import { Filter, ArrowUpDown, ChevronLeft, ChevronRight } from 'lucide-react'

const tickets = [
  { category: 'THANH TOÁN', id: 'Vé #FL-9021', title: 'Sai lệch trong việc chia hóa đơn điện nước hàng tháng cho Cả...', desc: 'Người dùng báo cáo rằng tính toán tiền điện tử động không tính cho nửa ...', priority: 'ƯU TIÊN CAO', priorityColor: 'bg-red-100 text-red-600', status: 'MỞ', statusColor: 'bg-blue-100 text-blue-600', time: '2 phút trước' },
  { category: 'HỒ SƠ', id: 'Vé #FL-8944', title: 'Không thể cập nhật thông tin liên lạc khẩn cấp', desc: 'Thông báo lỗi hiện lên mỗi khi nhấn nút \'Lưu\' trong trang cài đặt hồ sơ...', priority: 'ƯU TIÊN THẤP', priorityColor: 'bg-green-100 text-green-600', status: 'ĐANG CHỜ', statusColor: 'bg-orange-100 text-orange-600', time: '45 phút trước' },
  { category: 'KỸ THUẬT', id: 'Vé #FL-8812', title: 'Ứng dụng di động bị treo khi khởi động trên iOS 17.4', desc: 'Nhật ký hiển thị lỗi con trỏ null khi khởi tạo màn hình chờ...', priority: 'TRUNG BÌNH', priorityColor: 'bg-yellow-100 text-yellow-600', status: 'MỞ', statusColor: 'bg-blue-100 text-blue-600', time: '2 giờ trước' },
  { category: 'THANH TOÁN', id: 'Vé #FL-8750', title: 'Yêu cầu hoàn tiền cho việc thanh toán trùng trong tháng 1', desc: 'Đã giải quyết: Tiền đã được hoàn vào số dư tài khoản và thông báo cho n...', priority: 'ƯU TIÊN THẤP', priorityColor: 'bg-green-100 text-green-600', status: 'ĐÃ GIẢI QUYẾT', statusColor: 'bg-green-100 text-green-600', time: '5 giờ trước' },
]

const leaderboard = [
  { initials: 'AS', name: 'Alex Smith', count: '12 Giải quyết', color: 'bg-blue-600' },
  { initials: 'MJ', name: 'Maria Jones', count: '09 Giải quyết', color: 'bg-purple-600' },
]

export default function Support() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Trung tâm Hỗ trợ</h1>
        <p className="text-gray-500 text-sm mt-1">Quản lý các thắc mắc của người dùng và giải quyết vé hỗ trợ để đảm bảo trải nghiệm tìm bạn ở chung liền mạch.</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Vé đang mở', value: '24' },
          { label: 'Phản hồi TB', value: '1.2g' },
          { label: 'Chưa phân công', value: '08', red: true },
          { label: 'Hài lòng', value: '98%', blue: true },
        ].map((s) => (
          <div key={s.label} className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{s.label}</p>
            <p className={`text-3xl font-bold mt-2 ${s.red ? 'text-red-500' : s.blue ? 'text-blue-600' : 'text-gray-900'}`}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* Ticket list */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 className="font-semibold text-gray-800">Yêu cầu hỗ trợ gần đây</h2>
          <div className="flex gap-2">
            <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">
              <Filter size={14} /> Lọc
            </button>
            <button className="flex items-center gap-1.5 px-3 py-1.5 text-sm border border-gray-200 rounded-lg text-gray-600 hover:bg-gray-50">
              <ArrowUpDown size={14} /> Sắp xếp
            </button>
          </div>
        </div>

        <div className="divide-y divide-gray-50">
          {tickets.map((t, i) => (
            <div key={i} className="px-5 py-4 hover:bg-gray-50 transition-colors cursor-pointer">
              <div className="flex items-start justify-between gap-4">
                <div className="flex gap-3 flex-1 min-w-0">
                  <div className="w-9 h-9 rounded-lg bg-blue-50 flex items-center justify-center flex-shrink-0 text-blue-600 text-xs font-bold">
                    {t.category[0]}
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <span className="text-xs font-semibold text-blue-600">{t.category}</span>
                      <span className="text-xs text-gray-400">· {t.id}</span>
                    </div>
                    <p className="text-sm font-semibold text-gray-800 truncate">{t.title}</p>
                    <p className="text-xs text-gray-500 mt-0.5 truncate">{t.desc}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  <div className="text-right">
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${t.priorityColor}`}>{t.priority}</span>
                    <p className="text-xs text-gray-400 mt-1">{t.time}</p>
                  </div>
                  <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${t.statusColor}`}>{t.status}</span>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="px-5 py-3 border-t border-gray-100 flex items-center justify-between">
          <p className="text-sm text-gray-500">Hiển thị 4 trên 24 vé</p>
          <div className="flex gap-1">
            <button className="p-1.5 border border-gray-200 rounded-lg text-gray-500 hover:bg-gray-50"><ChevronLeft size={16} /></button>
            <button className="p-1.5 border border-gray-200 rounded-lg text-gray-500 hover:bg-gray-50"><ChevronRight size={16} /></button>
          </div>
        </div>
      </div>

      {/* Bottom row */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800">Tối ưu hóa thời gian phản hồi</h3>
          <p className="text-sm text-gray-500 mt-1">Phân tích AI của chúng tôi cho thấy 40% vé Thanh toán có thể giải quyết bằng hướng dẫn "Tranh chấp thanh toán" tự động. Bạn có muốn tạo mẫu không?</p>
          <button className="mt-4 px-4 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700">Bật Mẫu tự động</button>
        </div>

        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">Bảng xếp hạng hỗ trợ</p>
          <div className="space-y-3">
            {leaderboard.map((l, i) => (
              <div key={i} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className={`w-8 h-8 rounded-full ${l.color} flex items-center justify-center text-white text-xs font-bold`}>{l.initials}</div>
                  <span className="text-sm font-medium text-gray-800">{l.name}</span>
                </div>
                <span className="text-sm text-gray-500">{l.count}</span>
              </div>
            ))}
          </div>
          <button className="w-full mt-4 py-2 bg-gray-900 text-white text-sm font-semibold rounded-lg hover:bg-gray-800">Báo cáo đầy đủ</button>
        </div>
      </div>
    </div>
  )
}
