import { useState } from 'react'
import { Download, AlertTriangle, MoreVertical, ChevronLeft, ChevronRight, CheckCircle, AlertCircle, RotateCcw } from 'lucide-react'
import { PieChart, Pie, Cell, Legend, Tooltip, ResponsiveContainer } from 'recharts'

const expenses = [
  { icon: '🏢', name: 'Căn hộ Skyline 4B', sub: '4 Người tham gia', amount: '2.450.000 đ', method: 'Chia đều', status: 'Đã tất toán', statusColor: 'text-green-600' },
  { icon: '⚡', name: 'Điện nước tháng 9', sub: 'Dịch vụ dùng chung', amount: '412.150 đ', method: 'Phần trăm %', status: 'Tranh chấp (2)', statusColor: 'text-red-500', hasAction: true },
  { icon: '🛒', name: 'Cải tạo Nhà bếp', sub: 'Mua sắm nhóm', amount: '5.800.000 đ', method: 'Tùy chỉnh', status: '3/5 Đã đóng', statusColor: 'text-yellow-600', avatars: true },
  { icon: '📶', name: 'Internet Cáp quang', sub: 'Cố định hàng tháng', amount: '89.990 đ', method: 'Chia đều', status: 'Chờ xác minh', statusColor: 'text-yellow-500', hasHistory: true },
]

const pieData = [
  { name: 'Đều', value: 64, color: '#2563EB' },
  { name: 'Thủ công', value: 22, color: '#E2E8F0' },
  { name: 'Phần trăm', value: 14, color: '#EF4444' },
]

const activity = [
  { icon: CheckCircle, color: 'text-green-500', text: 'Alex Chen đã đóng 612.500 đ', sub: 'Căn hộ Skyline 4B · 2 giờ trước' },
  { icon: AlertCircle, color: 'text-red-500', text: 'Tranh chấp mới được gửi', sub: 'Điện nước tháng 9 (Jordan Smith) · 5 giờ trước' },
  { icon: RotateCcw, color: 'text-blue-500', text: 'Tự động tất toán thành công', sub: 'Hóa đơn Internet · Hôm qua lúc 11:45 CH' },
]

const tabs = ['Tất cả chi phí', 'Đang chờ', 'Bị gắn cờ']

export default function Expenses() {
  const [activeTab, setActiveTab] = useState('Tất cả chi phí')

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Quản lý Chi tiêu</h1>
          <p className="text-gray-500 text-sm mt-1">Tổng quan số cái thời gian thực cho quản gia hiện đại.</p>
        </div>
        <div className="flex gap-2">
          <button className="flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-lg text-sm font-medium text-gray-600 hover:bg-gray-50">
            <Download size={15} /> Xuất CSV
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-red-500 text-white rounded-lg text-sm font-semibold hover:bg-red-600">
            <AlertTriangle size={15} /> Giải quyết Tranh chấp
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Tổng thanh toán đã xử lý</p>
          <p className="text-4xl font-bold text-gray-900 mt-2">142.850.000<span className="text-2xl">đ</span></p>
          <p className="text-sm text-green-600 font-medium mt-2 flex items-center gap-1">↗ +12.5% so với tháng trước</p>
        </div>
        <div className="bg-red-500 rounded-xl p-6 text-white">
          <p className="text-xs font-semibold text-red-200 uppercase tracking-wider">Tranh chấp chưa giải quyết</p>
          <p className="text-5xl font-bold mt-2">14</p>
          <p className="text-sm text-red-200 mt-2">Yêu cầu xử lý khẩn cấp !</p>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 className="font-semibold text-gray-800">Sổ cái Chung Đang hoạt động</h2>
          <div className="flex gap-1">
            {tabs.map(t => (
              <button key={t} onClick={() => setActiveTab(t)}
                className={`px-4 py-1.5 text-sm rounded-lg font-medium transition-colors ${activeTab === t ? 'bg-gray-900 text-white' : 'text-gray-600 hover:bg-gray-100'}`}>
                {t}
              </button>
            ))}
          </div>
        </div>

        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100">
              {['Tên nhóm', 'Tổng số tiền', 'Cách chia', 'Trạng thái'].map(h => (
                <th key={h} className="text-left text-xs font-semibold text-gray-500 uppercase tracking-wider px-5 py-3">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {expenses.map((e, i) => (
              <tr key={i} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                <td className="px-5 py-4">
                  <div className="flex items-center gap-3">
                    <span className="text-xl">{e.icon}</span>
                    <div>
                      <p className="text-sm font-semibold text-gray-800">{e.name}</p>
                      <p className="text-xs text-gray-400">{e.sub}</p>
                    </div>
                  </div>
                </td>
                <td className="px-5 py-4 text-sm font-semibold text-gray-800">{e.amount}</td>
                <td className="px-5 py-4">
                  <span className="text-xs border border-gray-200 px-2 py-1 rounded text-gray-600">{e.method}</span>
                </td>
                <td className="px-5 py-4">
                  <div className="flex items-center justify-between">
                    <span className={`text-sm font-medium ${e.statusColor}`}>● {e.status}</span>
                    {e.hasAction && <button className="px-3 py-1 bg-red-600 text-white text-xs font-semibold rounded-lg hover:bg-red-700">Giải quyết</button>}
                    {e.hasHistory && <button className="p-1 text-gray-400 hover:text-gray-600"><RotateCcw size={15} /></button>}
                    {!e.hasAction && !e.hasHistory && <button className="p-1 text-gray-400"><MoreVertical size={15} /></button>}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="px-5 py-3 border-t border-gray-100 flex items-center justify-between">
          <p className="text-sm text-gray-500">Hiển thị 4 trên 128 giao dịch được ghi nhận</p>
          <div className="flex items-center gap-1">
            <button className="p-1.5 border border-gray-200 rounded text-gray-500"><ChevronLeft size={15} /></button>
            <button className="w-7 h-7 bg-blue-600 text-white text-sm rounded font-medium">1</button>
            <button className="w-7 h-7 text-sm text-gray-600 hover:bg-gray-100 rounded">2</button>
            <button className="p-1.5 border border-gray-200 rounded text-gray-500"><ChevronRight size={15} /></button>
          </div>
        </div>
      </div>

      {/* Bottom row */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800 mb-3">Lịch sử Thanh toán</h3>
          <div className="space-y-3">
            {activity.map((a, i) => (
              <div key={i} className="flex items-start gap-2.5">
                <a.icon size={16} className={`${a.color} flex-shrink-0 mt-0.5`} />
                <div>
                  <p className="text-sm font-medium text-gray-800">{a.text}</p>
                  <p className="text-xs text-gray-400">{a.sub}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800 mb-1">Phân bổ cách chia</h3>
          <p className="text-xs text-blue-600 mb-2">Phân tích ưu tiên hệ thống</p>
          <ResponsiveContainer width="100%" height={160}>
            <PieChart>
              <Pie data={pieData} cx="50%" cy="50%" innerRadius={45} outerRadius={70} dataKey="value">
                {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
              </Pie>
              <Tooltip formatter={(v) => [`${v}%`]} />
            </PieChart>
          </ResponsiveContainer>
          <div className="flex justify-center gap-4 mt-2">
            {pieData.map(p => (
              <div key={p.name} className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-full" style={{ background: p.color }} />
                <span className="text-xs text-gray-600">{p.name}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
