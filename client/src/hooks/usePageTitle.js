import { useEffect } from 'react';

export function usePageTitle(title) {
  useEffect(() => {
    document.title = title ? `${title} · Vote4U` : 'Vote4U · Find your polling place, follow the 2028 race';
  }, [title]);
}
