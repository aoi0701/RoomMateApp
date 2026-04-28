import { useState } from 'react'
import { ChevronDown } from 'lucide-react'

const criteria = [
  { icon: '💰', name: 'Khoảng ngân sách', desc: 'Ngưỡng tương thích về tài chính', weight: 95, tags: ['QUAN TRỌNG', 'BẮT BUỘC'], tagColors: ['bg-orange-50 dark:bg-orange-950 text-orange-600 dark:text-orange-400 ring-1 ring-orange-100 dark:ring-orange-900', 'bg-red-50 dark:bg-red-950 text-red-600 dark:text-red-400 ring-1 ring-red-100 dark:ring-red-900'] },
  { icon: '🚬', name: 'Tình trạng hút thuốc', desc: 'Lọc theo sở thích lối sống', weight: 80, tags: ['KHỚP NHỊ PHÂN'], tagColors: ['bg-violet-50 dark:bg-violet-950 text-violet-600 dark:text-violet-400 ring-1 ring-violet-100 dark:ring-violet-900'] },
  { icon: '🐾', name: 'Thân thiện với thú cưng', desc: 'Sống chung với động vật', weight: 70, tags: ['CHỌN NHIỀU'], tagColors: ['bg-primary-light dark:bg-primary/20 text-primary ring-1 ring-primary/20'] },
  { icon: '🧹', name: 'Mức độ sạch sẽ', desc: 'Kỳ vọng về bảo trì không gian chung', weight: 65, tags: ['PHỔ ĐIỂM'], tagColors: ['bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 ring-1 ring-gray-200 dark:ring-gray-700'] },
  { icon: '👫', name: 'Ưu tiên giới tính', desc: 'Ưu tiên về an ninh và sự thoải mái', weight: 100, tags: ['CỐT YẾU'], tagColors: ['bg-amber-50 dark:bg-amber-950 text-amber-700 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900'] },
]

export default function Criteria() {
  const [weight, setWeight] = useState(95)
  const [enforcement, setEnforcement] = useState('hard')

  return (
    <div className="space-y-8">
      <div className="pb-4">
        <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white">Tiêu chí Phù hợp</h1>
        <p className="text-gray-400 dark:text-gray-500 text-sm font-medium mt-2 mb-2">Tinh chỉnh trọng số và bộ lọc cho thuật toán tìm kiếm người ở ghép.</p>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Criteria list */}
        <div className="col-span-2">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-base font-bold text-gray-800 dark:text-gray-100">Thông số Hoạt động</h2>
            <span className="text-xs font-bold bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400
              ring-1 ring-emerald-100 dark:ring-emerald-900 px-3 py-1 rounded-full">5 ĐANG HOẠT ĐỘNG</span>
          </div>
          <div className="space-y-3">
            {criteria.map((c, i) => (
              <div key={i} className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-4
                flex items-center gap-4 hover:border-primary/30 dark:hover:border-primary/40
                hover:shadow-md cursor-pointer transition-all duration-150">
                <div className="w-11 h-11 rounded-xl bg-primary-light dark:bg-primary/20 flex items-center justify-center text-xl flex-shrink-0">{c.icon}</div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold text-gray-800 dark:text-gray-100">{c.name}</p>
                  <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-0.5">{c.desc}</p>
                  <div className="flex gap-1.5 mt-2 flex-wrap">
                    {c.tags.map((tag, j) => (
                      <span key={j} className={`text-xs font-bold px-2 py-0.5 rounded-full ${c.tagColors[j]}`}>{tag}</span>
                    ))}
                  </div>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className="text-2xl font-extrabold text-primary tabular-nums">{c.weight}%</p>
                  <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 mt-0.5">TRỌNG SỐ</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Config panel */}
        <div className="space-y-4">
          <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm p-5">
            <h3 className="text-base font-bold text-gray-800 dark:text-gray-100 mb-4">Cấu hình Tiêu chí</h3>

            <div className="space-y-4">
              <div>
                <label className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">Nhãn hiển thị</label>
                <input type="text" defaultValue="Khoảng ngân sách"
                  className="w-full mt-1.5 px-3 py-2.5 text-sm font-semibold
                    bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700
                    text-gray-800 dark:text-gray-100 rounded-xl outline-none
                    focus:border-primary focus:ring-2 focus:ring-primary/10 transition-all" />
              </div>

              <div>
                <label className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">Biểu tượng tham chiếu</label>
                <div className="mt-1.5 px-3 py-2.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700
                  rounded-xl text-sm font-semibold text-gray-800 dark:text-gray-100 flex items-center gap-2">
                  💰 <span>payments</span>
                </div>
              </div>

              <div>
                <label className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">Loại thuật toán</label>
                <div className="mt-1.5 relative">
                  <select className="w-full px-3 py-2.5 text-sm font-semibold
                    bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700
                    text-gray-800 dark:text-gray-100 rounded-xl appearance-none outline-none
                    focus:border-primary focus:ring-2 focus:ring-primary/10 transition-all cursor-pointer">
                    <option>Phổ tài chính</option>
                    <option>Nhị phân</option>
                    <option>Phổ điểm</option>
                  </select>
                  <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">Độ nhạy trọng số</label>
                  <span className="text-sm font-extrabold text-primary tabular-nums">{weight}%</span>
                </div>
                <input type="range" min={0} max={100} value={weight} onChange={e => setWeight(Number(e.target.value))}
                  className="w-full accent-primary cursor-pointer" />
                <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-1.5">
                  Xác định mức độ ảnh hưởng của yếu tố này đến điểm số "% Phù hợp" cuối cùng.
                </p>
              </div>

              <div>
                <label className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest block mb-2">Mức độ thực thi</label>
                <div className="space-y-2">
                  {[
                    { value: 'hard', label: 'Lọc cứng (Phải khớp hoàn toàn)' },
                    { value: 'soft', label: 'Khớp mềm (Điểm số có trọng số)' },
                  ].map(opt => (
                    <label key={opt.value} className="flex items-center gap-2.5 cursor-pointer">
                      <input type="radio" name="enforcement" value={opt.value}
                        checked={enforcement === opt.value} onChange={() => setEnforcement(opt.value)}
                        className="accent-primary" />
                      <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">{opt.label}</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>

            <div className="flex gap-2 mt-5">
              <button className="flex-1 py-2.5 bg-primary text-white text-sm font-bold rounded-xl
                hover:bg-primary-dark active:scale-[0.98] transition-all cursor-pointer">Cập nhật Tiêu chí</button>
              <button className="px-4 py-2.5 border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-400
                text-sm font-semibold rounded-xl hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer transition-all">Hủy bỏ</button>
            </div>
          </div>

          <div className="bg-primary-light dark:bg-primary/10 rounded-2xl border border-primary/20 dark:border-primary/30 p-4">
            <div className="flex items-center gap-1.5 mb-2">
              <span className="text-xs font-extrabold text-primary uppercase tracking-widest">🔍 Xem trước tác động</span>
            </div>
            <p className="text-xs font-medium text-gray-600 dark:text-gray-400">
              Việc tăng trọng số này sẽ khiến các kết quả có chênh lệch ngân sách trên 200$ tự động bị giảm ưu tiên 15,4% trong nguồn cấp dữ liệu khám phá.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
