import { NavLink } from 'react-router-dom';
import Icon from './Icon';
import LogoMark from './LogoMark';

const NAV_ITEMS = [
  { to: '/', label: 'Home', icon: 'home', end: true },
  { to: '/tools', label: 'Vote', desktopLabel: 'Voting Tools', icon: 'pin' },
  { to: '/news', label: 'News', icon: 'news' },
  { to: '/about', label: 'About', icon: 'info' },
];

export function SiteHeader() {
  return (
    <header className="pt-safe sticky top-0 z-40 border-b border-slate-200 bg-white/95 backdrop-blur-sm">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4 sm:h-16 sm:px-6">
        <NavLink to="/" className="flex items-center gap-2 rounded-lg" aria-label="Vote4U home">
          <LogoMark className="size-8" />
          <span className="text-xl font-bold tracking-tight text-slate-900">
            Vote<span className="text-blue-600">4U</span>
          </span>
        </NavLink>
        <nav aria-label="Main" className="hidden sm:block">
          <ul className="flex items-center gap-1 text-[15px] font-medium">
            {NAV_ITEMS.map(({ to, label, desktopLabel, end }) => (
              <li key={to}>
                <NavLink
                  to={to}
                  end={end}
                  className={({ isActive }) =>
                    `rounded-lg px-3 py-2 transition-colors ${
                      isActive ? 'bg-blue-50 text-blue-700' : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                    }`
                  }
                >
                  {desktopLabel || label}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>
      </div>
    </header>
  );
}

export function TabBar() {
  return (
    <nav
      aria-label="Main"
      className="pb-safe fixed inset-x-0 bottom-0 z-40 border-t border-slate-200 bg-white/95 backdrop-blur-sm sm:hidden"
    >
      <ul className="grid grid-cols-4">
        {NAV_ITEMS.map(({ to, label, icon, end }) => (
          <li key={to}>
            <NavLink
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex min-h-14 flex-col items-center justify-center gap-0.5 text-[11px] font-medium transition-colors ${
                  isActive ? 'text-blue-600' : 'text-slate-500 active:text-slate-900'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  <Icon name={icon} className="size-6" strokeWidth={isActive ? 2.2 : 1.8} />
                  {label}
                </>
              )}
            </NavLink>
          </li>
        ))}
      </ul>
    </nav>
  );
}
