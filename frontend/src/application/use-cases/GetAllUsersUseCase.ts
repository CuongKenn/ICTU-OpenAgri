/**
 * Get all users use case
 */
import { User } from '@/domain/entities/User';
import { UserRepository } from '@/domain/repositories/UserRepository';

export class GetAllUsersUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(skip: number = 0, limit: number = 100): Promise<User[]> {
    return this.userRepository.getAll(skip, limit);
  }
}
