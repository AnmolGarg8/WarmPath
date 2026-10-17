import React from 'react';
import { createBrowserRouter, RouterProvider, Navigate, RouteObject } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Layout } from './core/Layout';

const queryClient = new QueryClient();

// Auto-collect all feature routes from pages/*/routes.tsx
const routeModules = import.meta.glob<{ routes: RouteObject[] }>('./pages/*/routes.tsx', {
  eager: true,
});

const pageRoutes: RouteObject[] = [];
for (const path in routeModules) {
  if (routeModules[path].routes) {
    pageRoutes.push(...routeModules[path].routes);
  }
}

const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      {
        index: true,
        element: <Navigate to="/dashboard" replace />,
      },
      ...pageRoutes,
    ],
  },
]);

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  );
}

export default App;
