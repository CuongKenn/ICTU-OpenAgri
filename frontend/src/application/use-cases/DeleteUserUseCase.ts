/**
 * Delete user use case
 */
import { UserRepository } from '@/domain/repositories/UserRepository';

export class DeleteUserUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(id: number): Promise<void> {
    // Check if user exists
    const existingUser = await this.userRepository.getById(id);
    if (!existingUser) {
      throw new Error('User not found');
    }

    return this.userRepository.delete(id);
  }
}
