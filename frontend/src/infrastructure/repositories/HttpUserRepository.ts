/**
 * HTTP User Repository Implementation
 */
import { UserRepository } from '@/domain/repositories/UserRepository';
import { User, CreateUserInput, UpdateUserInput } from '@/domain/entities/User';
import { httpClient } from '../http/HttpClient';

export class HttpUserRepository implements UserRepository {
  private basePath = '/users';

  async getAll(skip: number = 0, limit: number = 100): Promise<User[]> {
    return httpClient.get<User[]>(`${this.basePath}?skip=${skip}&limit=${limit}`);
  }

  async getById(id: number): Promise<User | null> {
    try {
      return await httpClient.get<User>(`${this.basePath}/${id}`);
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null;
      }
      throw error;
    }
  }

  async create(input: CreateUserInput): Promise<User> {
    return httpClient.post<User>(this.basePath, input);
  }

  async update(id: number, input: UpdateUserInput): Promise<User> {
    return httpClient.put<User>(`${this.basePath}/${id}`, input);
  }

  async delete(id: number): Promise<void> {
    await httpClient.delete(`${this.basePath}/${id}`);
  }
}
