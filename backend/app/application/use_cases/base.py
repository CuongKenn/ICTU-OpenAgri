"""
Base use case class.
"""
from abc import ABC, abstractmethod
from typing import Generic, TypeVar

InputDTO = TypeVar('InputDTO')
OutputDTO = TypeVar('OutputDTO')


class BaseUseCase(ABC, Generic[InputDTO, OutputDTO]):
    """Base use case for application business logic."""
    
    @abstractmethod
    async def execute(self, input_dto: InputDTO) -> OutputDTO:
        """Execute the use case."""
        pass
