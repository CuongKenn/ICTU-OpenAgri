/**
 * Create user use case
 */
import { User, CreateUserInput } from '@/domain/entities/User';
import { UserRepository } from '@/domain/repositories/UserRepository';

export class CreateUserUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(input: CreateUserInput): Promise<User> {
    // Business logic validation
    if (!input.email || !input.username) {
      throw new Error('Email and username are required');
    }

    return this.userRepository.create(input);
  }
}
