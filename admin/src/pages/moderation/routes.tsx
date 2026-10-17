import React from 'react';
import { RouteObject } from 'react-router-dom';
import { ModerationPage } from './moderation_page';

export const routes: RouteObject[] = [
  {
    path: 'moderation',
    element: <ModerationPage />,
  },
];
