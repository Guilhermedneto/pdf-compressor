import { render, screen } from '@testing-library/react';
import Home from './Home';

test('renders the main heading', () => {
  render(<Home />);
  const headingElement = screen.getByText(/Comprima seu PDF/i);
  expect(headingElement).toBeInTheDocument();
});
