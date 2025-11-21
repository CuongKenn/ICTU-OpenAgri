/**
 * User Detail Component
 */
import { useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useUserStore } from '../stores/useUserStore';

export const UserDetail = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { selectedUser, loading, error, fetchUser } = useUserStore();

  useEffect(() => {
    if (id) {
      fetchUser(parseInt(id));
    }
  }, [id, fetchUser]);

  if (loading) {
    return <div className="loading">Loading user details...</div>;
  }

  if (error) {
    return <div className="error">Error: {error}</div>;
  }

  if (!selectedUser) {
    return <div className="error">User not found</div>;
  }

  return (
    <div className="user-detail">
      <div className="header">
        <h2>User Details</h2>
        <div className="actions">
          <button
            onClick={() => navigate(`/users/${id}/edit`)}
            className="btn-primary"
          >
            Edit
          </button>
          <button onClick={() => navigate('/users')} className="btn-secondary">
            Back to List
          </button>
        </div>
      </div>

      <div className="detail-card">
        <div className="detail-row">
          <span className="label">ID:</span>
          <span className="value">{selectedUser.id}</span>
        </div>

        <div className="detail-row">
          <span className="label">Username:</span>
          <span className="value">{selectedUser.username}</span>
        </div>

        <div className="detail-row">
          <span className="label">Email:</span>
          <span className="value">{selectedUser.email}</span>
        </div>

        <div className="detail-row">
          <span className="label">Full Name:</span>
          <span className="value">{selectedUser.fullName || '-'}</span>
        </div>

        <div className="detail-row">
          <span className="label">Status:</span>
          <span className={`status ${selectedUser.isActive ? 'active' : 'inactive'}`}>
            {selectedUser.isActive ? 'Active' : 'Inactive'}
          </span>
        </div>

        <div className="detail-row">
          <span className="label">Superuser:</span>
          <span className="value">{selectedUser.isSuperuser ? 'Yes' : 'No'}</span>
        </div>

        <div className="detail-row">
          <span className="label">Created At:</span>
          <span className="value">
            {new Date(selectedUser.createdAt).toLocaleString()}
          </span>
        </div>

        <div className="detail-row">
          <span className="label">Updated At:</span>
          <span className="value">
            {new Date(selectedUser.updatedAt).toLocaleString()}
          </span>
        </div>
      </div>
    </div>
  );
};
