/**
 * Get user by ID use case
 */
import { User } from '@/domain/entities/User';
import { UserRepository } from '@/domain/repositories/UserRepository';

export class GetUserByIdUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(id: number): Promise<User | null> {
    return this.userRepository.getById(id);
  }
}
