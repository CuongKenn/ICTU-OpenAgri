"""DTOs for Gemini-powered agriculture chatbot."""
from typing import List

from pydantic import BaseModel, Field


class ChatMessageDTO(BaseModel):
    """Represents a single chat message exchanged with the assistant."""

    role: str = Field(..., pattern="^(user|assistant)$", description="Role of the message sender")
    content: str = Field(..., min_length=1, max_length=2000, description="Message content")


class ChatRequestDTO(BaseModel):
    """Payload for asking the agriculture assistant."""

    question: str = Field(..., min_length=1, max_length=1000, description="Latest user question")
    history: List[ChatMessageDTO] = Field(
        default_factory=list,
        description="Optional conversation history for better context",
    )


class ChatTipDTO(BaseModel):
    """Knowledge base tips surfaced alongside the answer."""

    id: str = Field(..., description="Identifier of the knowledge base entry")
    title: str = Field(..., description="Tip title")
    summary: str = Field(..., description="Short description of the tip")


class ChatResponseDTO(BaseModel):
    """Response from the agriculture assistant."""

    answer: str = Field(..., description="Assistant response in Vietnamese")
    tips: List[ChatTipDTO] = Field(
        default_factory=list,
        description="Relevant expert tips used to craft the answer",
    )
