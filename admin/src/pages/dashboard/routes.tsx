import React from 'react';
import { RouteObject } from 'react-router-dom';
import { DashboardPage } from './dashboard_page';

export const routes: RouteObject[] = [
  {
    index: true,
    element: <DashboardPage />,
  },
];
