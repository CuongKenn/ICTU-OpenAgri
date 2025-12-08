"""Chatbot API endpoints for Gemini agriculture assistant."""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, status

from app.application.dto.chatbot_dto import ChatRequestDTO, ChatResponseDTO
from app.application.use_cases.chatbot_use_cases import AskAgricultureAssistantUseCase
from app.domain.entities.user import User
from app.presentation.deps import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post(
    "/chat",
    response_model=ChatResponseDTO,
    summary="Hỏi trợ lý nông nghiệp",
    status_code=status.HTTP_200_OK,
)
async def ask_agri_assistant(
    request: ChatRequestDTO,
    current_user: User = Depends(get_current_user),
) -> ChatResponseDTO:
    """Forward user question to Gemini agriculture assistant."""
    # Validate user is authenticated
    if not current_user or not current_user.id:
        logger.warning("Unauthorized chatbot access attempt")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Bạn cần đăng nhập để sử dụng chức năng này."
        )
    
    use_case = AskAgricultureAssistantUseCase()

    try:
        return await use_case.execute(request)
    except ValueError as exc:
        logger.warning("Invalid chatbot request from user %s: %s", current_user.id, exc)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except RuntimeError as exc:
        logger.error("Gemini assistant temporarily unavailable: %s", exc)
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(exc)) from exc
    except Exception as exc:  # pragma: no cover - safety net
        logger.exception("Unexpected chatbot error for user %s: %s", current_user.id, exc)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Không thể xử lý yêu cầu trợ lý AI. Vui lòng thử lại sau.",
        ) from exc
