import React from 'react';
import { RouteObject } from 'react-router-dom';
import { VerificationPage } from './verification_page';

export const routes: RouteObject[] = [
  {
    path: 'verification',
    element: <VerificationPage />,
  },
];
