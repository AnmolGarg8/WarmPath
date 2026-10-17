import type { RouteObject } from 'react-router-dom';
import { SeatsPage } from './seats_page';

export const routes: RouteObject[] = [
  {
    path: 'seats',
    element: <SeatsPage />,
  },
];
