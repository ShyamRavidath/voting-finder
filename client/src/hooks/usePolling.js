import { useState } from 'react';
import { api } from '../lib/api';

export function usePolling() {
  const [locations, setLocations] = useState([]);
  const [dataSource, setDataSource] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const search = async (zip) => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.getPolling(zip);
      setLocations(data.locations || []);
      setDataSource(data.dataSource);
    } catch (err) {
      setError(err.message);
      setLocations([]);
    } finally {
      setLoading(false);
    }
  };

  return { locations, dataSource, loading, error, search };
}
