import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query, doc, deleteDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { MapPin, Trash2, Search, FileText, LayoutList } from 'lucide-react'

export default function Posts() {
  const [posts, setPosts] = useState([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)

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
    }
  }

  const filtered = posts.filter(p =>
    (p.title ?? '').toLowerCase().includes(search.toLowerCase()) ||
    (p.location ?? '').toLowerCase().includes(search.toLowerCase()) ||
    (p.province ?? '').toLowerCase().includes(search.toLowerCase())
  )

  const stats = [
    { label: 'Tổng bài đăng', value: posts.length, color: 'text-primary', icon: LayoutList },
    { label: 'Hà Nội', value: posts.filter(p => (p.province ?? '').toLowerCase().includes('hà nội')).length, color: 'text-emerald-600 dark:text-emerald-400', icon: MapPin },
    { label: 'TP. HCM', value: posts.filter(p => (p.province ?? '').toLowerCase().includes('hồ chí minh')).length, color: 'text-violet-600 dark:text-violet-400', icon: MapPin },
  ]

  return (
    <div className="space-y-8">
      <div className="pb-4">
        <h1 className="text-3xl font-extrabold text-gray-900 dark:text-white">Quản lý Bài đăng</h1>
        <p className="text-gray-400 dark:text-gray-500 text-sm font-medium mt-2 mb-2">Xem và quản lý các bài đăng tìm phòng trong hệ thống.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {stats.map(s => (
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
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-800 flex items-center gap-4">
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
          <p className="text-sm font-semibold text-gray-400 dark:text-gray-500 ml-auto">
            <span className="text-gray-700 dark:text-gray-300 font-bold">{filtered.length}</span> bài đăng
          </p>
        </div>

        {loading ? (
          <div className="p-10 text-center text-gray-400 dark:text-gray-500 font-semibold">Đang tải...</div>
        ) : (
          <div className="divide-y divide-gray-50 dark:divide-gray-800">
            {filtered.length === 0 && (
              <div className="p-10 text-center text-sm font-semibold text-gray-400 dark:text-gray-500">Không có bài đăng nào</div>
            )}
            {filtered.map(p => (
              <div key={p.id} className="flex items-center gap-4 px-5 py-4 hover:bg-gray-50 dark:hover:bg-gray-800/60 transition-colors duration-100">
                {p.imageUrls?.[0] || p.imageUrl ? (
                  <img src={p.imageUrls?.[0] ?? p.imageUrl} alt="" className="w-16 h-12 object-cover rounded-xl flex-shrink-0" />
                ) : (
                  <div className="w-16 h-12 bg-gray-100 dark:bg-gray-800 rounded-xl flex items-center justify-center flex-shrink-0">
                    <FileText size={16} className="text-gray-300 dark:text-gray-600" />
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="text-base font-bold text-gray-800 dark:text-gray-100 truncate">{p.title}</p>
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
                <button onClick={() => deletePost(p.id)}
                  className="p-2 text-red-400 hover:bg-red-50 dark:hover:bg-red-950 rounded-xl
                    transition-all duration-150 active:scale-95 cursor-pointer flex-shrink-0">
                  <Trash2 size={15} />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
