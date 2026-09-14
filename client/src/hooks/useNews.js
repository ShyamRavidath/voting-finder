import { useCallback, useEffect, useRef, useState } from 'react';
import { api } from '../lib/api';

export function useNews() {
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const controllerRef = useRef(null);

  const load = useCallback(async (forceRefresh = false) => {
    controllerRef.current?.abort();
    const controller = new AbortController();
    controllerRef.current = controller;
    setLoading(true);
    setError(null);
    try {
      const data = await api.getNews(forceRefresh, { signal: controller.signal });
      setArticles(data.articles || []);
    } catch (err) {
      if (controller.signal.aborted) return;
      setError(err.message);
    } finally {
      if (!controller.signal.aborted) setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    return () => controllerRef.current?.abort();
  }, [load]);

  return { articles, loading, error, refresh: () => load(true), retry: () => load(false) };
}
