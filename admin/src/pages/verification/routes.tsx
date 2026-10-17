import React from 'react';
import { RouteObject } from 'react-router-dom';
import { VerificationPage } from './VerificationPage';

export const routes: RouteObject[] = [
  {
    path: '/verification',
    element: <VerificationPage />,
  },
];
