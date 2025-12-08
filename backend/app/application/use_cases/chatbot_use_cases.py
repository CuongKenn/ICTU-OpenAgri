"""Use case for Gemini-powered agriculture assistant."""
from __future__ import annotations

import asyncio
import logging
from typing import List

from app.application.dto.chatbot_dto import (
    ChatRequestDTO,
    ChatResponseDTO,
    ChatTipDTO,
)
from app.infrastructure.external_services.gemini_service import (
    GeminiAgricultureAssistant,
)

logger = logging.getLogger(__name__)


class AskAgricultureAssistantUseCase:
    """Call Gemini assistant and wrap response into DTOs."""

    def __init__(self, assistant: GeminiAgricultureAssistant | None = None) -> None:
        self.assistant = assistant or GeminiAgricultureAssistant()

    async def execute(self, request: ChatRequestDTO) -> ChatResponseDTO:
        history_payload: List[dict[str, str]] = [
            {"role": message.role, "content": message.content}
            for message in request.history
        ]

        loop = asyncio.get_running_loop()

        try:
            result = await loop.run_in_executor(  # type: ignore[arg-type]
                None,
                lambda: self.assistant.generate_answer(
                    question=request.question,
                    history=history_payload,
                ),
            )
        except ValueError as exc:
            logger.warning("Validation error when calling Gemini: %s", exc)
            raise
        except RuntimeError:
            raise
        except Exception as exc:  # pragma: no cover - safety net
            logger.exception("Unexpected error when calling Gemini assistant: %s", exc)
            raise RuntimeError("Hệ thống trợ lý AI đang gặp sự cố. Vui lòng thử lại sau.") from exc

        tips = [
            ChatTipDTO(
                id=tip.get("id", ""),
                title=tip.get("title", ""),
                summary=tip.get("summary", ""),
            )
            for tip in result.get("tips", [])
        ]

        return ChatResponseDTO(answer=result.get("answer", ""), tips=tips)
