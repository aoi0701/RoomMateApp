import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query, doc, deleteDoc, updateDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { MapPin, Trash2, Search, FileText, LayoutList, Eye, EyeOff, X, EyeIcon } from 'lucide-react'

const TABS = ['Tất cả', 'Hiển thị', 'Đã ẩn']

function timeStr(ts) {
  if (!ts) return '—'
  return ts.toDate().toLocaleString('vi-VN')
}

export default function Posts() {
  const [posts, setPosts] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('Tất cả')
  const [detail, setDetail] = useState(null)

  useEffect(() => {
    const q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'))
    const unsub = onSnapshot(q, snap => {
      setPosts(snap.docs.map(d => ({ id: d.id, ...d.data() })))
      setLoading(false)
    })
    return unsub
  }, [])

  const deletePost = async (id) => {
    if (confirm('Bạn có chắc muốn xóa bài đăng này?')) {
      await deleteDoc(doc(db, 'posts', id))
      setDetail(null)
    }
  }

  const toggleHide = async (p) => {
    await updateDoc(doc(db, 'posts', p.id), { isHidden: !p.isHidden })
    setDetail(d => d ? { ...d, isHidden: !d.isHidden } : null)
  }

  const filtered = posts
    .filter(p => {
      if (activeTab === 'Hiển thị') return !p.isHidden
      if (activeTab === 'Đã ẩn') return !!p.isHidden
      return true
    })
    .filter(p =>
      (p.title ?? '').toLowerCase().includes(search.toLowerCase()) ||
      (p.location ?? '').toLowerCase().includes(search.toLowerCase()) ||
      (p.province ?? '').toLowerCase().includes(search.toLowerCase())
    )

  const statCards = [
    { label: 'Tổng bài đăng', value: posts.length, color: 'text-primary', icon: LayoutList },
    { label: 'Đang hiển thị', value: posts.filter(p => !p.isHidden).length, color: 'text-emerald-600 dark:text-emerald-400', icon: EyeIcon },
    { label: 'Đã ẩn', value: posts.filter(p => !!p.isHidden).length, color: 'text-amber-600 dark:text-amber-400', icon: EyeOff },
    { label: 'Hà Nội', value: posts.filter(p => (p.province ?? '').toLowerCase().includes('hà nội')).length, color: 'text-violet-600 dark:text-violet-400', icon: MapPin },
  ]

  return (
    <div className="space-y-6">
      <div className="pb-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Quản lý Bài đăng</h1>
        <p className="text-gray-400 dark:text-gray-500 text-sm mt-1">Xem và quản lý các bài đăng tìm phòng trong hệ thống.</p>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {statCards.map(s => (
          <div key={s.label} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-5
            hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 cursor-default">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest">{s.label}</p>
              <s.icon size={15} className={s.color} />
            </div>
            <p className={`text-4xl font-extrabold ${s.color} tabular-nums`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-700 flex items-center gap-4">
          <div className="relative flex-1 max-w-sm">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Tìm tiêu đề hoặc địa chỉ..."
              className="w-full pl-9 pr-3 py-2 text-sm font-medium
                bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700
                text-gray-800 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500
                rounded-xl outline-none focus:border-primary focus:ring-2 focus:ring-primary/10 transition-all duration-150"
            />
          </div>
          <div className="flex gap-1 bg-gray-50 dark:bg-gray-800 border border-gray-100 dark:border-gray-700 rounded-xl p-1">
            {TABS.map(t => (
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
          <p className="text-sm font-semibold text-gray-400 dark:text-gray-500 ml-auto">
            <span className="text-gray-700 dark:text-gray-300 font-bold">{filtered.length}</span> bài đăng
          </p>
        </div>

        {loading ? (
          <div className="p-10 text-center text-gray-400 dark:text-gray-500 font-semibold">Đang tải...</div>
        ) : (
          <div className="divide-y divide-gray-50 dark:divide-gray-700">
            {filtered.length === 0 && (
              <div className="p-10 text-center text-sm font-semibold text-gray-400 dark:text-gray-500">Không có bài đăng nào</div>
            )}
            {filtered.map(p => (
              <div key={p.id}
                onClick={() => setDetail(p)}
                className={`flex items-center gap-4 px-5 py-4 cursor-pointer transition-colors duration-100
                  hover:bg-gray-50 dark:hover:bg-gray-700/60 ${p.isHidden ? 'opacity-50' : ''}`}>
                {p.imageUrls?.[0] || p.imageUrl ? (
                  <img src={p.imageUrls?.[0] ?? p.imageUrl} alt="" className="w-16 h-12 object-cover rounded-xl flex-shrink-0" />
                ) : (
                  <div className="w-16 h-12 bg-gray-100 dark:bg-gray-800 rounded-xl flex items-center justify-center flex-shrink-0">
                    <FileText size={16} className="text-gray-300 dark:text-gray-600" />
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-base font-bold text-gray-800 dark:text-gray-100 truncate">{p.title}</p>
                    {p.isHidden && (
                      <span className="text-xs font-bold px-2 py-0.5 rounded-full bg-amber-50 dark:bg-amber-950
                        text-amber-600 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900 flex-shrink-0">Đã ẩn</span>
                    )}
                  </div>
                  <div className="flex items-center gap-1 mt-0.5">
                    <MapPin size={11} className="text-gray-400 flex-shrink-0" />
                    <p className="text-sm font-medium text-gray-400 dark:text-gray-500 truncate">
                      {p.location ?? `${p.district ?? ''}, ${p.province ?? ''}`}
                    </p>
                  </div>
                  <div className="flex items-center gap-3 mt-1.5">
                    <span className="text-sm font-bold text-primary">{p.price?.toLocaleString('vi-VN')}đ/tháng</span>
                    {p.area && <span className="text-sm font-semibold text-gray-400 dark:text-gray-500">{p.area}m²</span>}
                    {p.roomType && <span className="text-sm font-semibold text-gray-400 dark:text-gray-500">{p.roomType}</span>}
                  </div>
                </div>
                <div className="flex gap-1 flex-shrink-0" onClick={e => e.stopPropagation()}>
                  <button onClick={() => toggleHide(p)}
                    title={p.isHidden ? 'Hiện bài' : 'Ẩn bài'}
                    className="p-2 text-amber-500 hover:bg-amber-50 dark:hover:bg-amber-950 rounded-xl
                      transition-all duration-150 active:scale-95 cursor-pointer">
                    {p.isHidden ? <Eye size={15} /> : <EyeOff size={15} />}
                  </button>
                  <button onClick={() => deletePost(p.id)}
                    title="Xóa bài"
                    className="p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-950 rounded-xl
                      transition-all duration-150 active:scale-95 cursor-pointer">
                    <Trash2 size={15} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Detail modal */}
      {detail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setDetail(null)}>
          <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700
            shadow-2xl w-full max-w-lg p-6 space-y-4 max-h-[90vh] overflow-y-auto"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">Chi tiết bài đăng</h3>
              <button onClick={() => setDetail(null)}
                className="p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">
                <X size={16} />
              </button>
            </div>

            {(detail.imageUrls?.[0] ?? detail.imageUrl) && (
              <img src={detail.imageUrls?.[0] ?? detail.imageUrl} alt=""
                className="w-full h-48 object-cover rounded-xl" />
            )}

            <div className="space-y-2 text-sm">
              <Row label="Tiêu đề"    value={detail.title ?? '—'} />
              <Row label="Giá"        value={detail.price ? `${detail.price.toLocaleString('vi-VN')}đ/tháng` : '—'} />
              <Row label="Địa chỉ"   value={detail.location ?? (`${detail.district ?? ''} ${detail.province ?? ''}`.trim() || '—')} />
              <Row label="Diện tích"  value={detail.area ? `${detail.area}m²` : '—'} />
              <Row label="Loại phòng" value={detail.roomType ?? '—'} />
              <Row label="Mô tả"      value={detail.description ?? '—'} />
              <Row label="Trạng thái" value={detail.isHidden ? 'Đã ẩn' : 'Hiển thị'} />
              <Row label="Ngày đăng"  value={timeStr(detail.createdAt)} />
            </div>

            <div className="flex gap-2 pt-2">
              <button onClick={() => toggleHide(detail)}
                className={`flex-1 py-2 rounded-xl text-sm font-semibold transition-all cursor-pointer
                  ${detail.isHidden
                    ? 'bg-emerald-500 text-white hover:bg-emerald-600'
                    : 'border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                  }`}>
                {detail.isHidden ? 'Hiện bài' : 'Ẩn bài'}
              </button>
              <button onClick={() => deletePost(detail.id)}
                className="flex-1 py-2 rounded-xl text-sm font-semibold bg-red-500 text-white hover:bg-red-600 transition-all cursor-pointer">
                Xóa bài
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function Row({ label, value }) {
  return (
    <div className="flex gap-2">
      <span className="w-28 flex-shrink-0 text-gray-400 dark:text-gray-500 font-medium">{label}:</span>
      <span className="text-gray-800 dark:text-gray-100 font-semibold break-all">{value}</span>
    </div>
  )
}
