import React from 'react';
import { RouteObject } from 'react-router-dom';
import { DashboardPage } from './DashboardPage';

export const routes: RouteObject[] = [
  {
    path: '/dashboard',
    element: <DashboardPage />,
  },
];
