import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard, Users, FileText, Wallet,
  SlidersHorizontal, Image, HelpCircle, AlertTriangle, LogOut
} from 'lucide-react'
import { useAuth } from '../context/AuthContext'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Bảng điều khiển' },
  { to: '/users', icon: Users, label: 'Người dùng' },
  { to: '/posts', icon: FileText, label: 'Bài viết' },
  { to: '/expenses', icon: Wallet, label: 'Chi phí' },
  { to: '/criteria', icon: SlidersHorizontal, label: 'Tiêu chí' },
  { to: '/media', icon: Image, label: 'Đa phương tiện' },
  { to: '/support', icon: HelpCircle, label: 'Hỗ trợ' },
  { to: '/violations', icon: AlertTriangle, label: 'Vi phạm' },
]

export default function Sidebar() {
  const { user, logout } = useAuth()
  const initials = user?.displayName?.[0]?.toUpperCase() ?? 'A'

  return (
    <aside className="w-56 min-h-screen bg-white border-r border-gray-200 flex flex-col fixed left-0 top-0 bottom-0">
      {/* Logo */}
      <div className="px-5 py-5 border-b border-gray-100">
        <h1 className="text-xl font-bold text-primary">RoomMate</h1>
        <p className="text-xs text-gray-400 uppercase tracking-wider mt-0.5">Bảng quản trị</p>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-0.5">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary-light text-primary border-r-2 border-primary'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`
            }
          >
            <Icon size={18} />
            {label}
          </NavLink>
        ))}
      </nav>

      {/* Bottom */}
      <div className="px-3 pb-4 space-y-2">
        <div className="flex items-center gap-2 px-2 py-2">
          <div className="w-8 h-8 rounded-full bg-primary-light flex items-center justify-center text-primary font-bold text-sm">{initials}</div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-gray-800 truncate">{user?.displayName ?? user?.email}</p>
            <p className="text-xs text-gray-400">Quản trị viên</p>
          </div>
        </div>
        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2 border border-gray-200 text-gray-600 rounded-lg py-2 text-sm font-medium hover:bg-red-50 hover:text-red-600 hover:border-red-200 transition-colors"
        >
          <LogOut size={15} />
          Đăng xuất
        </button>
      </div>
    </aside>
  )
}
