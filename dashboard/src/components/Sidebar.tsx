'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/auth';

const nav = [
  { href: '/dashboard', label: 'Übersicht', icon: '⊞' },
  { href: '/dashboard/events', label: 'Events', icon: '◈' },
  { href: '/dashboard/participants', label: 'Teilnehmer', icon: '◉' },
  { href: '/dashboard/points', label: 'Punkte', icon: '⊕' },
  { href: '/dashboard/rewards', label: 'Prämien', icon: '★' },
];

export function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();

  return (
    <aside className="flex h-screen w-56 flex-col border-r border-gray-200 bg-white">
      <div className="border-b border-gray-200 px-4 py-4">
        <Link href="/dashboard" className="text-xl font-extrabold tracking-tight text-brand-500">
          QuestBand
        </Link>
      </div>

      <nav className="flex-1 space-y-0.5 px-2 py-3">
        {nav.map((item) => {
          const active = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href));
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium transition ${
                active
                  ? 'bg-brand-50 text-brand-700'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
              }`}
            >
              <span className="text-base">{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-gray-200 px-4 py-3">
        <div className="text-xs text-gray-500">{user?.name || user?.role}</div>
        <button
          onClick={logout}
          className="mt-1 text-xs font-medium text-gray-400 hover:text-red-600"
        >
          Abmelden
        </button>
      </div>
    </aside>
  );
}
