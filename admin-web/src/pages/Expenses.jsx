import { useState } from 'react'
import { Download, AlertTriangle, MoreVertical, ChevronLeft, ChevronRight, CheckCircle, AlertCircle, RotateCcw } from 'lucide-react'
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts'

const expenses = [
  { icon: '🏢', name: 'Căn hộ Skyline 4B', sub: '4 Người tham gia', amount: '2.450.000 đ', method: 'Chia đều', status: 'Đã tất toán', statusColor: 'text-emerald-600 dark:text-emerald-400' },
  { icon: '⚡', name: 'Điện nước tháng 9', sub: 'Dịch vụ dùng chung', amount: '412.150 đ', method: 'Phần trăm %', status: 'Tranh chấp (2)', statusColor: 'text-red-500', hasAction: true },
  { icon: '🛒', name: 'Cải tạo Nhà bếp', sub: 'Mua sắm nhóm', amount: '5.800.000 đ', method: 'Tùy chỉnh', status: '3/5 Đã đóng', statusColor: 'text-amber-600 dark:text-amber-400' },
  { icon: '📶', name: 'Internet Cáp quang', sub: 'Cố định hàng tháng', amount: '89.990 đ', method: 'Chia đều', status: 'Chờ xác minh', statusColor: 'text-amber-500', hasHistory: true },
]

const pieData = [
  { name: 'Chia đều', value: 64, color: '#2F6BFF' },
  { name: 'Thủ công', value: 22, color: '#e2e8f0' },
  { name: 'Phần trăm', value: 14, color: '#ef4444' },
]

const activity = [
  { icon: CheckCircle, color: 'text-emerald-500', text: 'Alex Chen đã đóng 612.500 đ', sub: 'Căn hộ Skyline 4B · 2 giờ trước' },
  { icon: AlertCircle, color: 'text-red-500', text: 'Tranh chấp mới được gửi', sub: 'Điện nước tháng 9 (Jordan Smith) · 5 giờ trước' },
  { icon: RotateCcw, color: 'text-primary', text: 'Tự động tất toán thành công', sub: 'Hóa đơn Internet · Hôm qua lúc 11:45 CH' },
]

const tabs = ['Tất cả chi phí', 'Đang chờ', 'Bị gắn cờ']

