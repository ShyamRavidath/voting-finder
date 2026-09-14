// Same artwork as public/favicon.svg and the generated app icons.
export default function LogoMark({ className = 'size-8' }) {
  return (
    <svg viewBox="0 0 64 64" className={className} aria-hidden="true">
      <rect width="64" height="64" rx="14" fill="#2563eb" />
      <rect x="21" y="10" width="22" height="27" rx="2.5" fill="#fff" />
      <path d="m26 23.5 4.5 4.5 8-9" fill="none" stroke="#2563eb" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round" />
      <rect x="12" y="34" width="40" height="20" rx="3.5" fill="#fff" />
      <rect x="19" y="33" width="26" height="3.2" rx="1.6" fill="#1e3a8a" />
      <rect x="12" y="45" width="40" height="3.2" fill="#dc2626" />
    </svg>
  );
}
