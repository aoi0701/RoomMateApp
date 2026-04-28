import { Search, Bell, Settings, Sun, Moon } from 'lucide-react'
import { useAuth } from '../context/AuthContext'
import { useTheme } from '../context/ThemeContext'

export default function Header({ placeholder = 'Tìm kiếm...' }) {
  const { user } = useAuth()
  const { dark, toggle } = useTheme()
  const initials = user?.displayName?.[0]?.toUpperCase() ?? 'A'

  return (
    <header className="h-16 bg-white/80 dark:bg-gray-900/80 backdrop-blur border-b border-gray-100 dark:border-gray-800
      flex items-center px-8 gap-4 fixed top-0 left-60 right-0 z-10 shadow-sm">
      <div className="flex-1 relative max-w-sm">
        <Search size={14} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        <input
          type="text"
          placeholder={placeholder}
          className="w-full pl-10 pr-4 py-2 text-sm font-medium
            bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700
            text-gray-800 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500
            rounded-full outline-none focus:border-primary focus:bg-white dark:focus:bg-gray-700
            focus:ring-2 focus:ring-primary/10 transition-all duration-150"
        />
      </div>
      <div className="flex items-center gap-1.5 ml-auto">
        {/* Dark mode toggle */}
        <button
          onClick={toggle}
          title={dark ? 'Chuyển sang Light' : 'Chuyển sang Dark'}
          className="p-2.5 text-gray-400 hover:text-primary hover:bg-primary-light dark:hover:bg-gray-800
            rounded-xl transition-all duration-150 active:scale-95 cursor-pointer"
        >
          {dark ? <Sun size={16} /> : <Moon size={16} />}
        </button>
        <button className="relative p-2.5 text-gray-400 hover:text-primary hover:bg-primary-light
          dark:hover:bg-gray-800 rounded-xl transition-all duration-150 active:scale-95 cursor-pointer">
          <Bell size={16} />
          <span className="absolute top-2 right-2 w-1.5 h-1.5 bg-red-500 rounded-full ring-2 ring-white dark:ring-gray-900" />
        </button>
        <button className="p-2.5 text-gray-400 hover:text-primary hover:bg-primary-light
          dark:hover:bg-gray-800 rounded-xl transition-all duration-150 active:scale-95 cursor-pointer">
          <Settings size={16} />
        </button>
        <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white
          font-bold text-xs ml-1 cursor-pointer hover:ring-2 hover:ring-primary/30 transition-all duration-150">
          {initials}
        </div>
      </div>
    </header>
  )
}
