/**
 * User List Component
 */
import { useEffect } from 'react';
import { useUserStore } from '../stores/useUserStore';
import { useNavigate } from 'react-router-dom';

export const UserList = () => {
  const { users, loading, error, fetchUsers, deleteUser } = useUserStore();
  const navigate = useNavigate();

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      try {
        await deleteUser(id);
      } catch (error) {
        console.error('Failed to delete user:', error);
      }
    }
  };

  if (loading) {
    return <div className="loading">Loading users...</div>;
  }

  if (error) {
    return <div className="error">Error: {error}</div>;
  }

  return (
    <div className="user-list">
      <div className="header">
        <h2>Users</h2>
        <button onClick={() => navigate('/users/create')} className="btn-primary">
          Create User
        </button>
      </div>

      <table className="user-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Username</th>
            <th>Email</th>
            <th>Full Name</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {users.map((user) => (
            <tr key={user.id}>
              <td>{user.id}</td>
              <td>{user.username}</td>
              <td>{user.email}</td>
              <td>{user.fullName || '-'}</td>
              <td>
                <span className={`status ${user.isActive ? 'active' : 'inactive'}`}>
                  {user.isActive ? 'Active' : 'Inactive'}
                </span>
              </td>
              <td>
                <button
                  onClick={() => navigate(`/users/${user.id}`)}
                  className="btn-secondary"
                >
                  View
                </button>
                <button
                  onClick={() => navigate(`/users/${user.id}/edit`)}
                  className="btn-secondary"
                >
                  Edit
                </button>
                <button
                  onClick={() => handleDelete(user.id)}
                  className="btn-danger"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {users.length === 0 && (
        <div className="empty-state">
          <p>No users found. Create your first user!</p>
        </div>
      )}
    </div>
  );
};
