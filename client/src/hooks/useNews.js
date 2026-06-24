import { useState, useEffect } from 'react';
import { api } from '../lib/api';

export function useNews() {
  const [articles, setArticles] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetch = async (forceRefresh = false) => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.getNews(forceRefresh);
      setArticles(data.articles || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetch(); }, []);

  return { articles, loading, error, refresh: () => fetch(true) };
}
