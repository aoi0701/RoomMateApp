import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard, Users, FileText, Wallet,
  SlidersHorizontal, Image, HelpCircle, AlertTriangle, LogOut,
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
    <aside className="w-60 min-h-screen bg-white dark:bg-gray-900 border-r border-gray-100 dark:border-gray-800
      flex flex-col fixed left-0 top-0 bottom-0 shadow-sm">
      {/* Logo */}
      <div className="px-5 py-5 border-b border-gray-100 dark:border-gray-800">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-primary flex items-center justify-center flex-shrink-0">
            <span className="text-white font-bold text-sm">R</span>
          </div>
          <div>
            <h1 className="text-base font-extrabold text-gray-900 dark:text-white leading-none">RoomMate</h1>
            <p className="text-[10px] text-gray-400 uppercase tracking-widest mt-0.5">Quản trị viên</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition-all duration-150 ease-in-out ${
                isActive
                  ? 'bg-primary-light dark:bg-primary/20 text-primary'
                  : 'text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-800 dark:hover:text-gray-100'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <div className={`w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 transition-all ${
                  isActive
                    ? 'bg-primary text-white'
                    : 'bg-transparent text-gray-400 dark:text-gray-500'
                }`}>
                  <Icon size={15} />
                </div>
                {label}
                {isActive && (
                  <span className="ml-auto w-1.5 h-1.5 rounded-full bg-primary" />
                )}
              </>
            )}
          </NavLink>
        ))}
      </nav>

      {/* Bottom */}
      <div className="px-3 pb-5 space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3">
        <div className="flex items-center gap-2.5 px-3 py-2.5 bg-gray-50 dark:bg-gray-800
          hover:bg-gray-100 dark:hover:bg-gray-700 rounded-xl transition-colors cursor-default">
          <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white font-bold text-xs flex-shrink-0">
            {initials}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-bold text-gray-800 dark:text-gray-100 truncate leading-tight">
              {user?.displayName ?? user?.email}
            </p>
            <p className="text-xs font-medium text-gray-400 mt-0.5">Quản trị viên</p>
          </div>
        </div>
        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2
            border border-gray-200 dark:border-gray-700
            text-gray-500 dark:text-gray-400
            rounded-xl py-2.5 text-sm font-semibold
            hover:bg-red-50 dark:hover:bg-red-950 hover:text-red-500 hover:border-red-200 dark:hover:border-red-800
            active:scale-[0.98] transition-all duration-150 ease-in-out cursor-pointer"
        >
          <LogOut size={14} />
          Đăng xuất
        </button>
      </div>
    </aside>
  )
}