export default function Expenses() {
  const [activeTab, setActiveTab] = useState('Tất cả chi phí')

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between pb-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Quản lý Chi tiêu</h1>
          <p className="text-gray-400 dark:text-gray-500 text-sm text-gray-400 dark:text-gray-500 mt-1">Tổng quan chi tiêu theo thời gian thực cho quản gia hiện đại.</p>
        </div>
        <div className="flex gap-2">
          <button className="flex items-center gap-2 px-4 py-2.5 border border-gray-200 dark:border-gray-700 rounded-xl
            text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700
            active:scale-[0.98] transition-all cursor-pointer">
            <Download size={14} /> Xuất CSV
          </button>
          <button className="flex items-center gap-2 px-4 py-2.5 bg-red-500 text-white rounded-xl
            text-sm font-bold hover:bg-red-600 active:scale-[0.98] transition-all cursor-pointer">
            <AlertTriangle size={14} /> Giải quyết Tranh chấp
          </button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-6">
          <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">Tổng thanh toán đã xử lý</p>
          <p className="text-4xl font-extrabold text-gray-900 dark:text-white mt-2 tabular-nums">
            142.850.000<span className="text-2xl">đ</span>
          </p>
          <p className="text-sm font-bold text-emerald-600 dark:text-emerald-400 mt-2">↗ +12.5% so với tháng trước</p>
        </div>
        <div className="bg-red-500 rounded-2xl p-6 text-white">
          <p className="text-xs font-extrabold text-red-200 uppercase tracking-widest">Tranh chấp chưa giải quyết</p>
          <p className="text-5xl font-extrabold mt-2 tabular-nums">14</p>
          <p className="text-sm font-bold text-red-200 mt-2">Yêu cầu xử lý khẩn cấp!</p>
        </div>
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-700 flex items-center justify-between">
          <h2 className="text-base font-bold text-gray-800 dark:text-gray-100">Sổ cái Chung Đang hoạt động</h2>
          <div className="flex gap-1 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl p-1">
            {tabs.map(t => (
              <button key={t} onClick={() => setActiveTab(t)}
                className={`px-3 py-1.5 text-sm rounded-lg font-semibold transition-all duration-150 cursor-pointer ${
                  activeTab === t
                    ? 'bg-white dark:bg-gray-700 text-gray-900 dark:text-white shadow-sm'
                    : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
                }`}>
                {t}
              </button>
            ))}
          </div>
        </div>

        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100 dark:border-gray-700">
              {['Tên nhóm', 'Tổng số tiền', 'Cách chia', 'Trạng thái'].map(h => (
                <th key={h} className="text-left text-xs font-extrabold text-gray-400 dark:text-gray-500
                  uppercase tracking-widest px-5 py-3.5">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50 dark:divide-gray-700">
            {expenses.map((e, i) => (
              <tr key={i} className="hover:bg-gray-50 dark:hover:bg-gray-700/60 transition-colors duration-100">
                <td className="px-5 py-4">
                  <div className="flex items-center gap-3">
                    <span className="text-xl">{e.icon}</span>
                    <div>
                      <p className="text-sm font-bold text-gray-800 dark:text-gray-100">{e.name}</p>
                      <p className="text-xs font-medium text-gray-400 dark:text-gray-500">{e.sub}</p>
                    </div>
                  </div>
                </td>
                <td className="px-5 py-4 text-sm font-extrabold text-gray-800 dark:text-gray-100">{e.amount}</td>
                <td className="px-5 py-4">
                  <span className="text-xs font-semibold border border-gray-200 dark:border-gray-700
                    px-2.5 py-1 rounded-lg text-gray-600 dark:text-gray-400">{e.method}</span>
                </td>
                <td className="px-5 py-4">
                  <div className="flex items-center justify-between">
                    <span className={`text-sm font-bold ${e.statusColor}`}>● {e.status}</span>
                    {e.hasAction && (
                      <button className="px-3 py-1 bg-red-600 text-white text-xs font-bold rounded-xl
                        hover:bg-red-700 active:scale-95 transition-all cursor-pointer">Giải quyết</button>
                    )}
                    {e.hasHistory && (
                      <button className="p-1.5 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 cursor-pointer">
                        <RotateCcw size={15} />
                      </button>
                    )}
                    {!e.hasAction && !e.hasHistory && (
                      <button className="p-1.5 text-gray-400 dark:text-gray-500 cursor-pointer">
                        <MoreVertical size={15} />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-400 dark:text-gray-500">Hiển thị 4 trên 128 giao dịch</p>
          <div className="flex items-center gap-1">
            <button className="p-1.5 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-500 dark:text-gray-400 cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700"><ChevronLeft size={15} /></button>
            <button className="w-7 h-7 bg-primary text-white text-sm rounded-lg font-bold">1</button>
            <button className="w-7 h-7 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg cursor-pointer">2</button>
            <button className="p-1.5 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-500 dark:text-gray-400 cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700"><ChevronRight size={15} /></button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-5">
          <h3 className="text-base font-bold text-gray-800 dark:text-gray-100 mb-3">Lịch sử Thanh toán</h3>
          <div className="space-y-3">
            {activity.map((a, i) => (
              <div key={i} className="flex items-start gap-2.5">
                <a.icon size={16} className={`${a.color} flex-shrink-0 mt-0.5`} />
                <div>
                  <p className="text-sm font-bold text-gray-800 dark:text-gray-100">{a.text}</p>
                  <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-0.5">{a.sub}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-5">
          <h3 className="text-base font-bold text-gray-800 dark:text-gray-100">Phân bổ cách chia</h3>
          <p className="text-xs font-semibold text-primary mb-2 mt-0.5">Phân tích ưu tiên hệ thống</p>
          <ResponsiveContainer width="100%" height={160}>
            <PieChart>
              <Pie data={pieData} cx="50%" cy="50%" innerRadius={45} outerRadius={70} dataKey="value">
                {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
              </Pie>
              <Tooltip formatter={(v) => [`${v}%`]} contentStyle={{ borderRadius: 12, border: 'none', boxShadow: '0 4px 24px rgba(0,0,0,0.1)' }} />
            </PieChart>
          </ResponsiveContainer>
          <div className="flex justify-center gap-4 mt-2">
            {pieData.map(p => (
              <div key={p.name} className="flex items-center gap-1.5">
                <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ background: p.color }} />
                <span className="text-xs font-semibold text-gray-500 dark:text-gray-400">{p.name}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
