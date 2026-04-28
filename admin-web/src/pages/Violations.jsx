import { AlertTriangle, Eye, CheckCircle, Ban, Clock } from 'lucide-react'

const violations = [
  { id: '#V-1042', user: 'John Doe', type: 'Nội dung không phù hợp', time: '10 phút trước', severity: 'Cao', severityColor: 'bg-red-50 dark:bg-red-950 text-red-600 dark:text-red-400 ring-1 ring-red-100 dark:ring-red-900', status: 'Chờ xử lý', statusColor: 'text-amber-600 dark:text-amber-400' },
  { id: '#V-1041', user: 'Jane Smith', type: 'Spam bài đăng', time: '1 giờ trước', severity: 'Trung bình', severityColor: 'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900', status: 'Đang xem xét', statusColor: 'text-primary' },
  { id: '#V-1040', user: 'Bob Lee', type: 'Thông tin sai lệch', time: '3 giờ trước', severity: 'Thấp', severityColor: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-100 dark:ring-emerald-900', status: 'Đã giải quyết', statusColor: 'text-emerald-600 dark:text-emerald-400' },
]

export default function Violations() {
  return (
    <div className="space-y-8">
      <div className="pb-4">
        <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white">Quản lý Vi phạm</h1>
        <p className="text-gray-400 dark:text-gray-500 text-sm font-medium mt-2 mb-2">Xem xét và xử lý các báo cáo vi phạm trong hệ thống.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Chờ xử lý', value: '14', color: 'text-red-500', icon: AlertTriangle },
          { label: 'Đang xem xét', value: '8', color: 'text-amber-600 dark:text-amber-400', icon: Clock },
          { label: 'Đã giải quyết', value: '142', color: 'text-emerald-600 dark:text-emerald-400', icon: CheckCircle },
        ].map(s => (
          <div key={s.label} className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5
            hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 cursor-default">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">{s.label}</p>
              <s.icon size={15} className={s.color} />
            </div>
            <p className={`text-4xl font-extrabold ${s.color} tabular-nums`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-800">
          <h2 className="text-base font-bold text-gray-800 dark:text-gray-100">Danh sách vi phạm</h2>
        </div>
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100 dark:border-gray-800">
              {['ID', 'Người dùng', 'Loại vi phạm', 'Thời gian', 'Mức độ', 'Trạng thái', 'Thao tác'].map(h => (
                <th key={h} className="text-left text-xs font-extrabold text-gray-400 dark:text-gray-500
                  uppercase tracking-widest px-4 py-3.5">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50 dark:divide-gray-800">
            {violations.map((v, i) => (
              <tr key={i} className="hover:bg-gray-50 dark:hover:bg-gray-800/60 transition-colors duration-100">
                <td className="px-4 py-4">
                  <span className="text-xs font-bold font-mono bg-gray-100 dark:bg-gray-800
                    text-gray-600 dark:text-gray-400 px-2 py-1 rounded-lg">{v.id}</span>
                </td>
                <td className="px-4 py-4 text-sm font-bold text-gray-800 dark:text-gray-100">{v.user}</td>
                <td className="px-4 py-4 text-sm font-semibold text-gray-600 dark:text-gray-400">{v.type}</td>
                <td className="px-4 py-4 text-xs font-semibold text-gray-400 dark:text-gray-500">{v.time}</td>
                <td className="px-4 py-4">
                  <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${v.severityColor}`}>{v.severity}</span>
                </td>
                <td className="px-4 py-4">
                  <span className={`text-sm font-bold ${v.statusColor}`}>{v.status}</span>
                </td>
                <td className="px-4 py-4">
                  <div className="flex gap-1">
                    <button className="p-2 text-primary hover:bg-primary-light dark:hover:bg-primary/20
                      rounded-lg transition-all duration-150 active:scale-95 cursor-pointer"><Eye size={15} /></button>
                    <button className="p-2 text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-950
                      rounded-lg transition-all duration-150 active:scale-95 cursor-pointer"><CheckCircle size={15} /></button>
                    <button className="p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-950
                      rounded-lg transition-all duration-150 active:scale-95 cursor-pointer"><Ban size={15} /></button>
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
