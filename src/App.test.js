   import { render, screen } from '@testing-library/react';
   import { MemoryRouter } from 'react-router-dom';
   import App from './App';

   // Mock Layout and page components (replace with actual imports if needed)
   jest.mock('./components/Layout', () => ({ children }) => <div data-testid="layout">{children}</div>);
   jest.mock('./pages/Login', () => () => <h1>Login</h1>);
   jest.mock('./pages/Register', () => () => <h1>Register</h1>);
   jest.mock('./pages/UserDashboard', () => () => <h1>Dashboard</h1>);
   jest.mock('./pages/NotFound', () => () => <h1>Not Found</h1>);

   test('renders Login page at /', () => {
     render(
       <MemoryRouter initialEntries={['/']}>
         <App />
       </MemoryRouter>
     );
     const loginElement = screen.getByText(/login/i);
     expect(loginElement).toBeInTheDocument();
     expect(screen.getByTestId('layout')).toBeInTheDocument();
   });

   test('renders Login page at /login', () => {
     render(
       <MemoryRouter initialEntries={['/login']}>
         <App />
       </MemoryRouter>
     );
     const loginElement = screen.getByText(/login/i);
     expect(loginElement).toBeInTheDocument();
     expect(screen.getByTestId('layout')).toBeInTheDocument();
   });

   test('renders Register page at /register', () => {
     render(
       <MemoryRouter initialEntries={['/register']}>
         <App />
       </MemoryRouter>
     );
     const registerElement = screen.getByText(/register/i);
     expect(registerElement).toBeInTheDocument();
     expect(screen.getByTestId('layout')).toBeInTheDocument();
   });

   test('renders UserDashboard page at /dashboard', () => {
     render(
       <MemoryRouter initialEntries={['/dashboard']}>
         <App />
       </MemoryRouter>
     );
     const dashboardElement = screen.getByText(/dashboard/i);
     expect(dashboardElement).toBeInTheDocument();
     expect(screen.getByTestId('layout')).toBeInTheDocument();
   });

   test('renders NotFound page at invalid route', () => {
     render(
       <MemoryRouter initialEntries={['/invalid']}>
         <App />
       </MemoryRouter>
     );
     const notFoundElement = screen.getByText(/not found/i);
     expect(notFoundElement).toBeInTheDocument();
     expect(screen.getByTestId('layout')).toBeInTheDocument();
   });