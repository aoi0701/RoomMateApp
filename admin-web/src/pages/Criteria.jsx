import { useState } from 'react'
import { ChevronDown } from 'lucide-react'

const criteria = [
  { icon: '💰', name: 'Khoảng ngân sách', desc: 'Ngưỡng tương thích về tài chính', weight: 95, tags: ['QUAN TRỌNG', 'BẮT BUỘC'], tagColors: ['bg-orange-100 text-orange-600', 'bg-red-100 text-red-600'] },
  { icon: '🚬', name: 'Tình trạng hút thuốc', desc: 'Lọc theo sở thích lối sống', weight: 80, tags: ['KHỚP NHỊ PHÂN'], tagColors: ['bg-purple-100 text-purple-600'] },
  { icon: '🐾', name: 'Thân thiện với thú cưng', desc: 'Sống chung với động vật', weight: 70, tags: ['CHỌN NHIỀU'], tagColors: ['bg-blue-100 text-blue-600'] },
  { icon: '🧹', name: 'Mức độ sạch sẽ', desc: 'Kỳ vọng về bảo trì không gian chung', weight: 65, tags: ['PHỔ ĐIỂM'], tagColors: ['bg-gray-100 text-gray-600'] },
  { icon: '👫', name: 'Ưu tiên giới tính', desc: 'Ưu tiên về an ninh và sự thoải mái', weight: 100, tags: ['CỐT YẾU'], tagColors: ['bg-yellow-100 text-yellow-700'] },
]

export default function Criteria() {
  const [weight, setWeight] = useState(95)
  const [enforcement, setEnforcement] = useState('hard')

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Tiêu chí Phù hợp</h1>
        <p className="text-gray-500 text-sm mt-1">Tinh chỉnh trọng số và bộ lọc cho thuật toán tìm kiếm người ở ghép.</p>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Criteria list */}
        <div className="col-span-2">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-gray-800">Thông số Hoạt động</h2>
            <span className="text-xs bg-green-100 text-green-700 font-semibold px-3 py-1 rounded-full">5 ĐANG HOẠT ĐỘNG</span>
          </div>
          <div className="space-y-3">
            {criteria.map((c, i) => (
              <div key={i} className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 flex items-center gap-4 hover:border-blue-200 cursor-pointer transition-colors">
                <div className="w-11 h-11 rounded-xl bg-blue-50 flex items-center justify-center text-xl flex-shrink-0">{c.icon}</div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-gray-800">{c.name}</p>
                  <p className="text-xs text-gray-500">{c.desc}</p>
                  <div className="flex gap-1.5 mt-1.5 flex-wrap">
                    {c.tags.map((tag, j) => (
                      <span key={j} className={`text-xs font-semibold px-2 py-0.5 rounded-full ${c.tagColors[j]}`}>{tag}</span>
                    ))}
                  </div>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className="text-2xl font-bold text-blue-600">{c.weight}%</p>
                  <p className="text-xs text-gray-400">TRỌNG SỐ</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Config panel */}
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h3 className="font-semibold text-gray-800 mb-4">Cấu hình Tiêu chí</h3>

            <div className="space-y-4">
              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Nhãn hiển thị</label>
                <input type="text" defaultValue="Khoảng ngân sách" className="w-full mt-1.5 px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm outline-none focus:border-blue-400" />
              </div>

              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Biểu tượng tham chiếu</label>
                <div className="mt-1.5 flex gap-2">
                  <div className="flex-1 px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm flex items-center gap-2">
                    💰 <span>payments</span>
                  </div>
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Loại thuật toán</label>
                <div className="mt-1.5 relative">
                  <select className="w-full px-3 py-2.5 bg-gray-50 border border-gray-200 rounded-lg text-sm appearance-none outline-none focus:border-blue-400">
                    <option>Phổ tài chính</option>
                    <option>Nhị phân</option>
                    <option>Phổ điểm</option>
                  </select>
                  <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Độ nhạy trọng số</label>
                  <span className="text-sm font-bold text-blue-600">{weight}%</span>
                </div>
                <input type="range" min={0} max={100} value={weight} onChange={e => setWeight(Number(e.target.value))}
                  className="w-full accent-blue-600" />
                <p className="text-xs text-gray-400 mt-1">Xác định mức độ ảnh hưởng của yếu tố này đến điểm số "% Phù hợp" cuối cùng.</p>
              </div>

              <div>
                <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-2">Mức độ thực thi</label>
                <div className="space-y-2">
                  {[
                    { value: 'hard', label: 'Lọc cứng (Phải khớp hoàn toàn)' },
                    { value: 'soft', label: 'Khớp mềm (Điểm số có trọng số)' },
                  ].map(opt => (
                    <label key={opt.value} className="flex items-center gap-2.5 cursor-pointer">
                      <input type="radio" name="enforcement" value={opt.value} checked={enforcement === opt.value} onChange={() => setEnforcement(opt.value)} className="accent-blue-600" />
                      <span className="text-sm text-gray-700">{opt.label}</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex gap-2 mt-5">
              <button className="flex-1 py-2.5 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700">Cập nhật Tiêu chí</button>
              <button className="px-4 py-2.5 border border-gray-200 text-gray-600 text-sm font-semibold rounded-lg hover:bg-gray-50">Hủy bỏ</button>
            </div>
          </div>

          {/* Preview impact */}
          <div className="bg-blue-50 rounded-xl border border-blue-100 p-4">
            <div className="flex items-center gap-1.5 mb-2">
              <span className="text-blue-600 text-xs">🔍</span>
              <span className="text-xs font-semibold text-blue-600 uppercase tracking-wider">Xem trước tác động</span>
            </div>
            <p className="text-xs text-gray-600">Việc tăng trọng số này sẽ khiến các kết quả có chênh lệch ngân sách trên 200$ tự động bị giảm ưu tiên 15,4% trong nguồn cấp dữ liệu khám phá toàn cầu.</p>
          </div>
        </div>
      </div>
    </div>
  )
}
