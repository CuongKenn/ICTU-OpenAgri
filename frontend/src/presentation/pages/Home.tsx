/**
 * Home page component
 */
import { Link } from 'react-router-dom';

export const Home = () => {
  return (
    <div className="home">
      <h1>Welcome to ICTU-OpenAgri</h1>
      <p>An open-source agricultural management platform</p>
      
      <div className="home-actions">
        <Link to="/users" className="btn-primary">
          Manage Users
        </Link>
      </div>
    </div>
  );
};
