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
  pending: 'bg-orange-100 text-orange-600',
  approved: 'bg-green-100 text-green-600',
  flagged: 'bg-red-100 text-red-600',
}
const statusLabel = { pending: 'ĐANG CHỜ', approved: 'ĐÃ DUYỆT', flagged: 'BỊ GẮN CỜ' }

const tabs = ['Tất cả', 'Chờ phê duyệt', 'Đã gắn cờ', 'Đã phê duyệt']

export default function Media() {
  const [activeTab, setActiveTab] = useState('Tất cả')

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Quản lý nội dung</h1>
          <p className="text-gray-500 text-sm mt-1">Xem xét và kiểm duyệt nội dung được tải lên bởi người tìm phòng và chủ nhà.</p>
        </div>
        <div className="flex rounded-lg border border-gray-200 overflow-hidden">
          {tabs.map(t => (
            <button key={t} onClick={() => setActiveTab(t)}
              className={`px-4 py-2 text-sm font-medium transition-colors ${activeTab === t ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 hover:bg-gray-50'}`}>
              {t}
            </button>
          ))}
        </div>
      </div>

      {/* Media grid */}
      <div className="grid grid-cols-4 gap-4">
        {mediaItems.map((item) => (
          <div key={item.id} className={`bg-white rounded-xl border shadow-sm overflow-hidden ${item.status === 'flagged' ? 'border-red-200' : 'border-gray-100'}`}>
            <div className="relative">
              {item.isVideo ? (
                <div className="w-full h-36 bg-gray-800 flex items-center justify-center">
                  <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
                    <Play size={18} className="text-white ml-0.5" />
                  </div>
                </div>
              ) : (
                <img src={item.img} alt="" className="w-full h-36 object-cover" />
              )}
              <span className="absolute top-2 left-2 text-xs font-bold bg-blue-600/90 text-white px-2 py-0.5 rounded">{item.type}</span>
            </div>
            <div className="p-3">
              <div className="flex items-center gap-1.5 mb-1">
                <div className="w-5 h-5 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 text-xs font-bold">{item.user[0]}</div>
                <span className="text-xs font-semibold text-gray-700 truncate">{item.user}</span>
              </div>
              <p className="text-xs text-gray-400">Đã tải {item.time}</p>
              {item.flag && <p className="text-xs text-red-500 font-medium mt-1">{item.flag}</p>}
              <div className="flex items-center gap-1.5 mt-3">
                {item.status === 'approved' ? (
                  <button className="p-1.5 text-gray-400 hover:bg-gray-100 rounded"><RotateCcw size={14} /></button>
                ) : (
                  <>
                    <button className="p-1.5 text-red-500 hover:bg-red-50 rounded border border-red-200"><X size={14} /></button>
                    <button className="p-1.5 text-green-500 hover:bg-green-50 rounded border border-green-200"><Check size={14} /></button>
                  </>
                )}
                {item.status === 'flagged' && (
                  <button className="p-1.5 text-gray-500 hover:bg-gray-100 rounded border border-gray-200"><Info size={14} /></button>
                )}
                <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ml-auto ${statusBadge[item.status]}`}>
                  {statusLabel[item.status]}
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Bottom row */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <h3 className="font-semibold text-gray-800">Nhịp độ kiểm duyệt</h3>
          <p className="text-sm text-gray-500 mt-1">Hoạt động hệ thống hiện đang <span className="text-green-600 font-medium">Ổn định</span>. Có 24 hình ảnh trong hàng đợi cần xem xét thủ công. Nội dung bị gắn cờ đã giảm 12% so với tuần trước.</p>
          <div className="grid grid-cols-3 gap-4 mt-4">
            {[{ label: 'HÀNG ĐỢI', value: '24' }, { label: 'CỜ BÁO', value: '03', red: true }, { label: 'TỔNG CỘNG', value: '1.2k' }].map(s => (
              <div key={s.label} className="text-center">
                <p className="text-xs text-gray-500 font-semibold">{s.label}</p>
                <p className={`text-2xl font-bold mt-1 ${s.red ? 'text-red-500' : 'text-gray-900'}`}>{s.value}</p>
              </div>
            ))}
          </div>
          <div className="mt-4 bg-blue-600 rounded-lg p-3 text-center">
            <p className="text-xs text-blue-100 font-semibold">BỘ LỌC TỰ ĐỘNG</p>
            <p className="text-white font-bold text-sm mt-0.5">Quét nội dung AI đang hoạt động</p>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <div className="bg-blue-600 rounded-xl p-4 text-white mb-4">
            <div className="flex items-center gap-2 mb-1">
              <Zap size={16} />
              <span className="text-sm font-semibold">Công cụ duyệt nhanh</span>
            </div>
            <p className="text-xs text-blue-100">Phê duyệt tất cả các mục đa phương tiện đang chờ mà đã vượt qua kiểm tra tin cậy AI ban đầu (95%+).</p>
            <button className="mt-3 w-full py-2 bg-white text-blue-600 text-sm font-bold rounded-lg hover:bg-blue-50">Thực hiện duyệt hàng loạt</button>
          </div>
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Lịch sử xem xét</p>
            <div className="space-y-2">
              {[
                { text: 'Đã duyệt 12 ảnh phòng', time: '10ph trước', color: 'bg-green-500' },
                { text: 'Đã từ chối video "Living_Tour.mp4"', time: '22ph trước', color: 'bg-red-500' },
                { text: 'Đã duyệt 5 ảnh đại diện', time: '1g trước', color: 'bg-green-500' },
              ].map((h, i) => (
                <div key={i} className="flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${h.color} flex-shrink-0`} />
                  <span className="text-xs text-gray-700 flex-1">{h.text}</span>
                  <span className="text-xs text-gray-400">{h.time}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
