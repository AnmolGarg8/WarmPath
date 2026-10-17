import React from 'react';
import { createBrowserRouter, RouterProvider, RouteObject } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AdminLayout } from './core/layout';

const queryClient = new QueryClient();

// Auto-collect all feature routes from pages/*/routes.tsx
const routeModules = import.meta.glob<{ routes: RouteObject[] }>('./pages/*/routes.tsx', { eager: true });
const collectedRoutes: RouteObject[] = Object.values(routeModules).flatMap((mod) => mod.routes);

const router = createBrowserRouter([
  {
    path: '/',
    element: <AdminLayout />,
    children: collectedRoutes,
  },
]);

export const App: React.FC = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  );
};
