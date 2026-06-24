import { NavLink } from 'react-router-dom';

export default function NavBar() {
  const linkClass = ({ isActive }) =>
    `transition hover:text-blue-600 ${isActive ? 'text-blue-600 font-semibold' : ''}`;

  return (
    <nav className="px-6 py-4 flex justify-between items-center bg-white/80 backdrop-blur-md border-b border-slate-200/50 sticky top-0 z-50 shadow-sm">
      <NavLink to="/" className="text-2xl font-bold tracking-tight bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
        Vote4U
      </NavLink>
      <div className="flex gap-8 font-medium text-slate-600">
        <NavLink to="/" end className={linkClass}>Home</NavLink>
        <NavLink to="/about" className={linkClass}>About</NavLink>
        <NavLink to="/tools" className={linkClass}>Tools</NavLink>
        <NavLink to="/news" className={linkClass}>News</NavLink>
      </div>
    </nav>
  );
}
