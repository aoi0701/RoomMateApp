import { AlertTriangle, Eye, CheckCircle, Ban } from 'lucide-react'

const violations = [
  { id: '#V-1042', user: 'John Doe', type: 'Nội dung không phù hợp', time: '10 phút trước', severity: 'Cao', severityColor: 'bg-red-100 text-red-600', status: 'Chờ xử lý' },
  { id: '#V-1041', user: 'Jane Smith', type: 'Spam bài đăng', time: '1 giờ trước', severity: 'Trung bình', severityColor: 'bg-yellow-100 text-yellow-600', status: 'Đang xem xét' },
  { id: '#V-1040', user: 'Bob Lee', type: 'Thông tin sai lệch', time: '3 giờ trước', severity: 'Thấp', severityColor: 'bg-green-100 text-green-600', status: 'Đã giải quyết' },
]

export default function Violations() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Quản lý Vi phạm</h1>
        <p className="text-gray-500 text-sm mt-1">Xem xét và xử lý các báo cáo vi phạm trong hệ thống.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Chờ xử lý', value: '14', color: 'text-red-500', bg: 'bg-red-50 border-red-100' },
          { label: 'Đang xem xét', value: '8', color: 'text-yellow-600', bg: 'bg-yellow-50 border-yellow-100' },
          { label: 'Đã giải quyết', value: '142', color: 'text-green-600', bg: 'bg-green-50 border-green-100' },
        ].map(s => (
          <div key={s.label} className={`rounded-xl border p-5 shadow-sm ${s.bg}`}>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider">{s.label}</p>
            <p className={`text-3xl font-bold mt-2 ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100">
          <h2 className="font-semibold text-gray-800">Danh sách vi phạm</h2>
        </div>
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100">
              {['ID', 'Người dùng', 'Loại vi phạm', 'Thời gian', 'Mức độ', 'Trạng thái', 'Thao tác'].map(h => (
                <th key={h} className="text-left text-xs font-semibold text-gray-500 uppercase tracking-wider px-4 py-3">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {violations.map((v, i) => (
              <tr key={i} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                <td className="px-4 py-4 text-xs font-mono bg-gray-50 rounded">{v.id}</td>
                <td className="px-4 py-4 text-sm font-medium text-gray-800">{v.user}</td>
                <td className="px-4 py-4 text-sm text-gray-600">{v.type}</td>
                <td className="px-4 py-4 text-xs text-gray-400">{v.time}</td>
                <td className="px-4 py-4">
                  <span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${v.severityColor}`}>{v.severity}</span>
                </td>
                <td className="px-4 py-4 text-sm text-gray-600">{v.status}</td>
                <td className="px-4 py-4">
                  <div className="flex gap-2">
                    <button className="p-1.5 text-blue-500 hover:bg-blue-50 rounded"><Eye size={15} /></button>
                    <button className="p-1.5 text-green-500 hover:bg-green-50 rounded"><CheckCircle size={15} /></button>
                    <button className="p-1.5 text-red-400 hover:bg-red-50 rounded"><Ban size={15} /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
