import { useCallback, useEffect, useRef, useState } from 'react';
import { api } from '../lib/api';

const INITIAL = { status: 'idle', zip: null, locations: [], dataSource: null, place: null, election: null, error: null };

export function usePolling() {
  const [state, setState] = useState(INITIAL);
  const controllerRef = useRef(null);

  useEffect(() => () => controllerRef.current?.abort(), []);

  const search = useCallback(async (zip) => {
    controllerRef.current?.abort();
    const controller = new AbortController();
    controllerRef.current = controller;
    setState((s) => ({ ...s, status: 'loading', zip, error: null }));
    try {
      const data = await api.getPolling(zip, { signal: controller.signal });
      setState({
        status: 'success',
        zip,
        locations: data.locations || [],
        dataSource: data.dataSource,
        place: data.place || null,
        election: data.election || null,
        error: null,
      });
    } catch (err) {
      if (controller.signal.aborted) return;
      setState({ ...INITIAL, status: 'error', zip, error: err.message });
    }
  }, []);

  return { ...state, search };
}
