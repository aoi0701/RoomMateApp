import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import Header from './Header'

export default function Layout() {
  return (
    <div className="flex min-h-screen bg-gray-50 dark:bg-gray-950">
      <Sidebar />
      <div className="flex-1 ml-60">
        <Header />
        <main className="pt-24 p-8">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
