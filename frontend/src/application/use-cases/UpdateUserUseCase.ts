/**
 * Update user use case
 */
import { User, UpdateUserInput } from '@/domain/entities/User';
import { UserRepository } from '@/domain/repositories/UserRepository';

export class UpdateUserUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(id: number, input: UpdateUserInput): Promise<User> {
    // Check if user exists
    const existingUser = await this.userRepository.getById(id);
    if (!existingUser) {
      throw new Error('User not found');
    }

    return this.userRepository.update(id, input);
  }
}
