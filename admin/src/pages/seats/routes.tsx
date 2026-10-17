import React from 'react';
import { RouteObject } from 'react-router-dom';
import { SeatsPage } from './SeatsPage';

export const routes: RouteObject[] = [
  {
    path: '/seats',
    element: <SeatsPage />,
  },
];
