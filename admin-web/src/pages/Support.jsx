import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query, doc, updateDoc } from 'firebase/firestore'
import { db } from '../firebase'
import { ChevronLeft, ChevronRight, X } from 'lucide-react'

const PRIORITY = {
  high:   { label: 'ƯU TIÊN CAO', cls: 'bg-red-50 dark:bg-red-950 text-red-600 dark:text-red-400 ring-1 ring-red-100 dark:ring-red-900' },
  medium: { label: 'TRUNG BÌNH',  cls: 'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400 ring-1 ring-amber-100 dark:ring-amber-900' },
  low:    { label: 'ƯU TIÊN THẤP', cls: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400 ring-1 ring-emerald-100 dark:ring-emerald-900' },
}

const STATUS = {
  open:     { label: 'MỞ',           cls: 'bg-primary-light dark:bg-primary/20 text-primary' },
  pending:  { label: 'ĐANG CHỜ',     cls: 'bg-amber-50 dark:bg-amber-950 text-amber-600 dark:text-amber-400' },
  resolved: { label: 'ĐÃ GIẢI QUYẾT', cls: 'bg-emerald-50 dark:bg-emerald-950 text-emerald-600 dark:text-emerald-400' },
}

const PAGE_SIZE = 10

function timeAgo(ts) {
  if (!ts) return ''
  const diff = Math.floor((Date.now() - ts.toDate().getTime()) / 1000)
  if (diff < 60) return `${diff} giây trước`
  if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`
  if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`
  return `${Math.floor(diff / 86400)} ngày trước`
}

export default function Support() {
  const [tickets, setTickets] = useState([])
  const [detail, setDetail] = useState(null)
  const [page, setPage] = useState(0)

  useEffect(() => {
    const q = query(collection(db, 'support_tickets'), orderBy('createdAt', 'desc'))
    return onSnapshot(q, snap => {
      setTickets(snap.docs.map(d => ({ id: d.id, ...d.data() })))
      setPage(0)
    })
  }, [])

  const open     = tickets.filter(t => t.status === 'open').length
  const pending  = tickets.filter(t => t.status === 'pending').length
  const resolved = tickets.filter(t => t.status === 'resolved').length

  const totalPages = Math.ceil(tickets.length / PAGE_SIZE)
  const paged = tickets.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE)

  async function setStatus(id, status) {
    await updateDoc(doc(db, 'support_tickets', id), { status })
  }

  return (
    <div className="space-y-6">
      <div className="pb-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Trung tâm Hỗ trợ</h1>
        <p className="text-sm text-gray-400 dark:text-gray-500 mt-1">Quản lý thắc mắc của người dùng và giải quyết vé hỗ trợ.</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Vé đang mở',    value: open,     color: 'text-primary' },
          { label: 'Đang chờ',       value: pending,  color: 'text-amber-600 dark:text-amber-400' },
          { label: 'Đã giải quyết', value: resolved, color: 'text-emerald-600 dark:text-emerald-400' },
        ].map(s => (
          <div key={s.label} className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700 p-5
            hover:shadow-md hover:-translate-y-0.5 transition-all duration-200 cursor-default">
            <p className="text-xs font-extrabold text-gray-400 dark:text-gray-500 uppercase tracking-widest mb-3">{s.label}</p>
            <p className={`text-4xl font-extrabold tabular-nums ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700">
        <div className="px-5 py-4 border-b border-gray-100 dark:border-gray-700">
          <h2 className="text-base font-bold text-gray-800 dark:text-gray-100">Yêu cầu hỗ trợ</h2>
        </div>

        {tickets.length === 0 ? (
          <div className="px-5 py-16 text-center text-gray-400 dark:text-gray-500 text-sm">
            Chưa có yêu cầu hỗ trợ nào
          </div>
        ) : (
          <>
            <div className="divide-y divide-gray-50 dark:divide-gray-700">
              {paged.map(t => {
                const pr = PRIORITY[t.priority] ?? PRIORITY.medium
                const st = STATUS[t.status] ?? STATUS.open
                return (
                  <div key={t.id}
                    onClick={() => setDetail(t)}
                    className="px-5 py-4 hover:bg-gray-50 dark:hover:bg-gray-700/60 transition-colors duration-100 cursor-pointer">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex gap-3 flex-1 min-w-0">
                        <div className="w-9 h-9 rounded-xl bg-primary-light dark:bg-primary/20 flex items-center justify-center
                          flex-shrink-0 text-primary text-xs font-extrabold">
                          {(t.category ?? 'H')[0].toUpperCase()}
                        </div>
                        <div className="min-w-0">
                          <div className="flex items-center gap-2 mb-0.5">
                            <span className="text-xs font-extrabold text-primary uppercase">{t.category ?? 'Hỗ trợ'}</span>
                            <span className="text-xs font-semibold text-gray-400 dark:text-gray-500">· {t.userName ?? t.userId ?? '—'}</span>
                          </div>
                          <p className="text-sm font-bold text-gray-800 dark:text-gray-100 truncate">{t.title}</p>
                          <p className="text-xs font-medium text-gray-400 dark:text-gray-500 mt-0.5 truncate">{t.description}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 flex-shrink-0">
                        <div className="text-right">
                          <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${pr.cls}`}>{pr.label}</span>
                          <p className="text-xs font-semibold text-gray-400 dark:text-gray-500 mt-1">{timeAgo(t.createdAt)}</p>
                        </div>
                        <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${st.cls}`}>{st.label}</span>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>

            <div className="px-5 py-3 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
              <p className="text-sm font-semibold text-gray-400 dark:text-gray-500">
                Hiển thị {paged.length} trên {tickets.length} vé
              </p>
              <div className="flex gap-1">
                <button disabled={page === 0} onClick={() => setPage(p => p - 1)}
                  className="p-1.5 border border-gray-200 dark:border-gray-700 rounded-xl text-gray-500 dark:text-gray-400
                    hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-40 cursor-pointer transition-all">
                  <ChevronLeft size={16} />
                </button>
                <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)}
                  className="p-1.5 border border-gray-200 dark:border-gray-700 rounded-xl text-gray-500 dark:text-gray-400
                    hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-40 cursor-pointer transition-all">
                  <ChevronRight size={16} />
                </button>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Detail modal */}
      {detail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm"
          onClick={() => setDetail(null)}>
          <div className="bg-white dark:bg-gray-800 rounded-2xl border border-gray-200 dark:border-gray-700
            shadow-2xl w-full max-w-md p-6 space-y-4"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold text-gray-900 dark:text-white">Chi tiết yêu cầu</h3>
              <button onClick={() => setDetail(null)}
                className="p-1.5 rounded-lg text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer">
                <X size={16} />
              </button>
            </div>
            <div className="space-y-2 text-sm">
              <Row label="Người gửi"  value={detail.userName ?? detail.userId ?? '—'} />
              <Row label="Danh mục"   value={detail.category ?? '—'} />
              <Row label="Tiêu đề"    value={detail.title ?? '—'} />
              <Row label="Mô tả"      value={detail.description ?? '—'} />
              <Row label="Ưu tiên"    value={PRIORITY[detail.priority]?.label ?? '—'} />
              <Row label="Trạng thái" value={STATUS[detail.status]?.label ?? '—'} />
              <Row label="Thời gian"  value={detail.createdAt?.toDate().toLocaleString('vi-VN') ?? '—'} />
            </div>
            <div className="flex gap-2 pt-2">
              {detail.status !== 'pending' && (
                <button onClick={() => { setStatus(detail.id, 'pending'); setDetail(d => ({ ...d, status: 'pending' })) }}
                  className="flex-1 py-2 rounded-xl text-sm font-semibold border border-gray-200 dark:border-gray-700
                    text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition-all cursor-pointer">
                  Đang chờ
                </button>
              )}
              {detail.status !== 'resolved' && (
                <button onClick={() => { setStatus(detail.id, 'resolved'); setDetail(null) }}
                  className="flex-1 py-2 rounded-xl text-sm font-semibold bg-emerald-500 text-white
                    hover:bg-emerald-600 transition-all cursor-pointer">
                  Giải quyết
                </button>
              )}
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
