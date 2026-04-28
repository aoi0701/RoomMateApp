import { useState } from 'react'
import { X, Check, RotateCcw, Play, Info, Zap } from 'lucide-react'

const mediaItems = [
  { id: 1, type: 'XEM TRƯỚC PHÒNG', user: 'Elena Rodriguez', time: '2 giờ trước', status: 'pending', flag: null, img: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=200&h=160&fit=crop' },
  { id: 2, type: 'NỘI DUNG VIDEO', user: 'Julian Weber', time: '5 giờ trước', status: 'flagged', flag: 'Bị gắn cờ: Chất lượng thấp / Nhòe', isVideo: true, img: '' },
  { id: 3, type: 'ẢNH ĐẠI DIỆN', user: 'Alex Thompson', time: '1 ngày trước', status: 'approved', flag: null, img: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=160&fit=crop' },
  { id: 4, type: 'KHU VỰC CHUNG', user: 'Sarah Jenkins', time: '4 giờ trước', status: 'pending', flag: null, img: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=160&fit=crop' },
  { id: 5, type: 'XEM TRƯỚC PHÒNG', user: 'Markus Aurelius', time: '2 ngày trước', status: 'approved', flag: null, img: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=200&h=160&fit=crop' },
  { id: 6, type: 'CẢNH QUAN', user: 'Claire Danes', time: '6 giờ trước', status: 'pending', flag: null, img: 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=200&h=160&fit=crop' },
]

const statusBadge = {
  pending:  'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900',
  approved: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-100 dark:ring-emerald-900',
  flagged:  'bg-red-50 dark:bg-red-950 text-red-600 dark:text-red-400 ring-1 ring-red-100 dark:ring-red-900',
}
const statusLabel = { pending: 'ĐANG CHỜ', approved: 'ĐÃ DUYỆT', flagged: 'BỊ GẮN CỜ' }

const tabs = ['Tất cả', 'Chờ phê duyệt', 'Đã gắn cờ', 'Đã phê duyệt']

export default function Media() {
  const [activeTab, setActiveTab] = useState('Tất cả')

  return (
    <div className="space-y-8">
      <div className="flex items-start justify-between pb-4">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white">Quản lý Nội dung</h1>
          <p className="text-gray-400 dark:text-gray-500 text-sm font-medium mt-2 mb-2">Xem xét và kiểm duyệt nội dung được tải lên bởi người tìm phòng và chủ nhà.</p>
        </div>
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

      <div className="grid grid-cols-4 gap-4">
        {mediaItems.map((item) => (
          <div key={item.id} className={`bg-white dark:bg-gray-900 rounded-2xl border shadow-sm overflow-hidden
            hover:shadow-md hover:-translate-y-0.5 transition-all duration-200
            ${item.status === 'flagged' ? 'border-red-200 dark:border-red-900' : 'border-gray-100 dark:border-gray-800'}`}>
            <div className="relative">
              {item.isVideo ? (
                <div className="w-full h-36 bg-gray-800 dark:bg-gray-950 flex items-center justify-center">
                  <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
                    <Play size={18} className="text-white ml-0.5" />
                  </div>
                </div>
              ) : (
                <img src={item.img} alt="" className="w-full h-36 object-cover" />
              )}
              <span className="absolute top-2 left-2 text-xs font-extrabold bg-primary/90 text-white px-2 py-0.5 rounded-lg">
                {item.type}
              </span>
            </div>
            <div className="p-3">
              <div className="flex items-center gap-1.5 mb-1">
                <div className="w-5 h-5 rounded-full bg-primary-light dark:bg-primary/20
                  flex items-center justify-center text-primary text-xs font-extrabold">{item.user[0]}</div>
                <span className="text-xs font-bold text-gray-700 dark:text-gray-300 truncate">{item.user}</span>
              </div>
              <p className="text-xs font-medium text-gray-400 dark:text-gray-500">Đã tải {item.time}</p>
              {item.flag && <p className="text-xs font-bold text-red-500 mt-1">{item.flag}</p>}
              <div className="flex items-center gap-1.5 mt-3">
                {item.status === 'approved' ? (
                  <button className="p-1.5 text-gray-400 dark:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800
                    rounded-lg cursor-pointer transition-all"><RotateCcw size={14} /></button>
                ) : (
                  <>
                    <button className="p-1.5 text-red-500 hover:bg-red-50 dark:hover:bg-red-950
                      rounded-lg border border-red-200 dark:border-red-900 cursor-pointer active:scale-95 transition-all"><X size={14} /></button>
                    <button className="p-1.5 text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-950
                      rounded-lg border border-emerald-200 dark:border-emerald-900 cursor-pointer active:scale-95 transition-all"><Check size={14} /></button>
                  </>
                )}
                {item.status === 'flagged' && (
                  <button className="p-1.5 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800
                    rounded-lg border border-gray-200 dark:border-gray-700 cursor-pointer transition-all"><Info size={14} /></button>
                )}
                <span className={`text-xs font-bold px-2 py-0.5 rounded-full ml-auto ${statusBadge[item.status]}`}>
                  {statusLabel[item.status]}
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5">
          <h3 className="text-base font-bold text-gray-800 dark:text-gray-100">Nhịp độ kiểm duyệt</h3>
          <p className="text-sm font-medium text-gray-500 dark:text-gray-400 mt-2">
            Hoạt động hệ thống hiện đang <span className="text-emerald-600 dark:text-emerald-400 font-bold">Ổn định</span>.
            Có 24 hình ảnh trong hàng đợi cần xem xét thủ công.
          </p>
          <div className="grid grid-cols-3 gap-4 mt-4">
            {[
              { label: 'HÀNG ĐỢI', value: '24', color: 'text-gray-800 dark:text-gray-100' },
              { label: 'CỜ BÁO', value: '03', color: 'text-red-500' },
              { label: 'TỔNG CỘNG', value: '1.2k', color: 'text-gray-800 dark:text-gray-100' },
            ].map(s => (
              <div key={s.label} className="text-center">
                <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500">{s.label}</p>
                <p className={`text-2xl font-extrabold mt-1 tabular-nums ${s.color}`}>{s.value}</p>
              </div>
            ))}
          </div>
          <div className="mt-4 bg-primary rounded-xl p-3 text-center">
            <p className="text-xs font-extrabold text-blue-100 tracking-widest">BỘ LỌC TỰ ĐỘNG</p>
            <p className="text-white font-bold text-sm mt-0.5">Quét nội dung AI đang hoạt động</p>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5">
          <div className="bg-primary rounded-xl p-4 text-white mb-4">
            <div className="flex items-center gap-2 mb-1">
              <Zap size={16} />
              <span className="text-sm font-bold">Công cụ duyệt nhanh</span>
            </div>
            <p className="text-xs text-blue-100 font-medium">Phê duyệt tất cả các mục đa phương tiện đang chờ mà đã vượt qua kiểm tra tin cậy AI ban đầu (95%+).</p>
            <button className="mt-3 w-full py-2 bg-white text-primary text-sm font-extrabold rounded-xl
              hover:bg-blue-50 active:scale-[0.98] transition-all cursor-pointer">Thực hiện duyệt hàng loạt</button>
          </div>
          <div>
            <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest mb-3">Lịch sử xem xét</p>
            <div className="space-y-2">
              {[
                { text: 'Đã duyệt 12 ảnh phòng', time: '10ph trước', color: 'bg-emerald-500' },
                { text: 'Đã từ chối video "Living_Tour.mp4"', time: '22ph trước', color: 'bg-red-500' },
                { text: 'Đã duyệt 5 ảnh đại diện', time: '1g trước', color: 'bg-emerald-500' },
              ].map((h, i) => (
                <div key={i} className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${h.color} flex-shrink-0`} />
                  <span className="text-xs font-semibold text-gray-700 dark:text-gray-300 flex-1">{h.text}</span>
                  <span className="text-xs font-medium text-gray-400 dark:text-gray-500">{h.time}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
